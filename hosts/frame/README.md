# Steam Frame

aarch64 SteamOS with an immutable root, so there is no `nixosConfiguration` here:
the Frame gets a standalone home-manager generation built from
`common/homemanager/cli.nix`.

## One-time setup on the Frame

SteamOS replaces `/` on every update, so the store has to live under `/home`.
The installer's `steam-deck` planner does that (store at `/home/nix`, bind-mounted
onto `/nix` by a systemd unit), but it still writes to `/etc`, so the root has to
be writable while it runs:

```bash
passwd                                # if you haven't set one
sudo steamos-readonly disable

sudo mkdir -p /etc/tmpfiles.d         # SteamOS ships without it; the installer expects it

curl -fsSL -o nix-installer.sh https://artifacts.nixos.org/nix-installer
less nix-installer.sh                 # small wrapper that fetches the binary for your arch
sh nix-installer.sh install steam-deck --enable-flakes

sudo steamos-readonly enable
```

Then activate:

```bash
nix run home-manager/master -- switch --flake /etc/nixos#steamos@frame
```

Afterwards `home-manager switch --flake ...` is on `$PATH`.

## Activating

The repo is cloned on the Frame (paths below assume `~/nixos`). The first switch
does not need the home-manager CLI -- build the generation and run its activation
script directly:

```bash
cd ~/nixos
nix build '.#homeConfigurations."steamos@frame".activationPackage'
HOME_MANAGER_BACKUP_EXT=backup ./result/activate
```

`HOME_MANAGER_BACKUP_EXT` is what `home-manager switch -b backup` sets; without it
activation aborts on the `~/.bashrc` and `~/.config/fish` SteamOS already ships.

After that `programs.home-manager.enable` has put the CLI on `$PATH`:

```bash
home-manager switch --flake ~/nixos#steamos@frame
```

Nix resolves every flake input, including the private `nix-secrets` one, even
though nothing in this configuration reads it. The Frame needs an ssh key with
read access to that repo.

## Build host

aarch64 builds go to thicc-server. The client half is a flag for now rather than a
`nix.buildMachines` entry in `./home.nix`.

The server half is not optional: thicc-server can only build aarch64 at all
because `hosts/thicc-server/remote-builder.nix` turns on binfmt, which is what
adds `aarch64-linux` to its `extra-platforms`.

Setup, once:

1. On the Frame, make the key the nix daemon will use:

   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/id_builder -N ""
   cat ~/.ssh/id_builder.pub
   ```

2. Append that public key to `common/users/jr-keys.txt` and rebuild thicc-server.
   Builds run as `jr`, which `common/default.nix` already lists in
   `nix.settings.trusted-users`.

3. `builders` is a restricted setting, so the `steamos` user has to be trusted
   locally too:

   ```bash
   nix config show trusted-users
   ```

   If it lists neither `steamos` nor `@wheel`, add it to `/etc/nix/nix.conf`
   (`sudo steamos-readonly disable` first) and `sudo systemctl restart nix-daemon`.
   SteamOS updates replace `/`, so that edit has to be redone afterwards; the
   store under `/home/nix` survives.

Then, on every build:

```bash
nix build '.#homeConfigurations."steamos@frame".activationPackage' --max-jobs 0 \
  --builders 'ssh-ng://jr@192.168.50.42 aarch64-linux /home/steamos/.ssh/id_builder 8 1 big-parallel - c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUZwamJtYStiMkg1SUFBMWNjZ0NEditlVWRkS3Bhc0Y2NkdJYURsZ1dFZTEK'
```

`home-manager switch` passes both flags through to nix, so the same two work there.

The fields are uri, systems, ssh key, max jobs, speed factor, supported features,
mandatory features (`-` for none), and the host's public key, `base64 -w0` of its
`/etc/ssh/ssh_host_ed25519_key.pub`. That last field is worth keeping: the daemon
connects as root, and root's `known_hosts` lives on the SteamOS root that every
system update replaces. `--max-jobs 0` is what actually forces the offload --
the Frame is aarch64 itself, so otherwise nix just builds locally.

192.168.50.42 rather than a name: bare `thicc-server` does not resolve from the
Frame, and `thicc-server.jrnet.win` answers with the tailscale address
(`100.95.204.122`), unreachable without tailscale. It is a DHCP lease, so reserve
it on the router or expect to fix up the command.

## Not supported here

Graphical modules (hyprland, rofi, kitty/ghostty, spicetify) still read the NixOS
`osConfig`, so they cannot be imported standalone yet -- see SESSION.md. Secrets
(agenix) are deliberately left out.
