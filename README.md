# My nixos/dotfiles config

## common sadness

if my own cache is being weird, use

```shell
nixos-rebuild switch --option substituters 'cache.nixos.org'
```

## Make ISO

https://nix.dev/tutorials/building-bootable-iso-image
https://hoverbear.org/blog/nix-flake-live-media/

```fish
nix build '.#nixosConfigurations.graphicalIso.config.system.build.isoImage'
# NOTE: UPDATE of to the right usb path
set USB_PATH /dev/null
set ISO_PATH ./result/iso/*.iso
sudo dd if=$ISO_PATH of=$USB_PATH status=progress
sync
```

## Links

Basing most of the organization from based Xe https://tulpa.dev/cadey/nixos-configs and https://github.com/Xe/nixos-configs
