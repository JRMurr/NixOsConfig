import base64
import re

from hypothesis import given, strategies as st

from rex_show import kitty

APC = re.compile(r"\x1b_G([^;]*);([^\x1b]*)\x1b\\")


@given(st.binary(min_size=1, max_size=20_000))
def test_transmit_chunks_round_trip(png):
    escapes = APC.findall(kitty.transmit(png))
    payloads = [payload for _, payload in escapes]
    more_flags = [dict(kv.split("=") for kv in keys.split(","))["m"] for keys, _ in escapes]

    assert all(len(p) <= kitty.CHUNK for p in payloads)
    assert more_flags == ["1"] * (len(escapes) - 1) + ["0"]
    assert base64.standard_b64decode("".join(payloads)) == png
    assert "i=1" in escapes[0][0] and "a=t" in escapes[0][0]
