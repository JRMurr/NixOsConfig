"""The process in the Graphics pane: watch the source, draw it, handle input."""
import os
import signal
import time
import traceback

from rex_show import kitty, rexcli
from rex_show.geometry import Pane, fit_view
from rex_show.image import is_markdown, is_vector, png_size
from rex_show.keys import parse_input
from rex_show.render import load_png, md_prepare, typst_png

PRODUCERS_FILE = "producers"  # Process group IDs to kill when the pane closes.
POLL_S = 0.2
PANE_CHECK_S = 2.0  # How often to check the pane still exists.
CAPTION_ROWS = 1
ZOOM_MAX = 16.0
ZOOM_SETTLE_S = 0.25  # Zoom rescales instantly; re-rasterize once input settles.
MAX_RASTER_PIXELS = 40_000_000  # Cap on re-rasterized SVG/Markdown size.
HINT = "hjkl +/-/0"


def file_stat(path):
    """(mtime, size), or None if missing; a change triggers a redraw."""
    try:
        stat = os.stat(path)
    except OSError:
        return None
    return stat.st_mtime_ns, stat.st_size


class Viewer:
    def __init__(self, source_file, term):
        self.source_file = source_file
        self.state_dir = os.path.dirname(source_file)
        self.build_dir = os.path.join(self.state_dir, "build")
        os.makedirs(self.build_dir, exist_ok=True)
        self.term = term

        self.png = None
        self.caption = ""
        self.x = 0  # Viewport origin, in raster px.
        self.y = 0
        self.zoom = 1.0  # 1 = fit the pane.
        self.raster_zoom = 1.0  # Zoom baked into the raster (vectors only).
        self.anchor = None  # (cx, cy) view centre to restore after a re-raster.
        self.drag = None  # (col, row, x, y) at drag start.
        self.vector = False

        self.resized = True  # Pane size changed: clear and redraw.
        self.rerender = False  # Re-rasterize vectors at the current zoom.
        self.rerender_at = None  # When zoom input has settled.
        self.last_key = None
        self.render_width = None  # Raster width of the current render.
        self.md_stat = None  # Markdown file stat at last full render.
        self.deps = []  # Images a Markdown doc embeds; changes redraw it.

    # --- geometry --------------------------------------------------------

    def pane(self):
        """Image area: the terminal minus the caption line."""
        full = self.term.pane()
        return Pane(full.cols, max(1, full.rows - CAPTION_ROWS), full.cell_w, full.cell_h)

    def pane_width(self):
        pane = self.pane()
        return int(pane.cols * pane.cell_w)

    def image_size(self):
        return png_size(self.png)

    def view(self):
        return fit_view(*self.image_size(), self.pane(), self.zoom, self.raster_zoom)

    def center(self):
        """View centre as fractions of the image, stable across re-rasters."""
        img_w, img_h = self.image_size()
        view = self.view()
        return (self.x + view.w_src / 2) / img_w, (self.y + view.h_src / 2) / img_h

    def center_on(self, cx, cy):
        img_w, img_h = self.image_size()
        view = self.view()
        self.x = int(cx * img_w - view.w_src / 2)
        self.y = int(cy * img_h - view.h_src / 2)

    def raster_width(self):
        """Width to rasterize vectors at: pane width times zoom, capped."""
        width = self.pane_width() * self.zoom
        if self.png is not None:
            img_w, img_h = self.image_size()
            width = min(width, (MAX_RASTER_PIXELS * img_w / img_h) ** 0.5)
        return int(width)

    # --- drawing ---------------------------------------------------------

    def place(self):
        img_w, img_h = self.image_size()
        view = self.view()
        max_x, max_y = img_w - view.w_src, img_h - view.h_src

        if self.anchor:  # Raster replaced: restore the view by fraction.
            self.center_on(*self.anchor)
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

        caption_row = self.pane().rows + 1
        return kitty.place(self.x, self.y, view) + kitty.status_line(caption_row, f"{status}  {HINT}")

    def status(self, text):
        self.term.write(kitty.status_line(self.pane().rows + 1, text))

    # --- loading ---------------------------------------------------------

    def source(self):
        """(path, change key); the key covers the file and embedded images."""
        try:
            with open(self.source_file) as f:
                path = f.read().strip()
            stat = (path, *file_stat(path))
        except (OSError, TypeError):
            return None, None

        return path, (stat, tuple(file_stat(d) for d in self.deps))

    def stale_raster(self, path):
        if not (self.resized or self.rerender) or self.png is None or not is_vector(path):
            return False
        return self.raster_width() != self.render_width

    def load(self, path, key):
        width = self.raster_width()
        self.render_width = width
        self.vector = is_vector(path)
        self.raster_zoom = width / self.pane_width() if self.vector else 1.0
        if not is_markdown(path):
            self.deps = []
            return load_png(path, width)

        md_stat = key[0]
        if md_stat != self.md_stat:  # Doc text changed: full pipeline.
            self.status(f"rendering {os.path.basename(path)}…")
            deps = md_prepare(path, self.build_dir)
            if deps is None:
                return None
            self.deps = deps
            self.md_stat = md_stat

        return typst_png(self.build_dir, width)  # Else only images changed.

    def refresh(self):
        path, key = self.source()
        if key is None or (key == self.last_key and not (self.resized or self.rerender)):
            return

        new_source = self.last_key is None or key[0][0] != self.last_key[0][0]
        changed = key != self.last_key or self.stale_raster(path)
        if new_source:
            self.md_stat = None
            self.deps = []
            self.x = self.y = 0
            self.zoom = 1.0
            self.anchor = None
        elif changed and self.png is not None and self.anchor is None:
            self.anchor = self.center()  # Keep the view across re-rasters.

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
        out = kitty.DELETE_ALL + kitty.CLEAR if clear else ""
        out += kitty.transmit(self.png) if changed or clear else ""
        self.term.write(out + self.place())
        self.resized = self.rerender = False
        self.last_key = key

    # --- input -----------------------------------------------------------

    def on_input(self, data):
        if self.png is None:
            return

        actions = parse_input(data)
        if not actions:
            return

        for action in actions:
            self.apply(action)
        self.term.write(self.place())

    def apply(self, action):
        view = self.view()
        pane = self.pane()
        kind = action[0]

        if kind == "pan":
            self.x += int(action[1] * view.w_src)
            self.y += int(action[2] * view.h_src)
        elif kind == "drag_start":
            self.drag = (action[1], action[2], self.x, self.y)
        elif kind == "drag" and self.drag:
            col, row, x, y = self.drag
            self.x = int(x - (action[1] - col) * pane.cell_w / view.scale)
            self.y = int(y - (action[2] - row) * pane.cell_h / view.scale)
        elif kind == "drag_end":
            self.drag = None
        elif kind == "top":
            self.y = 0
        elif kind == "bottom":
            self.y = self.image_size()[1]
        elif kind in ("zoom", "zoom_reset"):
            self.set_zoom(1.0 if kind == "zoom_reset" else self.zoom * action[1])

    def set_zoom(self, zoom):
        zoom = max(1.0, min(zoom, ZOOM_MAX))
        if zoom == self.zoom:
            return

        cx, cy = self.center()
        self.zoom = zoom  # place() rescales the current raster now.
        self.center_on(cx, cy)  # Now, so later actions in this read apply after.
        if self.vector:
            self.rerender_at = time.monotonic() + ZOOM_SETTLE_S

    # --- lifecycle -------------------------------------------------------

    def shutdown(self, *_):
        """Pane closed: kill producers started for it, then exit."""
        producers = os.path.join(self.state_dir, PRODUCERS_FILE)
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
            return not rexcli.exists(own)
        except Exception:  # Server unreachable: not proof of a close.
            return False

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
        self.term.setup()
        self.term.write(kitty.HIDE_CURSOR + kitty.MOUSE_ON)

        next_check = time.monotonic() + PANE_CHECK_S
        while True:
            now = time.monotonic()
            if self.rerender_at and now >= self.rerender_at:
                self.rerender_at = None
                self.rerender = True

            if now >= next_check:
                next_check = now + PANE_CHECK_S
                if self.pane_gone():
                    self.shutdown()

            data = self.term.read(POLL_S)
            if data == b"":
                self.shutdown()
            if data:
                self.on_input(data)
            self.refresh()
