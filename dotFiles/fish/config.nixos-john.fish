bass source "~/.nix-profile/etc/profile.d/hm-session-vars.sh" # setup by home manager
eval (direnv hook fish)

set -x VISUAL vim
set -x EDITOR "code"
set -x BROWSER "firefox"


alias nixRe="sudo nixos-rebuild switch"


function resetPulse
    # https://wiki.archlinux.org/index.php/PulseAudio/Troubleshooting#Bad_configuration_files
    killall pulseaudio
    # set files /tmp/pulse* ~/.pulse* ~/.config/pulse
    # rm -rf $files
    pulseaudio -k
    pulseaudio --start
end