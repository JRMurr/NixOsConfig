alias cat="bat -p --paging=never"

alias cleanGit="git branch --merged | egrep -v '(^\*|master|dev)' | xargs git branch -d"
alias cleanSquash="git-delete-squashed"
alias sshAm="ssh -i ~/personal/jr.pem ec2-user@ec2-35-170-192-165.compute-1.amazonaws.com"
alias gitSyncUp="git fetch upstream; git rebase upstream/master"
alias lzd="lazydocker"
alias ls="exa --icons"

alias grm="go run main.go"