from hypothesis import assume, given, strategies as st

from rex_show.geometry import Pane, fit_view

dims = st.integers(min_value=1, max_value=20_000)
panes = st.builds(Pane, cols=st.integers(1, 400), rows=st.integers(1, 200),
                  cell_w=st.floats(4, 30), cell_h=st.floats(8, 60))
zooms = st.floats(1, 16)


@given(dims, dims, panes, zooms)
def test_view_within_image_and_pane(img_w, img_h, pane, zoom):
    view = fit_view(img_w, img_h, pane, zoom)

    assert 0 <= view.w_src <= img_w
    assert 0 <= view.h_src <= img_h
    assert 1 <= view.cols <= pane.cols
    assert 1 <= view.rows <= pane.rows


@given(dims, dims, panes)
def test_unzoomed_shows_full_width(img_w, img_h, pane):
    assert fit_view(img_w, img_h, pane).w_src == img_w


@given(dims, dims, panes, zooms, zooms)
def test_more_zoom_shows_less(img_w, img_h, pane, zoom_a, zoom_b):
    lo, hi = sorted((zoom_a, zoom_b))
    a, b = fit_view(img_w, img_h, pane, lo), fit_view(img_w, img_h, pane, hi)

    assert b.w_src <= a.w_src
    assert b.h_src <= a.h_src


@given(st.integers(100, 4000), st.integers(100, 4000), panes, zooms, st.floats(1, 8))
def test_raster_zoom_keeps_visible_fraction(img_w, img_h, pane, zoom, raster_zoom):
    """A vector re-rasterized k times larger shows the same part of it."""
    plain = fit_view(img_w, img_h, pane, zoom)
    big_w, big_h = round(img_w * raster_zoom), round(img_h * raster_zoom)
    big = fit_view(big_w, big_h, pane, zoom, raster_zoom)
    assume(plain.w_src > 10 and plain.h_src > 10)

    assert abs(plain.w_src / img_w - big.w_src / big_w) < 0.02
    assert abs(plain.h_src / img_h - big.h_src / big_h) < 0.02
