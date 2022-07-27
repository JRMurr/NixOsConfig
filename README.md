# My nixos/dotfiles config

## Setup

1. `touch secrets/passwords.nix`
2. run `mkpasswd -m sha-512` to generate a password and get the hash
3. set `secrets/passwords.nix` to `{jr=<hashedPassword>}`



## Make ISO
https://nix.dev/tutorials/building-bootable-iso-image
https://hoverbear.org/blog/nix-flake-live-media/

```fish
nix build '.#nixosConfigurations.graphicalIso.config.system.build.isoImage'
# NOTE: UPDATE of to the right usb path (df -h)
set USB_PATH /dev/null
set ISO_PATH ./result/iso/*.iso
sudo dd if=$ISO_PATH of=$USB_PATH status=progress
sync
```


## Links

Basing most of the organization from based Xe https://tulpa.dev/cadey/nixos-configs and https://github.com/Xe/nixos-configs 

## TODO
- figure out agenix for secrets
- Move pkgs in `programs.nix` around to files that use it. Mainly dev tools to home-manager or something
- go through and make sure all graphical stuff is behind the `gcfg.enable` flag