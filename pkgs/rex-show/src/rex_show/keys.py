"""Terminal input (keys, SGR mouse) -> viewer actions.

Actions: ("pan", dx, dy) in fractions of the view, ("zoom", factor),
("zoom_reset",), ("top",), ("bottom",), ("drag_start", col, row),
("drag", col, row), ("drag_end",).
"""
import re

STEP_LINE = 0.1  # Fraction of the visible size per line pan.
STEP_PAGE = 0.9
ZOOM_STEP = 1.25

KEYS = {
    b"j": ("pan", 0, STEP_LINE), b"\x1b[B": ("pan", 0, STEP_LINE),
    b"k": ("pan", 0, -STEP_LINE), b"\x1b[A": ("pan", 0, -STEP_LINE),
    b"l": ("pan", STEP_LINE, 0), b"\x1b[C": ("pan", STEP_LINE, 0),
    b"h": ("pan", -STEP_LINE, 0), b"\x1b[D": ("pan", -STEP_LINE, 0),
    b" ": ("pan", 0, STEP_PAGE), b"f": ("pan", 0, STEP_PAGE), b"\x1b[6~": ("pan", 0, STEP_PAGE),
    b"b": ("pan", 0, -STEP_PAGE), b"\x1b[5~": ("pan", 0, -STEP_PAGE),
    b"+": ("zoom", ZOOM_STEP), b"=": ("zoom", ZOOM_STEP),
    b"-": ("zoom", 1 / ZOOM_STEP), b"0": ("zoom_reset",),
    b"g": ("top",), b"G": ("bottom",),
}

# SGR mouse: ESC [ < button ; col ; row M (press) or m (release).
INPUT_TOKEN = re.compile(
    rb"\x1b\[<(\d+);(\d+);(\d+)([Mm])|\x1b\[[0-9;]*[~A-Za-z]|.", re.DOTALL)
BUTTON_LEFT, MOTION = 0, 32
WHEEL_UP, WHEEL_DOWN, WHEEL_LEFT, WHEEL_RIGHT = 64, 65, 66, 67
MOD_SHIFT, MOD_ALT, MOD_CTRL = 4, 8, 16


def mouse_action(button, col, row, pressed):
    base = button & ~(MOD_SHIFT | MOD_ALT | MOD_CTRL)
    if base == BUTTON_LEFT:  # Plain or alt drag pans.
        return ("drag_start", col, row) if pressed else ("drag_end",)
    if base == BUTTON_LEFT | MOTION:
        return ("drag", col, row)
    if not pressed:
        return None

    sign = {WHEEL_UP: -1, WHEEL_DOWN: 1, WHEEL_LEFT: -1, WHEEL_RIGHT: 1}.get(base)
    if sign is None:
        return None

    if base in (WHEEL_LEFT, WHEEL_RIGHT) or button & MOD_SHIFT:
        return ("pan", sign * STEP_LINE, 0)
    if button & (MOD_ALT | MOD_CTRL):  # Rex's window takes ctrl+wheel.
        return ("zoom", ZOOM_STEP if sign < 0 else 1 / ZOOM_STEP)
    return ("pan", 0, sign * STEP_LINE)


def parse_input(data):
    """Raw terminal input -> list of actions; one read may hold many events."""
    actions = []
    for match in INPUT_TOKEN.finditer(data):
        if match.group(1) is not None:
            button, col, row = (int(match.group(i)) for i in (1, 2, 3))
            action = mouse_action(button, col, row, match.group(4) == b"M")
        else:
            action = KEYS.get(match.group(0))
        if action:
            actions.append(action)
    return actions
