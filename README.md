# My nixos/dotfiles config

## Setup

1. `touch secrets/passwords.nix`
2. run `mkpasswd -m sha-512` to generate a password and get the hash
3. set `secrets/passwords.nix` to `{jr=<hashedPassword>}`


## Links

Basing most of the organization from based Xe https://tulpa.dev/cadey/nixos-configs and https://github.com/Xe/nixos-configs 

## TODO
- figure out agenix for secrets
- Move pkgs in `programs.nix` around to files that use it. Mainly dev tools to home-manager or something
- add root option to configure monitors/check if graphical to turn graphics stuff off