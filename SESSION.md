# Deferred items

Incidental things noticed while working, not blocking anything.

## Slow network path to registry.npmjs.org / Cloudflare

From thicc-server, TLS handshakes to `registry.npmjs.org` (Cloudflare anycast, 104.16.x.x)
take 3-4s and TCP connects up to 1s, varying per attempt. `cache.nixos.org` and `github.com`
are consistently fast, so this is specific to that path. Ruled out: PMTU black hole (1472-byte
DF pings pass) and IPv6-only breakage.

This broke the catppuccin vscode extension build, worked around in `pkgs/vscode.nix` by
lowering pnpm's parallel fetches. Anything else that pulls many small files from npm is
likely to hit the same thing.

## `wsl` host does not evaluate

`nix eval .#nixosConfigurations.wsl.config.system.build.toplevel.drvPath` fails:

```
Failed assertions:
- age.identityPaths must be set, for example by enabling openssh.
```

Pre-existing (fails on `main` too). It is the only host not covered by the
`nix-cache-build` job, because it cannot be built at all.

## `myOptions.tailscale.tailNetName` is declared but never read

`common/myOptions/tailscale.nix` defines `tailNetName = "tail19e8e.ts.net"`, but nothing
consumes it. Meanwhile `common/tailscale.nix` hardcodes a different, older-style domain in
`networking.search`: `johnreillymurray.gmail.com.beta.tailscale.net`. One of the two is stale.

## thicc-server's tailscale IP is hardcoded in two places

`100.95.204.122` appears in `hosts/thicc-server/postgres.nix:9` (already carries a
`TODO: make this a config option`) and `hosts/thicc-server/blocky/default.nix:74-79`.
Blocky's `jrnet.win` mapping is what makes `cache.jrnet.win` resolve internally, so this
one matters to the binary cache.

## Dead cachix leftovers

`scripts/pushStore.sh` still pushes to `jrmurr` cachix, which was commented out of
`common/default.nix` in `d607f6c`. `cachix` is still in
`common/homemanager/programs.nix:66`. Harmless, just unused.

## ntfy failure notifications bury the actual error

`notify-failure@` sends the last 40 journal lines. Because `nix-cache-build` runs with
`--keep-going`, that tail is almost entirely `building '/nix/store/...drv'...` noise and the
`FAILED: <host>` / `EVAL FAILED: <host>` markers scroll off. The body should lead with those
markers and keep only a short tail after them.

## ccstatusline settings version pin

`version` in `common/homemanager/llms/claude/default.nix` must match the installed
ccstatusline schema version. When the package bumps it, the tool tries to migrate and
rewrite the file, hits EROFS on the store symlink, and shows `⚠ invalid config`.

## `services.ttyd.checkOrigin` has an inverted description

The NixOS option says "Whether to allow a websocket connection from a different
origin", but it passes ttyd's `--check-origin`, which *rejects* cross-origin
upgrades. `hosts/thicc-server/ttyd.nix` sets it to `true` for the restrictive
behaviour. Worth an upstream doc fix.
