bass source "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh"
# impure since nix-ld-vscode needs it
alias nixRe="sudo nixos-rebuild switch --flake '/mnt/f/nixWsl/NixOsConfig/#wsl' --impure"
