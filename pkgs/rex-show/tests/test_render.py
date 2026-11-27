import shutil

import pytest

from helpers import make_png
from rex_show import render
from rex_show.image import png_size

needs = lambda *tools: pytest.mark.skipif(  # noqa: E731
    not all(shutil.which(t) for t in tools), reason=f"needs {', '.join(tools)}")


@needs("rsvg-convert")
def test_svg_renders_at_width(tmp_path):
    svg = tmp_path / "plot.svg"
    svg.write_text('<svg xmlns="http://www.w3.org/2000/svg" width="40" height="20"/>')

    assert png_size(render.load_png(str(svg), 400)) == (400, 200)


@needs("pandoc", "typst")
def test_markdown_renders_and_reports_images(tmp_path):
    (tmp_path / "chart.png").write_bytes(make_png(20, 10))
    doc = tmp_path / "README.md"
    doc.write_text("# Title\n\nSome *text*.\n\n![chart](chart.png)\n\n![remote](https://example.com/x.png)\n")
    build = tmp_path / "build"
    build.mkdir()

    deps = render.md_prepare(str(doc), str(build))
    png = render.typst_png(str(build), 800)

    assert deps == [str(tmp_path / "chart.png")]  # Relative path made absolute; remote dropped.
    assert png_size(png)[0] == pytest.approx(800, abs=2)
