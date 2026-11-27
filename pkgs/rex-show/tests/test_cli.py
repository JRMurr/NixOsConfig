import pytest

from rex_show.cli import parse_args


@pytest.mark.parametrize("argv, expected", [
    (["chart.png"], ("chart.png", [])),
    (["doc.md", "--", "python3", "live.py", "-v"], ("doc.md", ["python3", "live.py", "-v"])),
    (["doc.md", "--", "a", "--", "b"], ("doc.md", ["a", "--", "b"])),  # Only first -- splits.
])
def test_parse_args(argv, expected):
    assert parse_args(argv) == expected


@pytest.mark.parametrize("argv", [[], ["a.png", "b.png"], ["doc.md", "--"], ["--", "cmd"]])
def test_parse_args_rejects(argv):
    assert parse_args(argv) is None
