"""Render XRService tracking datasets (.occ) into one tiled MP4 of all tracking cameras.

Usage: occ2video [-o OUT.mp4] [DATASET_DIR ...]   (default: every dataset in DATASETS_DIR)

Each .occ is a stream of 'occipitl' records. Two record types carry H.264 frames:
  RECORD_LED   all 4 cameras at the short controller-LED exposure (near black, gamma-boosted here)
  RECORD_ROOM  the 2 side (slam) cameras at the normal exposure
A record body is TLV fields (u32 id, u32 len, value); each camera block starts at FIELD_CAM.
Format reverse-engineered from datasets of 2026-10; fields not listed here are ignored.
"""
import argparse
import glob
import json
import os
import re
import struct
import subprocess
import sys
import tempfile

DATASETS_DIR = os.path.expanduser('~/.config/openvr/config/cv/xrservice/datasets')

MAGIC = b'occipitl'
RECORD_HDR = struct.Struct('<8sII')     # magic, type, body length
TLV_HDR = struct.Struct('<II')          # field id, length
NAL_LEN = struct.Struct('>I')
ANNEXB_START = b'\0\0\0\1'

RECORD_ROOM = 32
RECORD_LED = 38
FIELD_TIMESTAMP = 12
FIELD_FRAME = 13
FIELD_PARAM_SET = 14
FIELD_CAM = 15
FIELD_SERIAL = 55

# Order of camera blocks inside each record, seen in every dataset so far. Used only when
# a camera's serial is blank (a dead camera reports none).
LED_ORDER = ['slam_right', 'slam_left', 'upper_left', 'upper_right']
ROOM_ORDER = ['slam_right', 'slam_left']

TILE_W, TILE_H = 400, 360
OUT_FPS = 30
LED_GAMMA = 0.35
FONT = 'Noto Sans Mono'


class Stream:
    def __init__(self, kind, slot):
        self.kind = kind
        self.slot = slot
        self.serial = ''
        self.data = bytearray()
        self.stamps = []

    def fps(self):
        if len(self.stamps) < 2:
            return OUT_FPS
        return (len(self.stamps) - 1) / (self.stamps[-1] - self.stamps[0])


def records(blob):
    pos = 0
    while (pos := blob.find(MAGIC, pos)) >= 0:
        _, kind, length = RECORD_HDR.unpack_from(blob, pos)
        body_start = pos + RECORD_HDR.size
        yield kind, blob[body_start:body_start + length]
        pos = body_start + length


def fields(body):
    pos = 0
    while pos + TLV_HDR.size <= len(body):
        fid, length = TLV_HDR.unpack_from(body, pos)
        start = pos + TLV_HDR.size
        yield fid, body[start:start + length]
        pos = start + length


def avcc_to_annexb(frame):
    out = bytearray()
    pos = 0
    while pos < len(frame):
        (length,) = NAL_LEN.unpack_from(frame, pos)
        out += ANNEXB_START + frame[pos + 4:pos + 4 + length]
        pos += 4 + length
    return out


def parse_occ(path):
    """Return {(record kind, camera slot in record): Stream}."""
    with open(path, 'rb') as f:
        blob = f.read()

    streams = {}
    for kind, body in records(blob):
        if kind not in (RECORD_LED, RECORD_ROOM):
            continue

        slot = -1
        stream = None
        for fid, value in fields(body):
            if fid == FIELD_CAM:
                slot += 1
                stream = streams.setdefault((kind, slot), Stream(kind, slot))
                continue
            if stream is None:
                continue
            if fid == FIELD_PARAM_SET:
                stream.data += ANNEXB_START + value
            elif fid == FIELD_FRAME:
                stream.data += avcc_to_annexb(value)
            elif fid == FIELD_TIMESTAMP:
                stream.stamps.append(struct.unpack('<d', value)[0])
            elif fid == FIELD_SERIAL:
                stream.serial = stream.serial or value.split(b'\0')[0].decode()
    return streams


def serial_names(dataset):
    path = os.path.join(dataset, 'snapshots', 'BeginningSnapshot', 'cameraMetadata.json')
    try:
        with open(path) as f:
            # XRService writes bare nan.
            cams = json.loads(re.sub(r'\bnan\b', 'null', f.read()))['cameras']
    except (OSError, ValueError, KeyError):
        return {}
    return {c['serialNumber']: c['cameraName'] for c in cams.values() if 'serialNumber' in c}


def name_streams(streams, names):
    """Return {(kind, camera name): Stream}."""
    named = {}
    for (kind, slot), stream in streams.items():
        order = LED_ORDER if kind == RECORD_LED else ROOM_ORDER
        name = names.get(stream.serial) or (order[slot] if slot < len(order) else 'cam%d' % slot)
        named[(kind, name)] = stream
    return named


