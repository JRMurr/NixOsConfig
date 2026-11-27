"""rex-show FILE [-- CMD...]

Show a PNG, SVG or Markdown file in a Rex split pane beside the caller.
The pane redraws whenever FILE changes, so rewriting it in a loop gives a
live view. CMD, if given, starts in the background with the caller's env and
is killed (with its process group) when the pane closes.

Keys: +/-/0 zoom in/out/reset (alt+wheel), hjkl/arrows pan (drag, wheel,
shift+wheel), space/b page, g/G top/bottom. SVG and Markdown re-render at
the zoom level so they stay sharp. Drawn with the kitty graphics protocol.
TODO: render only the visible region so zoom past MAX_RASTER_PIXELS stays sharp.
"""
import os
import subprocess
import sys

from rex_show import rexcli
from rex_show.image import is_markdown, is_png, is_svg, SVG_SNIFF_BYTES
from rex_show.terminal import Terminal
from rex_show.viewer import PRODUCERS_FILE, Viewer

LABEL = "Graphics"
SPLIT_RATIO = 45
PRODUCER_LOG = "producer.log"
VIEWER_LOG = "viewer.log"
VIEW_FLAG = "--view"


def parse_args(argv):
    """(file, producer cmd) or None if malformed."""
    producer = []
    if "--" in argv:
        split = argv.index("--")
        argv, producer = argv[:split], argv[split + 1:]
        if not producer:
            return None

    if len(argv) != 1:
        return None

    return argv[0], producer


def state_dir(anchor):
    base = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
    path = os.path.join(base, "rex-show", anchor.rsplit(":", 1)[-1])
    os.makedirs(path, exist_ok=True)
    return path


def ensure_pane(anchor, source_file):
    pane_file = os.path.join(os.path.dirname(source_file), "pane")
    if os.path.exists(pane_file):
        with open(pane_file) as f:
            block_id = f.read().strip()
        if rexcli.is_placed(block_id):
            return block_id

    # The Rex server spawns the viewer with its own env; hand over our tools
    # and module path so it runs the same code, packaged or from source.
    viewer = ["env", f"PATH={os.environ['PATH']}", f"PYTHONPATH={os.pathsep.join(sys.path)}",
              sys.executable, "-m", "rex_show", VIEW_FLAG, source_file]
    block_id = rexcli.split_right(anchor, LABEL, SPLIT_RATIO, viewer)
    with open(pane_file, "w") as f:
        f.write(block_id)
    return block_id


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
    if not (is_png(head) or is_svg(head) or is_markdown(path)):
        sys.exit(f"rex-show: {path} is not a PNG, SVG or Markdown file")

    source_file = os.path.join(state_dir(anchor), "source")
    tmp = source_file + ".tmp"
    with open(tmp, "w") as f:
        f.write(os.path.abspath(path))
    os.replace(tmp, source_file)

    print(ensure_pane(anchor, source_file))

    if producer:
        start_producer(producer, os.path.dirname(source_file))


def view(source_file):
    sys.stderr = open(os.path.join(os.path.dirname(source_file), VIEWER_LOG), "a")
    Viewer(source_file, Terminal()).run()


def main():
    argv = sys.argv[1:]
    if len(argv) == 2 and argv[0] == VIEW_FLAG:
        view(argv[1])
        return

    args = parse_args(argv)
    if args is None:
        sys.exit(__doc__)

    show(*args)
