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

## ccstatusline settings version pin

`version` in `common/homemanager/llms/claude/default.nix` must match the installed
ccstatusline schema version. When the package bumps it, the tool tries to migrate and
rewrite the file, hits EROFS on the store symlink, and shows `⚠ invalid config`.

## `services.ttyd.checkOrigin` has an inverted description

The NixOS option says "Whether to allow a websocket connection from a different
origin", but it passes ttyd's `--check-origin`, which *rejects* cross-origin
upgrades. `hosts/thicc-server/ttyd.nix` sets it to `true` for the restrictive
behaviour. Worth an upstream doc fix.


## blocky's `customDNS` mapping is a wildcard

`hosts/thicc-server/blocky/default.nix` maps `${myDomain}` -> 100.95.204.122, which
answers *any* `*.jrnet.win`. The tailnet pushes `jrnet.win` as a search domain, so
failed public lookups get the suffix appended and land on Caddy instead of returning
NXDOMAIN -- the query log shows `mtalk.google.com.jrnet.win`,
`metadata.google.internal.jrnet.win`, and even `cache.jrnet.win.jrnet.win`.
Cosmetic, but it masks real NXDOMAINs.

## clightd SIGSEGVs once at every boot

`coredumpctl` shows `clightd` (5.9) dumping core ~5s after start on every boot today
(17:50:28, 20:21:41, ...), then restarting. Moot while clight is disabled, but the
system service still runs.

## X11-only user units fail under the Hyprland session

`setxkbmap.service`, `xplugd.service` (hits start-limit), and `nm-applet.service`
(`cannot open display`) fail at every Hyprland login. They belong to the X11 session
and should be gated on it.

## hypridle aborts on session exit

`hypridle` 0.1.8 dies with SIGABRT (`terminate called without an active exception`)
when the compositor socket closes (boot at 18:04 today). Cosmetic, upstream.

## wayle can't parse Hyprland `activespecialv2` events

`wayle-hyprland` 0.2.3 logs `cannot parse workspace_id ... expected integer, got ""`
on every special-workspace toggle with Hyprland 0.56. Upstream version skew.

## swaylock.nix comment says "hyprlock"

`common/homemanager/hyprland/swaylock.nix:19` — comment refers to hyprlock instances.


## clight can be D-Bus-activated without its config

`org.clight.clight.service` (from the clight package) has `Exec=.../bin/clight` with no
`--conf-file`. If `clight.service` is not running (e.g. after `nh os switch`, which stops
it and does not restart it) any client touching `org.clight.clight` — `busctl`, a bar
widget — spawns an unconfigured clight with dimmer/DPMS defaults, reintroducing the
black-screen bug. Fix: override the D-Bus service file to point at the unit, or
`systemctl --user restart clight` after a switch.

## clightd SIGSEGVs once at every boot

`coredumpctl` shows clightd (pid ~1000, uid 0) crashing with SIGSEGV a few seconds
after start on each boot; it is restarted and works. Backtrace ends in
`_dbus_connection_do_iteration_unlocked` (libdbus). Likely the "crashing bug" noted in
`hosts/framework/brightness/default.nix`.

## Graphical home-manager modules cannot be used standalone

`common/homemanager/cli.nix` is the only part of the HM tree that evaluates with
`osConfig = null` (what standalone home-manager passes, see
home-manager `modules/misc/submodule-support.nix`). hyprland, rofi, kitty,
ghostty, spicetify, xsession, and the unimported polybar/i3/dunst/redshift/slumber
still read `osConfig` directly. Giving `hosts/frame` any GUI app means mirroring
the options they need -- `myOptions.graphics.monitors`, `myOptions.theme.colors`,
`services.xserver.dpi` -- into `common/homemanager/myOptions.nix` the same way
`graphics.enable` and `llm.skills` already are.

## `nix flake check` fails on the `overlays` output

`flake.nix` exposes `overlays` as a list, but the flake schema wants an attrset
(`overlays.default`). `nix flake check` errors out before reaching the checks:
`error: expected a set but found a list`. Pre-existing on `main`; individual
checks still build via `nix build .#checks.x86_64-linux.<name>`.

## `nix.nixPath` is deprecated

`flake.nix` sets `nix.nixPath`, which every host evaluation now warns has been
renamed to `nix.settings.nix-path`.

## No LAN-reachable name for thicc-server

`hosts/frame/README.md` addresses the build host as `192.168.50.42` because nothing
on the LAN resolves the server to a LAN address: the router forwards to blocky,
which maps all of `jrnet.win` to the tailscale IP, and there is no mDNS/avahi on
the server. That is a third hardcoded address for this host, and blocky's
`cache-lan` mapping repeats it. A LAN-only `customDNS` name for the host itself
would fix the README, and an option for the LAN address would dedupe the rest.

## Frame: wheel notches arrive 80x too large in the nested desktop

`wev` in Desktop Mode shows one notch as `axis_value120: 120` (correct) but
`axis: 1200` (normal is ~15). Firefox scrolls by `axis`, so a notch acts like
page down; terminals and Vesktop use value120 and are fine. Inflated somewhere
between gamescope and the nested KWin (not narrowed down). Worked around in
Firefox with `mousewheel.default.delta_multiplier_y`; if SteamOS fixes the
relay, that pref will make Firefox scroll ~50x too slowly.
- SteamOS beta update dropped `/etc/tmpfiles.d/non-nixos-gpu.conf` and `/etc/jr/manifest` (overlay upper reset), breaking GL for Nix apps. Activation now warns, but only on the next switch; consider a login-time check (user service running `steamos-etc --check`) to catch it after an update.
