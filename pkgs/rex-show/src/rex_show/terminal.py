"""The viewer's own terminal: size, raw input, output."""
import fcntl
import os
import select
import struct
import sys
import termios
import tty

from rex_show.geometry import Pane

FALLBACK_CELL = (10, 20)  # px, when the terminal doesn't report pixel size.
READ_BYTES = 4096  # Drags and wheel bursts arrive many events at a time.


class Terminal:
    def __init__(self):
        self.stdin = sys.stdin.fileno()
        self.stdout = sys.stdout

    def setup(self):
        tty.setcbreak(self.stdin)

    def pane(self):
        raw = fcntl.ioctl(self.stdout.fileno(), termios.TIOCGWINSZ, b"\0" * 8)
        rows, cols, xpix, ypix = struct.unpack("HHHH", raw)
        cell_w = xpix / cols if xpix else FALLBACK_CELL[0]
        cell_h = ypix / rows if ypix else FALLBACK_CELL[1]
        return Pane(cols, rows, cell_w, cell_h)

    def write(self, text):
        self.stdout.write(text)
        self.stdout.flush()

    def read(self, timeout):
        """Input bytes; None on timeout; b"" once the terminal is gone."""
        try:
            if not select.select([self.stdin], [], [], timeout)[0]:
                return None
            return os.read(self.stdin, READ_BYTES)
        except InterruptedError:
            return None
        except OSError:
            return b""  # EIO: pty closed.
