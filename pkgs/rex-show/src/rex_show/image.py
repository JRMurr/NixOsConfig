"""Recognising source files and reading PNG headers."""
import struct

PNG_MAGIC = b"\x89PNG\r\n\x1a\n"
PNG_IEND = b"IEND\xaeB`\x82"  # Final chunk; absent while a file is mid-write.
PNG_DIMS = slice(16, 24)  # IHDR width/height offsets.
SVG_SNIFF_BYTES = 1024
MD_EXTENSIONS = (".md", ".markdown")
SVG_EXTENSION = ".svg"


def is_png(head):
    return head.startswith(PNG_MAGIC)


def is_complete_png(data):
    return is_png(data) and data.endswith(PNG_IEND)


def is_svg(head):
    return b"<svg" in head[:SVG_SNIFF_BYTES]


def is_markdown(path):
    return path.lower().endswith(MD_EXTENSIONS)


def is_vector(path):
    """Sources rasterized at the pane's size, so zoom re-renders them sharp."""
    return is_markdown(path) or path.lower().endswith(SVG_EXTENSION)


def png_size(png):
    return struct.unpack(">II", png[PNG_DIMS])
