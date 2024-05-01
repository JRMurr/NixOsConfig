alias cat="bat -p --paging=never"

alias cleanGit="git branch --merged | egrep -v '(^\*|master|dev)' | xargs git branch -d"
alias cleanSquash="git-delete-squashed"
alias gitSyncUp="git fetch upstream; git rebase upstream/master"
alias lzd="lazydocker"
alias ls="exa --icons"

alias nbf="nix build -L --file"
function nobf --wraps 'nix build -L --file' --description 'nom build -L --file'
    nom build -L --file $argv
end
