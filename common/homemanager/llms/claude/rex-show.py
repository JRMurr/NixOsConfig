"""Show a PNG, SVG or Markdown file in a Rex split pane beside the caller.

rex-show FILE [-- CMD...]
    Point the pane at FILE; create the pane if missing. The pane redraws
    whenever FILE changes, so rewriting it in a loop gives a live view.
    CMD, if given, starts in the background with the caller's env and is
    killed (with its process group) when the pane closes.

Keys: +/-/0 zoom in/out/reset (ctrl+wheel), hjkl/arrows pan (wheel,
shift+wheel), space/b page, g/G top/bottom. SVG and Markdown re-render at
the zoom level so they stay sharp. Drawn with the kitty graphics protocol.
TODO: render only the visible region so zoom past MAX_RASTER_PIXELS stays sharp.
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

STEP_LINE = 0.1  # Fraction of the visible size per line pan.
STEP_PAGE = 0.9
ZOOM_STEP = 1.25
ZOOM_MAX = 16.0
MAX_RASTER_PIXELS = 40_000_000  # Cap on re-rasterized SVG/Markdown size.

# Actions: ("pan", dx, dy) in fractions of the view, ("zoom", factor),
# ("zoom_reset",), ("top",), ("bottom",).
KEYS = {
    b"j": ("pan", 0, STEP_LINE), b"\x1b[B": ("pan", 0, STEP_LINE),
    b"k": ("pan", 0, -STEP_LINE), b"\x1b[A": ("pan", 0, -STEP_LINE),
    b"l": ("pan", STEP_LINE, 0), b"\x1b[C": ("pan", STEP_LINE, 0),
    b"h": ("pan", -STEP_LINE, 0), b"\x1b[D": ("pan", -STEP_LINE, 0),
    b" ": ("pan", 0, STEP_PAGE), b"f": ("pan", 0, STEP_PAGE), b"\x1b[6~": ("pan", 0, STEP_PAGE),
    b"b": ("pan", 0, -STEP_PAGE), b"\x1b[5~": ("pan", 0, -STEP_PAGE),
    b"+": ("zoom", ZOOM_STEP), b"=": ("zoom", ZOOM_STEP),
    b"-": ("zoom", 1 / ZOOM_STEP), b"0": ("zoom_reset",),
    b"g": ("top",), b"G": ("bottom",),
}

# SGR mouse: ESC [ < button ; col ; row M. Wheel buttons plus modifier bits.
INPUT_TOKEN = re.compile(rb"\x1b\[<(\d+);\d+;\d+[Mm]|\x1b\[[0-9;]*[~A-Za-z]|.", re.DOTALL)
WHEEL_UP, WHEEL_DOWN, WHEEL_LEFT, WHEEL_RIGHT = 64, 65, 66, 67
MOD_SHIFT, MOD_ALT, MOD_CTRL = 4, 8, 16


def mouse_action(button):
    base = button & ~(MOD_SHIFT | MOD_ALT | MOD_CTRL)
    sign = {WHEEL_UP: -1, WHEEL_DOWN: 1, WHEEL_LEFT: -1, WHEEL_RIGHT: 1}.get(base)
    if sign is None:
        return None

    if base in (WHEEL_LEFT, WHEEL_RIGHT) or button & MOD_SHIFT:
        return ("pan", sign * STEP_LINE, 0)
    if button & MOD_CTRL:
        return ("zoom", ZOOM_STEP if sign < 0 else 1 / ZOOM_STEP)
    return ("pan", 0, sign * STEP_LINE)


def parse_input(data):
    """Raw terminal input -> list of actions; one read may hold many events."""
    actions = []
    for match in INPUT_TOKEN.finditer(data):
        if match.group(1) is not None:
            action = mouse_action(int(match.group(1)))
        else:
            action = KEYS.get(match.group(0))
        if action:
            actions.append(action)
    return actions

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
        self.x = 0  # Viewport origin, in raster px.
        self.y = 0
        self.zoom = 1.0  # 1 = fit the pane.
        self.raster_zoom = 1.0  # Zoom baked into the raster (vectors only).
        self.anchor = None  # (cx, cy) view centre to keep after a zoom.
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
        """Crop of the raster to show and the cells it fills.

        At zoom 1 the image fits the pane, or fits its width and scrolls if
        tall. Zoom scales from there. Returns (w_src, h_src, cols, rows)."""
        img_w, img_h = struct.unpack(">II", self.png[PNG_DIMS])
        cols, rows, cell_w, cell_h = self.pane()
        pane_w, pane_h = cols * cell_w, rows * cell_h

        logical_w, logical_h = img_w / self.raster_zoom, img_h / self.raster_zoom
        fit = pane_w / logical_w
        if logical_h * fit <= pane_h:
            fit = min(fit, pane_h / logical_h)
        scale = fit * self.zoom / self.raster_zoom  # Screen px per raster px.

        w_src = min(img_w, pane_w / scale)
        h_src = min(img_h, pane_h / scale)
        c = max(1, round(w_src * scale / cell_w))
        r = max(1, round(h_src * scale / cell_h))
        return int(w_src), int(h_src), min(c, cols), min(r, rows)

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
        w_src, h_src, c, r = self.layout()
        max_x, max_y = img_w - w_src, img_h - h_src

        if self.anchor:  # Keep the pre-zoom centre in view.
            self.x = int(self.anchor[0] * img_w - w_src / 2)
            self.y = int(self.anchor[1] * img_h - h_src / 2)
            self.anchor = None
        self.x = max(0, min(self.x, max_x))
        self.y = max(0, min(self.y, max_y))

        status = f"{self.caption}  {img_w}x{img_h}"
        if self.zoom != 1:
            status += f"  {self.zoom:.3g}x"
        if max_x:
            status += f"  x{100 * self.x // max_x}%"
        if max_y:
            status += f"  y{100 * self.y // max_y}%"
        status += "  hjkl +/-/0"

        rows = self.pane()[1]
        return (f"\x1b[H\x1b_Ga=p,q=2,C=1,i={IMAGE_ID},p={PLACEMENT_ID},"
                f"x={self.x},y={self.y},w={w_src},h={h_src},c={c},r={r}\x1b\\"
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

    def pane_width(self):
        cols, _, cell_w, _ = self.pane()
        return int(cols * cell_w)

    def width_px(self):
        """Raster width for vector sources: pane width times zoom, capped."""
        width = self.pane_width() * self.zoom
        if self.png is not None:
            img_w, img_h = struct.unpack(">II", self.png[PNG_DIMS])
            width = min(width, (MAX_RASTER_PIXELS * img_w / img_h) ** 0.5)
        return int(width)

    def stale_width(self, path):
        """Vector sources render at pane width x zoom; re-render on change."""
        if not self.resized or self.png is None or not path:
            return False
        if not (is_markdown(path) or path.lower().endswith(".svg")):
            return False
        return self.width_px() != self.render_width

    def load(self, path, key):
        width_px = self.width_px()
        self.render_width = width_px
        vector = is_markdown(path) or path.lower().endswith(".svg")
        self.raster_zoom = width_px / self.pane_width() if vector else 1.0
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
            self.x = self.y = 0
            self.zoom = 1.0
            self.anchor = None
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

        actions = parse_input(data)
        if not actions:
            return

        for action in actions:
            self.apply(action)

        if self.resized:
            return  # Zoom: refresh() re-rasterizes and redraws.

        sys.stdout.write(self.place())
        sys.stdout.flush()

    def apply(self, action):
        img_w, img_h = struct.unpack(">II", self.png[PNG_DIMS])
        w_src, h_src, _, _ = self.layout()
        kind = action[0]

        if kind == "pan":
            self.x += int(action[1] * w_src)
            self.y += int(action[2] * h_src)
        elif kind == "top":
            self.y = 0
        elif kind == "bottom":
            self.y = img_h
        elif kind in ("zoom", "zoom_reset"):
            zoom = 1.0 if kind == "zoom_reset" else self.zoom * action[1]
            zoom = max(1.0, min(zoom, ZOOM_MAX))
            if zoom == self.zoom:
                return
            if self.anchor is None:
                self.anchor = ((self.x + w_src / 2) / img_w, (self.y + h_src / 2) / img_h)
            self.zoom = zoom
            self.resized = True  # Redraw path; vectors re-rasterize.

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
