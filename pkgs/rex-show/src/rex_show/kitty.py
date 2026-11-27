"""Kitty graphics protocol and the few other escapes the viewer needs."""
import base64

CHUNK = 4096  # Max base64 payload per escape, per spec.
IMAGE_ID = 1
PLACEMENT_ID = 1

DELETE_ALL = "\x1b_Ga=d,d=A,q=2\x1b\\"
CLEAR = "\x1b[2J\x1b[H"
HIDE_CURSOR = "\x1b[?25l"
MOUSE_ON = "\x1b[?1000h\x1b[?1002h\x1b[?1006h"  # Buttons, drags, SGR encoding.


def transmit(png):
    """Upload PNG bytes as IMAGE_ID, replacing any previous upload."""
    data = base64.standard_b64encode(png).decode()
    chunks = [data[i:i + CHUNK] for i in range(0, len(data), CHUNK)]
    out = []
    for i, chunk in enumerate(chunks):
        head = f"a=t,f=100,q=2,i={IMAGE_ID}," if i == 0 else ""
        out.append(f"\x1b_G{head}m={int(i < len(chunks) - 1)};{chunk}\x1b\\")
    return "".join(out)


def place(x, y, view):
    """Show a crop of IMAGE_ID at the top left. Reusing PLACEMENT_ID
    replaces the previous frame in place: no flicker."""
    return (f"\x1b[H\x1b_Ga=p,q=2,C=1,i={IMAGE_ID},p={PLACEMENT_ID},"
            f"x={x},y={y},w={view.w_src},h={view.h_src},c={view.cols},r={view.rows}\x1b\\")


def status_line(row, text):
    """Dim text on a cleared row (1-based)."""
    return f"\x1b[{row};1H\x1b[2K\x1b[2m{text}\x1b[0m"
