"""Maintain the pinned Factorio mod manifest (mods.json).

The mod portal only serves downloads to an authenticated user, and a credential
baked into a fixed-output derivation would land world-readable in the nix store.
So factorio.nix pins each mod's name/version/download-path/sha1 — all public
metadata — and a systemd oneshot does the authenticated fetch at runtime,
verifying against the pinned sha1. This tool is what keeps those pins current.

  factorio-mod add https://mods.factorio.com/mod/even-distribution
  factorio-mod update
  factorio-mod remove even-distribution

Required dependencies are resolved transitively; after any change, rebuild.
"""

import argparse
import http.client
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

PORTAL = "https://mods.factorio.com"
ATTEMPTS = 3

# Both defaults are supplied by the nix wrapper, so the game version stays tied
# to the pinned server version and doesn't have to be maintained here. The
# fallbacks are for running this file directly out of the repo.
#
# Note the manifest default points at the config repo, not the copy in the nix
# store: this tool edits the source of truth, then you rebuild.
DEFAULT_MANIFEST = os.environ.get(
    "FACTORIO_MODS_FILE", "/etc/nixos/hosts/thicc-server/factorio/mods.json"
)
DEFAULT_GAME_VERSION = os.environ.get("FACTORIO_GAME_VERSION", "2.1")


# ==============================================================================
# Portal API
# ==============================================================================


def fetch_mod(name):
    """Full portal metadata for a mod, including every release.

    Retried because `update` re-fetches every pinned mod, and the portal drops
    connections often enough that a single blip would otherwise abort the run.
    A missing mod is a hard error immediately — no point retrying a 404.
    """
    url = f"{PORTAL}/api/mods/{urllib.parse.quote(name)}/full"
    for attempt in range(1, ATTEMPTS + 1):
        try:
            with urllib.request.urlopen(url, timeout=30) as response:
                return json.load(response)
        except urllib.error.HTTPError as err:  # subclass of OSError, so first
            if err.code == 404:
                sys.exit(f"no such mod on the portal: {name}")
            problem = f"portal returned {err.code}"
        except (OSError, http.client.HTTPException) as err:
            problem = f"portal unreachable ({err})"
        if attempt < ATTEMPTS:
            time.sleep(attempt)
    sys.exit(f"{name}: {problem} after {ATTEMPTS} attempts")


def version_tuple(version):
    return tuple(int(part) for part in version.split("."))


def pick_release(mod, game_version):
    """Newest release that doesn't require a newer game than we run.

    Releases come back oldest-first, so the last compatible one is the newest.
    We accept anything built for an *older* game version rather than requiring an
    exact match, since most mods lag a point release behind.
    """
    target = version_tuple(game_version)
    compatible = [
        release
        for release in mod["releases"]
        if version_tuple(release["info_json"]["factorio_version"]) <= target
    ]
    if not compatible:
        sys.exit(f"{mod['name']}: no release compatible with factorio {game_version}")
    return compatible[-1]


# Factorio dependency syntax, e.g. "base >= 2.1.0", "? optional-mod >= 1.0",
# "(?) hidden-optional", "! incompatible-mod", "~ required-but-no-load-order".
# Only the unprefixed and "~" forms are things we actually have to download.
DEPENDENCY = re.compile(r"^\s*(?P<prefix>!|\(\?\)|\?|~)?\s*(?P<name>[^<>=\s]+)")
OPTIONAL_PREFIXES = {"!", "?", "(?)"}


def required_dependencies(release):
    names = []
    for dependency in release["info_json"].get("dependencies", []):
        match = DEPENDENCY.match(dependency)
        # "base" is the game itself, not something the portal serves.
        if match and match["prefix"] not in OPTIONAL_PREFIXES and match["name"] != "base":
            names.append(match["name"])
    return names


