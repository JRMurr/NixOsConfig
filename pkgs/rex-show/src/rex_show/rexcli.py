"""Thin wrapper over the rex CLI."""
import json
import subprocess

PLACED = "placed"


def rex(*args):
    out = subprocess.run(["rex", *args], capture_output=True, text=True, check=True)
    return json.loads(out.stdout) if "--json" in args else out.stdout


def blocks():
    return rex("block", "ls", "--json")["blocks"]


def is_placed(block_id):
    return any(b["block_id"] == block_id and b.get("placement") == PLACED for b in blocks())


def exists(block_id):
    """False once the block is gone, including a UI close kept for undo.
    Raises if the server can't be asked."""
    return any(b["block_id"] == block_id for b in blocks())


def split_right(anchor, label, ratio, cmd):
    """New pane right of anchor running cmd, without taking focus."""
    created = rex("split", "-b", anchor, "--split=right", "--ratio", str(ratio),
                  "--label", label, "--focus=false", "--shell=none", "--json", "--", *cmd)
    return created["block_ids"][0]
