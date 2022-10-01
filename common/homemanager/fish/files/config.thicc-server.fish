# bass source "~/.nix-profile/etc/profile.d/hm-session-vars.sh" # setup by home manager
bass source "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh"
eval (direnv hook fish)

set -x VISUAL vim
set -x EDITOR vim


alias nixRe="sudo nixos-rebuild switch"
