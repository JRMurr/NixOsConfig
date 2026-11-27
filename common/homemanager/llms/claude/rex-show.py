"""Show a PNG, SVG or Markdown file in a Rex split pane beside the caller.

rex-show FILE [-- CMD...]
    Point the pane at FILE; create the pane if missing. The pane redraws
    whenever FILE changes, so rewriting it in a loop gives a live view.
    CMD, if given, starts in the background with the caller's env and is
    killed (with its process group) when the pane closes.

Images taller than the pane scroll: j/k, arrows, space/PgDn, b/PgUp, g/G,
mouse wheel. Drawn with the kitty graphics protocol.
"""
import base64
import fcntl
import json
import os
import re
import select
import signal
import struct
import subprocess
import sys
import termios
import time
import traceback
import tty

LABEL = "Graphics"
PRODUCERS_FILE = "producers"  # Process group IDs to kill when the pane closes.
PRODUCER_LOG = "producer.log"
PANE_CHECK_S = 2.0  # How often the viewer checks its pane still exists.
SPLIT_RATIO = "45"
CHUNK = 4096  # Max base64 payload per escape, per KGP spec.
POLL_S = 0.2
CAPTION_ROWS = 1
IMAGE_ID = 1
PLACEMENT_ID = 1
FALLBACK_CELL = (10, 20)  # px, when the terminal doesn't report pixel size.

PNG_MAGIC = b"\x89PNG\r\n\x1a\n"
PNG_IEND = b"IEND\xaeB`\x82"  # Final chunk; absent while a file is mid-write.
PNG_DIMS = slice(16, 24)  # IHDR width/height offsets.
SVG_SNIFF_BYTES = 1024
MD_EXTENSIONS = (".md", ".markdown")

MD_PAGE_WIDTH_PT = 520
PT_PER_INCH = 72
MERMAID_FENCE = re.compile(rb"^\s*```\s*mermaid", re.MULTILINE)
TYP_IMAGE = re.compile(r'image\("([^"]+)"')

ESC_DELETE_ALL = "\x1b_Ga=d,d=A,q=2\x1b\\"
ESC_CLEAR = "\x1b[2J\x1b[H"
ESC_HIDE_CURSOR = "\x1b[?25l"
ESC_MOUSE_ON = "\x1b[?1000h\x1b[?1006h"  # Button events, SGR encoding.

STEP_LINE = 0.1  # Fraction of the visible height per line scroll.
STEP_PAGE = 0.9
KEYS = {
    b"j": STEP_LINE, b"\x1b[B": STEP_LINE, b"\x1b[<65;": STEP_LINE,
    b"k": -STEP_LINE, b"\x1b[A": -STEP_LINE, b"\x1b[<64;": -STEP_LINE,
    b" ": STEP_PAGE, b"f": STEP_PAGE, b"\x1b[6~": STEP_PAGE,
    b"b": -STEP_PAGE, b"\x1b[5~": -STEP_PAGE,
}
KEY_TOP = b"g"
KEY_BOTTOM = b"G"

THEME_TYP = """\
#let fg = rgb("#c0caf5")
#let bg = rgb("#0f1117")
#let accent = rgb("#7aa2f7")
#let muted = rgb("#1a1d27")
#set page(width: {width}pt, height: auto, margin: 18pt, fill: bg)
#set text(fill: fg, size: 11pt)
#set image(width: 100%)
#show heading: set text(fill: accent)
#show link: set text(fill: accent)
#show raw.where(block: true): block.with(fill: muted, inset: 8pt, radius: 4pt, width: 100%)
#show raw.where(block: false): box.with(fill: muted, inset: (x: 3pt), outset: (y: 3pt), radius: 2pt)
#show quote: it => block(stroke: (left: 2pt + accent), inset: (left: 10pt, y: 4pt), it.body)
#set table(stroke: 0.5pt + fg.transparentize(60%))
#show figure: set block(breakable: true)
#include "body.typ"
"""

# Typst runs with --root /, so image paths must be absolute. Relative paths
# resolve against the build dir (mermaid output) first, then the source dir.
# TODO: fetch remote images instead of dropping them to alt text.
PATHS_LUA = """\
function Image(img)
  if img.src:match("^%a+://") then return img.caption end
  if img.src:sub(1, 1) == "/" then return img end
  for _, dir in ipairs({BUILD_DIR, SOURCE_DIR}) do
    local path = dir .. "/" .. img.src
    if io.open(path) then img.src = path; return img end
  end
end
"""


# --- caller side -------------------------------------------------------------

def state_dir(anchor):
    base = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
    path = os.path.join(base, "rex-show", anchor.rsplit(":", 1)[-1])
    os.makedirs(path, exist_ok=True)
    return path


