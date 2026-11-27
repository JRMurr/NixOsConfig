import pytest
from hypothesis import given, strategies as st

from rex_show.keys import STEP_LINE, STEP_PAGE, ZOOM_STEP, parse_input

ACTION_KINDS = {"pan", "zoom", "zoom_reset", "top", "bottom", "drag_start", "drag", "drag_end"}


@pytest.mark.parametrize("data, expected", [
    (b"j", [("pan", 0, STEP_LINE)]),
    (b"\x1b[C\x1b[6~", [("pan", STEP_LINE, 0), ("pan", 0, STEP_PAGE)]),
    (b"jjl+", [("pan", 0, STEP_LINE)] * 2 + [("pan", STEP_LINE, 0), ("zoom", ZOOM_STEP)]),
    (b"0gG", [("zoom_reset",), ("top",), ("bottom",)]),
    # Mouse wheel, SGR encoding.
    (b"\x1b[<64;5;5M", [("pan", 0, -STEP_LINE)]),
    (b"\x1b[<65;5;5M\x1b[<65;5;5M", [("pan", 0, STEP_LINE)] * 2),
    (b"\x1b[<68;5;5M", [("pan", -STEP_LINE, 0)]),  # shift+wheel
    (b"\x1b[<67;5;5M", [("pan", STEP_LINE, 0)]),  # horizontal wheel
    (b"\x1b[<72;5;5M", [("zoom", ZOOM_STEP)]),  # alt+wheel
    (b"\x1b[<81;5;5M", [("zoom", 1 / ZOOM_STEP)]),  # ctrl+wheel
    (b"\x1b[<64;5;5m", []),  # Wheel release.
    (b"\x1b[<2;5;5M", []),  # Right click.
    # Drags, plain and alt.
    (b"\x1b[<0;10;12M", [("drag_start", 10, 12)]),
    (b"\x1b[<8;10;12M", [("drag_start", 10, 12)]),
    (b"\x1b[<32;9;12M\x1b[<40;8;11M", [("drag", 9, 12), ("drag", 8, 11)]),
    (b"\x1b[<0;7;11m", [("drag_end",)]),
])
def test_parse_input(data, expected):
    assert parse_input(data) == expected


@given(st.binary())
def test_parse_input_total(data):
    """Any bytes parse without error into known actions."""
    assert all(action[0] in ACTION_KINDS for action in parse_input(data))
