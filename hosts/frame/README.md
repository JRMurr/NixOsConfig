# Steam Frame

aarch64 SteamOS with an immutable root, so there is no `nixosConfiguration` here:
the Frame gets a standalone home-manager generation built from
`common/homemanager/cli.nix`.

## One-time setup on the Frame

SteamOS replaces `/` on every update, so the store has to live under `/home`.
The Determinate installer's `steam-deck` planner does exactly that (store at
`/home/nix`, bind-mounted onto `/nix` by a systemd unit):

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install steam-deck
```

Then activate:

```bash
nix run home-manager/master -- switch --flake /etc/nixos#steamos@frame
```

Afterwards `home-manager switch --flake ...` is on `$PATH`.

## Building

Nothing in this config is cached for aarch64 yet, and the Frame is slow to build
on. Either push from a host with `boot.binfmt.emulatedSystems = [ "aarch64-linux" ]`,
or add the Frame as a remote builder.

## Not supported here

Graphical modules (hyprland, rofi, kitty/ghostty, spicetify) still read the NixOS
`osConfig`, so they cannot be imported standalone yet -- see SESSION.md. Secrets
(agenix) are deliberately left out.