def rex(*args):
    out = subprocess.run(["rex", *args], capture_output=True, text=True, check=True)
    return json.loads(out.stdout) if "--json" in args else out.stdout


def pane_alive(block_id):
    blocks = rex("block", "ls", "--json")["blocks"]
    return any(b["block_id"] == block_id and b.get("placement") == "placed" for b in blocks)


def ensure_pane(anchor, source_file):
    pane_file = os.path.join(os.path.dirname(source_file), "pane")
    if os.path.exists(pane_file):
        with open(pane_file) as f:
            block_id = f.read().strip()
        if pane_alive(block_id):
            return block_id

    # The Rex server spawns the viewer with its own env; hand over our tools.
    viewer = ["env", f"PATH={os.environ['PATH']}", sys.executable,
              os.path.abspath(__file__), "--view", source_file]
    created = rex("split", "-b", anchor, "--split=right", "--ratio", SPLIT_RATIO,
                  "--label", LABEL, "--focus=false", "--shell=none", "--json", "--", *viewer)
    block_id = created["block_ids"][0]
    with open(pane_file, "w") as f:
        f.write(block_id)
    return block_id


def is_svg(head):
    return b"<svg" in head[:SVG_SNIFF_BYTES]


def is_markdown(path):
    return path.lower().endswith(MD_EXTENSIONS)


def start_producer(cmd, state):
    """Run cmd detached in its own process group; the viewer kills it on close."""
    with open(os.path.join(state, PRODUCER_LOG), "ab") as log:
        proc = subprocess.Popen(cmd, stdin=subprocess.DEVNULL, stdout=log, stderr=log,
                                start_new_session=True)
    with open(os.path.join(state, PRODUCERS_FILE), "a") as f:
        f.write(f"{proc.pid}\n")


def show(path, producer):
    anchor = os.environ.get("REX_BLOCK")
    if not anchor:
        sys.exit("rex-show: REX_BLOCK unset; not in a Rex terminal")

    with open(path, "rb") as f:
        head = f.read(SVG_SNIFF_BYTES)
    if not (head.startswith(PNG_MAGIC) or is_svg(head) or is_markdown(path)):
        sys.exit(f"rex-show: {path} is not a PNG, SVG or Markdown file")

    source_file = os.path.join(state_dir(anchor), "source")
    tmp = source_file + ".tmp"
    with open(tmp, "w") as f:
        f.write(os.path.abspath(path))
    os.replace(tmp, source_file)

    print(ensure_pane(anchor, source_file))

    if producer:
        start_producer(producer, os.path.dirname(source_file))


# --- converters: any source -> PNG bytes ---------------------------------------

def run(*cmd):
    """stdout bytes, or None on failure (stderr goes to the viewer log)."""
    try:
        out = subprocess.run(cmd, capture_output=True)
    except OSError as err:  # Tool missing from PATH.
        sys.stderr.write(f"{err}\n")
        sys.stderr.flush()
        return None

    if out.returncode != 0:
        sys.stderr.write(out.stderr.decode(errors="replace"))
        sys.stderr.flush()
        return None
    return out.stdout


def svg_to_png(path, width_px):
    return run("rsvg-convert", "-w", str(width_px), path)


def md_prepare(path, build_dir):
    """Markdown -> build_dir/main.typ. Returns referenced image paths, or None."""
    with open(path, "rb") as f:
        markdown = f.read()

    staged = os.path.join(build_dir, "doc.md")
    with open(staged, "wb") as f:
        f.write(markdown)

    if MERMAID_FENCE.search(markdown):
        if run("mmdc", "-q", "-t", "dark", "-b", "transparent", "-s", "2", "-e", "png",
               "-i", staged, "-o", staged) is None:
            return None

    lua = os.path.join(build_dir, "paths.lua")
    with open(lua, "w") as f:
        f.write(f"BUILD_DIR = {json.dumps(build_dir)}\n"
                f"SOURCE_DIR = {json.dumps(os.path.dirname(path))}\n" + PATHS_LUA)

    body = os.path.join(build_dir, "body.typ")
    if run("pandoc", "-f", "gfm", "-t", "typst", "--lua-filter", lua, staged, "-o", body) is None:
        return None

    with open(os.path.join(build_dir, "main.typ"), "w") as f:
        f.write(THEME_TYP.replace("{width}", str(MD_PAGE_WIDTH_PT)))

    with open(body) as f:
        return TYP_IMAGE.findall(f.read())


