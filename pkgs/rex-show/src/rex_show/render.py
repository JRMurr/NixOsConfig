"""Converters: PNG, SVG or Markdown source -> PNG bytes. None on failure;
details go to stderr (the viewer log)."""
import json
import os
import re
import subprocess
import sys
from importlib.resources import files

from rex_show.image import is_complete_png, is_svg

MD_PAGE_WIDTH_PT = 520
PT_PER_INCH = 72
MERMAID_FENCE = re.compile(rb"^\s*```\s*mermaid", re.MULTILINE)
TYP_IMAGE = re.compile(r'image\("([^"]+)"')


def run(*cmd):
    """stdout bytes, or None if the tool is missing or fails."""
    try:
        out = subprocess.run(cmd, capture_output=True)
    except OSError as err:
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


def load_png(path, width_px):
    """PNG bytes for a PNG or SVG path, or None if unreadable or mid-write."""
    with open(path, "rb") as f:
        data = f.read()

    if is_svg(data):
        return svg_to_png(path, width_px)

    return data if is_complete_png(data) else None


def md_prepare(path, build_dir):
    """Markdown -> build_dir/main.typ, the slow stage (Mermaid, pandoc).
    Returns the local images the doc embeds, or None."""
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
                f"SOURCE_DIR = {json.dumps(os.path.dirname(os.path.abspath(path)))}\n")
        f.write(files("rex_show").joinpath("paths.lua").read_text())

    body = os.path.join(build_dir, "body.typ")
    if run("pandoc", "-f", "gfm", "-t", "typst", "--lua-filter", lua, staged, "-o", body) is None:
        return None

    theme = files("rex_show").joinpath("theme.typ").read_text()
    with open(os.path.join(build_dir, "main.typ"), "w") as f:
        f.write(theme.replace("{width}", str(MD_PAGE_WIDTH_PT)))

    with open(body) as f:
        return TYP_IMAGE.findall(f.read())


def typst_png(build_dir, width_px):
    """Compile build_dir/main.typ, the fast stage; cheap enough per frame."""
    ppi = width_px * PT_PER_INCH / MD_PAGE_WIDTH_PT
    main = os.path.join(build_dir, "main.typ")
    out = os.path.join(build_dir, "out.png")
    if run("typst", "compile", "--root", "/", "--ppi", f"{ppi:.0f}", main, out) is None:
        return None

    with open(out, "rb") as f:
        return f.read()
