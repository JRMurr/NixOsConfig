"""Test fixtures: real PNG bytes and a fake terminal."""
import struct
import zlib

from rex_show.geometry import Pane

PNG_MAGIC = b"\x89PNG\r\n\x1a\n"
RGB_8BIT = (8, 2)  # bit depth, colour type


def _chunk(kind, data):
    body = kind + data
    return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body))


def make_png(width, height):
    """A valid, solid-black RGB PNG."""
    ihdr = struct.pack(">IIBBBBB", width, height, *RGB_8BIT, 0, 0, 0)
    row = b"\0" + b"\0" * (3 * width)  # Filter byte + pixels.
    idat = zlib.compress(row * height)
    return PNG_MAGIC + _chunk(b"IHDR", ihdr) + _chunk(b"IDAT", idat) + _chunk(b"IEND", b"")


class FakeTerminal:
    """Fixed-size terminal that records output."""

    def __init__(self, pane=Pane(cols=100, rows=50, cell_w=10, cell_h=20)):
        self._pane = pane
        self.out = []

    def pane(self):
        return self._pane

    def write(self, text):
        self.out.append(text)