def text(label, color='white', y='8', size=20):
    label = label.replace(':', r'\:')
    return ("drawtext=font='%s':text='%s':fontcolor=%s:fontsize=%d:x=8:y=%s:box=1:boxcolor=black@0.6"
            % (FONT, label, color, size, y))


def tile_filter(index, stream, label, kind):
    chain = ['[%d:v]scale=%d:%d:force_original_aspect_ratio=decrease' % (index, TILE_W, TILE_H),
             'pad=%d:%d:-1:-1' % (TILE_W, TILE_H)]
    if kind == RECORD_LED:
        # Limited range after scale: black is 16, white 235.
        chain.append("lutyuv=y='16+219*pow(clip((val-16)/219\\,0\\,1)\\,%s)'" % LED_GAMMA)
    chain.append('fps=%d' % OUT_FPS)

    dead = not stream.serial
    chain.append(text(label, 'red' if dead else 'white'))
    if dead:
        chain.append(text('NO SERIAL: camera down', 'red', y='h-36'))
    return ','.join(chain)


def render(dataset, out_path, workdir):
    occs = glob.glob(os.path.join(dataset, '*.occ'))
    if not occs:
        print('skip %s: no .occ' % dataset, file=sys.stderr)
        return False

    named = name_streams(parse_occ(occs[0]), serial_names(dataset))
    layout = [(RECORD_LED, n) for n in ('upper_left', 'upper_right', 'slam_left', 'slam_right')]
    layout += [(RECORD_ROOM, n) for n in ('slam_left', 'slam_right')]

    inputs, chains, tiles = [], [], []
    for i, key in enumerate(layout):
        kind, name = key
        label = '%s %s' % (name, 'LED exposure' if kind == RECORD_LED else 'room exposure')
        stream = named.get(key)
        if stream is None:
            inputs += ['-f', 'lavfi', '-i', 'color=black:s=%dx%d:r=%d' % (TILE_W, TILE_H, OUT_FPS)]
            chains.append('[%d:v]%s,%s[t%d]' % (i, text(label), text('NOT RECORDED', 'red', y='h-36'), i))
            tiles.append('[t%d]' % i)
            continue

        h264 = os.path.join(workdir, '%s_%d_%s.h264' % (os.path.basename(dataset), kind, name))
        with open(h264, 'wb') as f:
            f.write(stream.data)
        inputs += ['-r', '%.6f' % stream.fps(), '-f', 'h264', '-i', h264]
        chains.append('%s[t%d]' % (tile_filter(i, stream, label, kind), i))
        tiles.append('[t%d]' % i)

    info = len(layout)
    inputs += ['-f', 'lavfi', '-i', 'color=black:s=%dx%d:r=%d' % (2 * TILE_W, TILE_H, OUT_FPS)]
    title = text(os.path.basename(dataset), size=24)
    clock = text('t=%{pts:hms}', y='48', size=24)
    chains.append('[%d:v]%s,%s[t%d]' % (info, title, clock, info))
    tiles.append('[t%d]' % info)

    grid = '0_0|w0_0|w0+w1_0|w0+w1+w2_0|0_h0|w0_h0|w0+w1_h0'
    chains.append('%sxstack=inputs=%d:layout=%s:shortest=1[out]' % (''.join(tiles), len(tiles), grid))

    cmd = ['ffmpeg', '-v', 'error', '-y', *inputs, '-filter_complex', ';'.join(chains),
           '-map', '[out]', '-c:v', 'libx264', '-preset', 'veryfast', '-crf', '20',
           '-pix_fmt', 'yuv420p', out_path]
    subprocess.run(cmd, check=True)
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('datasets', nargs='*')
    parser.add_argument('-o', '--output', default='trackers.mp4')
    args = parser.parse_args()

    datasets = args.datasets or sorted(glob.glob(os.path.join(DATASETS_DIR, '*.dataset')))
    if not datasets:
        sys.exit('no datasets in %s' % DATASETS_DIR)

    with tempfile.TemporaryDirectory() as workdir:
        segments = []
        for dataset in datasets:
            dataset = dataset.rstrip('/')
            segment = os.path.join(workdir, '%03d.mp4' % len(segments))
            print('rendering %s' % os.path.basename(dataset), file=sys.stderr)
            if render(dataset, segment, workdir):
                segments.append(segment)

        listing = os.path.join(workdir, 'segments.txt')
        with open(listing, 'w') as f:
            f.writelines("file '%s'\n" % s for s in segments)
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'concat', '-safe', '0', '-i', listing,
                        '-c', 'copy', args.output], check=True)
    print(args.output)


if __name__ == '__main__':
    main()