def resolve(roots, game_version, known=frozenset()):
    """Breadth-first walk of the required-dependency graph.

    Anything in `known` is treated as already pinned: we neither re-fetch it nor
    re-walk its dependencies, since those were walked when it was first added.

    TODO: version constraints in dependency strings ("flib >= 0.14") are ignored;
    we always take the newest compatible release. If that ever bites, the pinned
    version can be hand-edited in the manifest.
    """
    entries = {}
    queue = list(roots)
    while queue:
        name = queue.pop(0)
        if name in entries or name in known:
            continue
        mod = fetch_mod(name)
        release = pick_release(mod, game_version)
        # Use the portal's canonical casing, not whatever was typed.
        entries[mod["name"]] = {
            "name": mod["name"],
            "version": release["version"],
            "downloadPath": release["download_url"],
            "sha1": release["sha1"],
        }
        queue.extend(required_dependencies(release))
    return entries


# ==============================================================================
# Manifest file
# ==============================================================================


def load(path):
    if not os.path.exists(path):
        return {}
    with open(path) as handle:
        return {entry["name"]: entry for entry in json.load(handle)}


def save(path, entries):
    ordered = sorted(entries.values(), key=lambda entry: entry["name"].lower())
    with open(path, "w") as handle:
        json.dump(ordered, handle, indent=2)
        handle.write("\n")


def report(before, after):
    """Print what changed, so a rebuild is never a surprise."""
    for name in sorted(set(after) - set(before), key=str.lower):
        print(f"  + {name} {after[name]['version']}")
    for name in sorted(set(before) & set(after), key=str.lower):
        if before[name]["version"] != after[name]["version"]:
            print(f"  ~ {name} {before[name]['version']} -> {after[name]['version']}")
    for name in sorted(set(before) - set(after), key=str.lower):
        print(f"  - {name} {before[name]['version']}")
    if before == after:
        print("  (no changes)")


# ==============================================================================
# Commands
# ==============================================================================


def mod_name(argument):
    """Accept either a bare mod name or a pasted portal URL."""
    match = re.search(r"/mod/([^/?#]+)", argument)
    return urllib.parse.unquote(match.group(1)) if match else argument


def cmd_add(args):
    before = load(args.file)
    roots = [mod_name(argument) for argument in args.mods]
    after = dict(before)
    after.update(resolve(roots, args.game_version, known=set(before)))
    return before, after


def cmd_update(args):
    before = load(args.file)
    # Every pinned mod is treated as a root. A mod that *drops* a dependency
    # therefore leaves it behind as an orphan; remove those by hand.
    return before, resolve(list(before), args.game_version)


def cmd_remove(args):
    before = load(args.file)
    after = dict(before)
    for argument in args.mods:
        name = mod_name(argument)
        if name not in after:
            sys.exit(f"not in the manifest: {name}")
        # Dependencies pulled in for this mod are left alone; `remove` them too
        # if nothing else needs them.
        del after[name]
    return before, after


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--file", default=DEFAULT_MANIFEST, help="manifest to edit")
    parser.add_argument(
        "--game-version",
        default=DEFAULT_GAME_VERSION,
        help="only pin releases built for this factorio version or older",
    )
    subcommands = parser.add_subparsers(dest="command", required=True)

    add = subcommands.add_parser("add", help="pin a mod and its dependencies")
    add.add_argument("mods", nargs="+", metavar="NAME_OR_URL")
    add.set_defaults(run=cmd_add)

    update = subcommands.add_parser("update", help="re-pin everything to newest")
    update.set_defaults(run=cmd_update)

    remove = subcommands.add_parser("remove", help="unpin a mod")
    remove.add_argument("mods", nargs="+", metavar="NAME_OR_URL")
    remove.set_defaults(run=cmd_remove)

    args = parser.parse_args()
    before, after = args.run(args)
    report(before, after)
    if before != after:
        save(args.file, after)
        print(f"\nwrote {args.file} — rebuild to apply")


if __name__ == "__main__":
    main()
