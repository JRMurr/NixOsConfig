from hypothesis import given, strategies as st

from helpers import make_png
from rex_show.image import is_complete_png, is_markdown, is_svg, is_vector, png_size

PNG = make_png(37, 11)


def test_png_size():
    assert png_size(PNG) == (37, 11)


@given(st.integers(0, len(PNG) - 1))
def test_partial_png_rejected(cut):
    """A file caught mid-write is never drawn."""
    assert not is_complete_png(PNG[:cut])


def test_complete_png_accepted():
    assert is_complete_png(PNG)


def test_sniffing():
    assert is_svg(b'<?xml version="1.0"?>\n<svg width="1">')
    assert not is_svg(PNG)
    assert is_markdown("/docs/README.md") and is_markdown("NOTES.MARKDOWN")
    assert is_vector("/a/plot.svg") and is_vector("/a/doc.md")
    assert not is_vector("/a/chart.png")
