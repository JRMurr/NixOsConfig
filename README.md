# My nixos/dotfiles config

## Setup

1. `touch secrets/passwords.nix`
2. run `mkpasswd -m sha-512` to generate a password and get the hash
3. set `secrets/passwords.nix` to `{jr=<hashedPassword>}`