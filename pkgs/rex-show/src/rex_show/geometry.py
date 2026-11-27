"""Viewport maths: which part of an image to show, and how big."""
from dataclasses import dataclass


@dataclass(frozen=True)
class Pane:
    """Drawable area in cells, and each cell's size in px."""
    cols: int
    rows: int
    cell_w: float
    cell_h: float


@dataclass(frozen=True)
class View:
    """Crop of the raster (px) and the cells it fills on screen."""
    w_src: int
    h_src: int
    cols: int
    rows: int
    scale: float  # Screen px per raster px.


def fit_view(img_w, img_h, pane, zoom=1.0, raster_zoom=1.0):
    """At zoom 1 the image fits the pane's width (tall images scroll).

    raster_zoom is the zoom already baked into a re-rasterized vector image,
    so a raster k times larger shows the same part of it."""
    pane_w, pane_h = pane.cols * pane.cell_w, pane.rows * pane.cell_h
    logical_w = img_w / raster_zoom
    scale = (pane_w / logical_w) * zoom / raster_zoom

    w_src = min(img_w, round(pane_w / scale))  # Round, not truncate: float error
    h_src = min(img_h, round(pane_h / scale))  # would drop the last px column.
    cols = min(pane.cols, max(1, round(w_src * scale / pane.cell_w)))
    rows = min(pane.rows, max(1, round(h_src * scale / pane.cell_h)))
    return View(w_src, h_src, cols, rows, scale)
