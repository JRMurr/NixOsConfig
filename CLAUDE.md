# CLAUDE.md

This is a NixOS flake-based system configuration managing multiple machines with shared modules, Home Manager for user-level config, and agenix for secrets.


## Common Operations

When possible use home manager to configure programs. It lives under `common/homemanager`. 

Multiple systems use this config. So when it makes sense add options under `common/myOptions` to make custom options.

## Commands

```bash
# Build and switch the current host (uses `nh`, a nixos-rebuild wrapper)
nh os switch /etc/nixos

# Build without switching (dry run)
nh os build /etc/nixos

# Build a specific host
nixos-rebuild build --flake '.#desktop'
nixos-rebuild build --flake '.#framework'
nixos-rebuild build --flake '.#thicc-server'

# Update a single flake input
nix flake lock --update-input <input-name>
# If the custom cache is broken, bypass it
nixos-rebuild switch --option substituters 'https://cache.nixos.org'

# Nix linting
statix check .
```

## docs

You can use the nixos mcp to get nix docs for most things, some urls directly listed below as a fallback

- [Nixpkgs reference](https://nixos.org/manual/nixpkgs/stable/)
- [Home manager options](https://nix-community.github.io/home-manager/options.xhtml)