import shutil

import pytest

from helpers import FakeTerminal, make_png
from rex_show.keys import ZOOM_STEP
from rex_show.viewer import Viewer

TALL = (800, 4000)  # px; fits pane width (1000px) after scaling, scrolls vertically.


@pytest.fixture
def show(tmp_path):
    """Viewer pointed at an image file; returns (viewer, terminal)."""
    def _show(name, data):
        image = tmp_path / name
        image.write_bytes(data)
        source = tmp_path / "state" / "source"
        source.parent.mkdir()
        source.write_text(str(image))

        term = FakeTerminal()
        viewer = Viewer(str(source), term)
        viewer.refresh()
        return viewer, term
    return _show


def test_draws_png(show):
    viewer, term = show("chart.png", make_png(*TALL))

    out = "".join(term.out)
    assert "a=t" in out and "a=p" in out
    assert "chart.png  800x4000" in out


def test_pan_clamps_to_edges(show):
    viewer, _ = show("chart.png", make_png(*TALL))
    view = viewer.view()

    viewer.on_input(b"k")  # Already at the top.
    assert viewer.y == 0

    viewer.on_input(b"G")
    assert viewer.y == TALL[1] - view.h_src

    viewer.on_input(b"j")  # Already at the bottom.
    assert viewer.y == TALL[1] - view.h_src


def test_zoom_keeps_centre(show):
    viewer, _ = show("chart.png", make_png(*TALL))
    viewer.on_input(b"jj")
    before = viewer.center()

    viewer.on_input(b"+++")
    after = viewer.center()

    assert viewer.zoom == pytest.approx(ZOOM_STEP ** 3)
    assert after == pytest.approx(before, abs=0.01)


def test_drag_moves_content_with_mouse(show):
    viewer, _ = show("chart.png", make_png(*TALL))
    viewer.on_input(b"+++G")  # Zoomed so both axes can move.
    x, y = viewer.x, viewer.y

    # Drag the mouse right and up: content follows, so the view moves left and down.
    viewer.on_input(b"\x1b[<0;50;20M\x1b[<32;60;15M\x1b[<0;60;15m")

    assert viewer.x < x
    assert viewer.y == y  # Already at the bottom; clamped.


def test_new_source_resets_view(show, tmp_path):
    viewer, _ = show("chart.png", make_png(*TALL))
    viewer.on_input(b"++G")

    other = tmp_path / "other.png"
    other.write_bytes(make_png(100, 100))
    (tmp_path / "state" / "source").write_text(str(other))
    viewer.refresh()

    assert (viewer.zoom, viewer.x, viewer.y) == (1.0, 0, 0)
    assert viewer.caption == "other.png"


def test_partial_write_keeps_last_frame(show, tmp_path):
    viewer, term = show("chart.png", make_png(*TALL))
    frame = viewer.png

    (tmp_path / "chart.png").write_bytes(make_png(*TALL)[:-10])
    viewer.refresh()

    assert viewer.png == frame


@pytest.mark.skipif(not shutil.which("rsvg-convert"), reason="needs librsvg")
def test_svg_rerasterizes_after_zoom(show):
    svg = b'<svg xmlns="http://www.w3.org/2000/svg" width="400" height="300"><rect width="400" height="300"/></svg>'
    viewer, _ = show("plot.svg", svg)
    width = viewer.image_size()[0]

    viewer.on_input(b"++")
    viewer.rerender = True  # As if zoom input settled.
    viewer.refresh()

    assert viewer.image_size()[0] == pytest.approx(width * ZOOM_STEP ** 2, rel=0.01)