def typst_png(build_dir, width_px):
    """Compile build_dir/main.typ. Cheap enough to rerun per frame."""
    ppi = width_px * PT_PER_INCH / MD_PAGE_WIDTH_PT
    main = os.path.join(build_dir, "main.typ")
    out = os.path.join(build_dir, "out.png")
    if run("typst", "compile", "--root", "/", "--ppi", f"{ppi:.0f}", main, out) is None:
        return None

    with open(out, "rb") as f:
        return f.read()


def load_png(path, width_px):
    """PNG bytes for an image path, or None if unreadable or mid-write."""
    with open(path, "rb") as f:
        data = f.read()

    if is_svg(data):
        return svg_to_png(path, width_px)

    if not (data.startswith(PNG_MAGIC) and data.endswith(PNG_IEND)):
        return None

    return data


# --- viewer ---------------------------------------------------------------------

def file_stat(path):
    """(mtime, size), or None if missing; a change triggers a redraw."""
    try:
        stat = os.stat(path)
    except OSError:
        return None
    return stat.st_mtime_ns, stat.st_size


class Viewer:
    def __init__(self, source_file):
        self.source_file = source_file
        self.build_dir = os.path.join(os.path.dirname(source_file), "build")
        os.makedirs(self.build_dir, exist_ok=True)
        self.png = None
        self.caption = ""
        self.scroll = 0  # Source-image px from the top.
        self.last_key = None
        self.resized = True
        self.md_stat = None  # Markdown file stat at last full render.
        self.deps = []  # Images a Markdown doc embeds; changes redraw it.
        self.render_width = None  # Pane px width of the current render.

    def pane(self):
        raw = fcntl.ioctl(sys.stdout.fileno(), termios.TIOCGWINSZ, b"\0" * 8)
        rows, cols, xpix, ypix = struct.unpack("HHHH", raw)
        cell_w = xpix / cols if xpix else FALLBACK_CELL[0]
        cell_h = ypix / rows if ypix else FALLBACK_CELL[1]
        return cols, max(1, rows - CAPTION_ROWS), cell_w, cell_h

    def layout(self):
        """(cols, rows, crop_h, max_scroll) for the current image and pane."""
        img_w, img_h = struct.unpack(">II", self.png[PNG_DIMS])
        cols, rows, cell_w, cell_h = self.pane()
        fit_width = cols * cell_w / img_w

        if img_h * fit_width > rows * cell_h:
            crop_h = int(rows * cell_h / fit_width)  # Tall: fit width, crop height.
            return cols, rows, crop_h, img_h - crop_h

        scale = min(fit_width, rows * cell_h / img_h)
        c, r = int(img_w * scale / cell_w), int(img_h * scale / cell_h)
        return max(1, c), max(1, r), img_h, 0

    def transmit(self):
        data = base64.standard_b64encode(self.png).decode()
        chunks = [data[i:i + CHUNK] for i in range(0, len(data), CHUNK)]
        out = []
        for i, chunk in enumerate(chunks):
            head = f"a=t,f=100,q=2,i={IMAGE_ID}," if i == 0 else ""
            out.append(f"\x1b_G{head}m={int(i < len(chunks) - 1)};{chunk}\x1b\\")
        return "".join(out)

    def place(self):
        """Same placement ID replaces the previous frame in place: no flicker."""
        img_w, img_h = struct.unpack(">II", self.png[PNG_DIMS])
        c, r, crop_h, max_scroll = self.layout()
        self.scroll = max(0, min(self.scroll, max_scroll))

        status = f"{self.caption}  {img_w}x{img_h}"
        if max_scroll:
            status += f"  {100 * self.scroll // max_scroll}%  j/k space/b g/G"

        rows = self.pane()[1]
        return (f"\x1b[H\x1b_Ga=p,q=2,C=1,i={IMAGE_ID},p={PLACEMENT_ID},"
                f"x=0,y={self.scroll},w={img_w},h={crop_h},c={c},r={r}\x1b\\"
                f"\x1b[{rows + 1};1H\x1b[2K\x1b[2m{status}\x1b[0m")

    def status(self, text):
        rows = self.pane()[1]
        sys.stdout.write(f"\x1b[{rows + 1};1H\x1b[2K\x1b[2m{text}\x1b[0m")
        sys.stdout.flush()

    def source(self):
        try:
            with open(self.source_file) as f:
                path = f.read().strip()
            stat = (path, *file_stat(path))
        except OSError:
            return None, None

        return path, (stat, tuple(file_stat(d) for d in self.deps))

    def width_px(self):
        cols, _, cell_w, _ = self.pane()
        return int(cols * cell_w)

    def stale_width(self, path):
        """Vector sources render at pane width; re-render after a resize."""
        if not self.resized or self.png is None or not path:
            return False
        if not (is_markdown(path) or path.lower().endswith(".svg")):
            return False
        return self.width_px() != self.render_width

    def load(self, path, key):
        width_px = self.width_px()
        self.render_width = width_px
        if not is_markdown(path):
            self.deps = []
            return load_png(path, width_px)

        md_stat = key[0]
        if md_stat != self.md_stat:  # Doc text changed: full pipeline.
            self.status(f"rendering {os.path.basename(path)}…")
            deps = md_prepare(path, self.build_dir)
            if deps is None:
                return None
            self.deps = deps
            self.md_stat = md_stat

        return typst_png(self.build_dir, width_px)  # Else only images changed.

    def refresh(self):
        path, key = self.source()
        if key is None or (key == self.last_key and not self.resized):
            return

        new_source = self.last_key is None or key[0][0] != self.last_key[0][0]
        changed = key != self.last_key or self.stale_width(path)
        if new_source:
            self.md_stat = None
            self.deps = []
        if changed:
            png = self.load(path, key)
            key = self.source()[1]  # Deps may have changed while loading.
            if png is None:
                self.last_key = key  # Don't retry a broken file until it changes.
                self.status(f"{os.path.basename(path)}: render failed, see viewer.log")
                return
            self.png = png
            self.caption = os.path.basename(path)

        if self.png is None:
            return

        if new_source:
            self.scroll = 0

        clear = self.resized or new_source
        out = ESC_DELETE_ALL + ESC_CLEAR if clear else ""
        out += self.transmit() if changed or clear else ""
        sys.stdout.write(out + self.place())
        sys.stdout.flush()
        self.resized = False
        self.last_key = key

    def on_input(self, data):
        if self.png is None:
            return

        _, _, crop_h, max_scroll = self.layout()
        if data == KEY_TOP:
            self.scroll = 0
        elif data == KEY_BOTTOM:
            self.scroll = max_scroll
        else:
            step = next((v for k, v in KEYS.items() if data.startswith(k)), None)
            if step is None:
                return
            self.scroll += int(step * crop_h)

        sys.stdout.write(self.place())
        sys.stdout.flush()

    def shutdown(self, *_):
        """Pane closed: kill producers started for it, then exit."""
        producers = os.path.join(os.path.dirname(self.source_file), PRODUCERS_FILE)
        try:
            with open(producers) as f:
                pgids = [int(line) for line in f if line.strip()]
            os.remove(producers)
        except OSError:
            pgids = []

        for pgid in pgids:
            try:
                os.killpg(pgid, signal.SIGTERM)
            except ProcessLookupError:
                continue

        os._exit(0)

    def pane_gone(self):
        """Closing a pane in the Rex UI keeps its process alive for undo, with
        no SIGHUP. Treat our block vanishing from the server as a close."""
        own = os.environ.get("REX_BLOCK")
        if not own:
            return False

        try:
            blocks = rex("block", "ls", "--json")["blocks"]
        except (OSError, subprocess.CalledProcessError, ValueError):
            return False  # Server unreachable: not proof of a close.

        return all(b["block_id"] != own for b in blocks)

    def run(self):
        signal.signal(signal.SIGWINCH, lambda *_: setattr(self, "resized", True))
        for sig in (signal.SIGHUP, signal.SIGTERM):
            signal.signal(sig, self.shutdown)
        try:
            self.loop()
        except Exception:  # Never orphan producers, even on a bug.
            traceback.print_exc()
            self.shutdown()

    def loop(self):
        stdin = sys.stdin.fileno()
        tty.setcbreak(stdin)
        sys.stdout.write(ESC_HIDE_CURSOR + ESC_MOUSE_ON)

        next_check = time.monotonic() + PANE_CHECK_S
        while True:
            if time.monotonic() >= next_check:
                next_check = time.monotonic() + PANE_CHECK_S
                if self.pane_gone():
                    self.shutdown()

            try:
                ready = select.select([stdin], [], [], POLL_S)[0]
                data = os.read(stdin, 64) if ready else None
            except InterruptedError:
                data = None
            except OSError:
                data = b""  # EIO: terminal gone.
            if data == b"":
                self.shutdown()
            if data:
                self.on_input(data)
            self.refresh()


def main():
    if len(sys.argv) == 3 and sys.argv[1] == "--view":
        log = os.path.join(os.path.dirname(sys.argv[2]), "viewer.log")
        sys.stderr = open(log, "a")
        Viewer(sys.argv[2]).run()
        return

    args = sys.argv[1:]
    producer = []
    if "--" in args:
        split = args.index("--")
        args, producer = args[:split], args[split + 1:]

    if len(args) != 1 or (producer == [] and "--" in sys.argv):
        sys.exit(__doc__)

    show(args[0], producer)


if __name__ == "__main__":
    main()
