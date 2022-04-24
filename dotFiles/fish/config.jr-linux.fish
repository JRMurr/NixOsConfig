
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
eval /home/jr/anaconda3/bin/conda "shell.fish" "hook" $argv | source
# <<< conda initialize <<<

set -x VISUAL vim
set -x EDITOR "code"
set -x BROWSER "firefox"


alias sshBetter="TERM=linux ssh"
alias cat="bat --paging=never -p"

#thiccbot aws
alias thiccAws="ssh -i /home/jr/code/awsStuff/jr.pem ec2-user@ec2-35-170-192-165.compute-1.amazonaws.com"


# thicc bot post
alias tPost="pgcli postgresql://testusr:password@localhost:5432/thiccdb"
alias thicc="source activate thiccBot"

alias dUp="docker-compose up --remove-orphans"
alias dUpB="docker-compose up --build --remove-orphans"
alias dDown="docker-compose down"

alias codeBash="code ~/.bashrc"
alias codezsh="code ~/.zshrc"
alias codei3="code ~/.i3/config"
alias codeKitty="code ~/.config/kitty/kitty.conf"
alias codeFish="code ~/.config/fish"

alias cp="cp -i"                          # confirm before overwriting something
alias df='df -h'                          # human-readable sizes
alias free='free -m'                      # show sizes in MB
alias np='nano -w PKGBUILD'
alias more=less
alias pacDel='sudo pacman -Rs'


function resetPulse
    # https://wiki.archlinux.org/index.php/PulseAudio/Troubleshooting#Bad_configuration_files
    killall pulseaudio
    set files /tmp/pulse* ~/.pulse* ~/.config/pulse
    rm -rf $files
    pulseaudio -k
    pulseaudio --start
end