# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A NixOS flake-based system configuration managing multiple machines with shared modules, Home Manager for user-level config, agenix for secrets, and a catppuccin theme throughout.

## Common Commands

```bash
# Build and switch the current host (uses `nh`, a nixos-rebuild wrapper)
nh os switch /etc/nixos

# Build without switching (dry run)
nh os build /etc/nixos

# Build a specific host
nixos-rebuild switch --flake '.#desktop'
nixos-rebuild switch --flake '.#framework'
nixos-rebuild switch --flake '.#thicc-server'

# Update a single flake input
nix flake lock --update-input <input-name>

# Update secrets input specifically
./updateSecrets.sh

# Build the graphical ISO
nix build '.#nixosConfigurations.graphicalIso.config.system.build.isoImage'

# If the custom cache is broken, bypass it
nixos-rebuild switch --option substituters 'https://cache.nixos.org'

# Nix linting
statix check .
```

## Architecture

### Hosts (`hosts/`)
Each subdirectory is a machine. All import `../../common` as their base:
- **desktop** - Main workstation. Uses Lanzaboote for secure boot, NVIDIA graphics, gaming
- **framework** - Framework laptop. Uses nixos-hardware module, fingerprint reader, gestures
- **thicc-server** - Headless home server. Runs Caddy, Blocky DNS, FreshRSS, Grafana/Prometheus/Loki monitoring, Factorio, Mopidy, Linkding, Attic cache, PostgreSQL
- **wsl** - Windows Subsystem for Linux (headless, no graphics)

The `mkSystem` helper in `flake.nix` composes `defaultModules` (agenix, home-manager, catppuccin, overlays, allowUnfree) with host-specific modules.

### Common modules (`common/`)
Shared NixOS config imported by all hosts. `common/default.nix` aggregates all submodules (audio, fonts, SSH, kernel, etc.).

**`common/myOptions/`** - Custom NixOS options under `myOptions.*` that act as feature flags. Hosts set these to toggle functionality:
- `myOptions.graphics.enable` - graphical desktop (disabled on server/wsl)
- `myOptions.gestures.enable` - touchpad gestures (framework only)
- `myOptions.networkShares.enable`, `myOptions.containers.enable`, `myOptions.lock.enable`, etc.
- `myOptions.graphics.monitors` - per-monitor config (resolution, position, scale, workspace, wallpaper)

### Home Manager (`common/homemanager/`, `common/users/`)
User-level dotfiles/programs managed via Home Manager. The entry point is:
- `common/users/jr.nix` - creates the `jr` user account (system-level), assigns home-manager config
- `common/users/jr/default.nix` - imports HM modules (catppuccin, spicetify, agenix) and `common/homemanager/`
- `common/homemanager/default.nix` - aggregates all HM modules: fish, git, hyprland, kitty, helix, zed, starship, rofi, etc.

Programs configured via HM have their own files in `common/homemanager/` (e.g., `kitty.nix`, `zed.nix`, `helix.nix`). Subdirectories exist for more complex configs (`hyprland/`, `fish/`, `git/`, `i3/`, `nushell/`, `polybar/`, `slumber/`).

### Custom packages (`pkgs/`)
`pkgs/overlay.nix` defines a nixpkgs overlay with custom/patched packages (caddy-with-plugins, glance, polybar-spotify, version overrides for mopidy-iris, lastpass-cli, vscode-extensions). `pkgs/default.nix` exposes them as a callPackage set.

### Server-specific patterns (`hosts/thicc-server/`)
The server uses a custom `myCaddy` option module (`caddy/options.nix`) with `myCaddy.reverseProxies` to declaratively define reverse proxy entries that get generated into Caddyfile config.

### Secrets
Managed via agenix. Secrets live in a separate private repo (`git+ssh://git@github.com/JRMurr/nix-secrets`). Run `./updateSecrets.sh` to pull the latest.

### Templates (`templates/`)
Flake templates for new projects: `common` (basic direnv+flake-utils), `zig`, `rust`, `rust-bevy`. Used via `nix flake init -t /etc/nixos#<template-name>`.

### Flake compatibility
`default.nix` and `legacyCommon.nix` provide non-flake access via `flake-compat` for legacy nix usage.

## Key Conventions

- The flake tracks **nixpkgs unstable**
- The `nh` tool is the preferred way to rebuild (`programs.nh` is enabled with `flake = "/etc/nixos"`)
- Feature toggles use `myOptions.*` - check `common/myOptions/default.nix` for available options
- Home Manager uses `useGlobalPkgs = true` and `useUserPackages = true` (no separate nixpkgs for HM)
- The primary user is `jr` with fish shell; the `jmurray` user exists for the server
