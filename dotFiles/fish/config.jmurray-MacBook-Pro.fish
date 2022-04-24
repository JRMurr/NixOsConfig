if type -q nvm
    nvm use 14
end
if type -q direnv
    direnv hook fish | source
end
sudo ifconfig lo0 alias 10.0.2.2

# ghcup-env
set -q GHCUP_INSTALL_BASE_PREFIX[1]; or set GHCUP_INSTALL_BASE_PREFIX $HOME
test -f /Users/jmurray/.ghcup/env ; and set -gx PATH $HOME/.cabal/bin /Users/jmurray/.ghcup/bin $PATH

#misc
alias myip="ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'"
alias jsonJs="pbpaste | json-to-js --spaces=4 | pbcopy; pbpaste"


set -g BODATA_DIR "/Users/jmurray/immuta/bodata"
set -g FINGERPRINT_DIR "/Users/jmurray/immuta/fingerprint"
set -g CLI_DIR "/Users/jmurray/immuta/cli"
set -g -x NODE_OPTIONS "--max_old_space_size=5120"


set -x GOPATH /Users/jmurray/go/
set -x PATH $PATH /usr/local/go/bin $GOPATH/bin

alias sshB="ssh -A -l jmurray bastion.immuta.com"
alias gUnit="grunt mocha_istanbul:unit"
alias bocode="code ~/immuta/bodata"
alias fingerCode="code ~/immuta/fingerprint"
alias cliCode="code ~/immuta/cli"


alias pgKris="psql -d immuta -U kris -h localhost"
alias pgJeff="psql -d immuta -U jeff -h localhost"
alias cliKris="pgcli postgresql://kris:pass@db.immuta:5432/immuta"
alias cliJeff="pgcli \"postgresql://jeff:pass@db.immuta:5432/immuta?sslmode=require\""
alias devBash="docker exec -i -t immuta-db-dev /bin/bash"
alias devPost="docker exec -i -t immuta-db-dev psql -d bometadata -U bometa"
alias dockerBash="docker exec -i -t bodata_postgres /bin/bash"
alias postLogs="docker logs bodata_postgres -f"
alias devLogs="docker logs immuta-db-dev -f"
alias dockerPost="docker exec -i -t bodata_postgres psql -d bometadata -U bometa"
alias pgBo="pgcli postgresql://bometa:secret@localhost:5432/bometadata"
alias pgFe=" psql postgresql://feature_service:secret@localhost:5432/immuta"
alias buildRun="bash ~/scripts/buildBodataPost.sh; sleep 40; npm start"
alias cdBo="cd ~/immuta/bodata/service"
alias fdwIT="IT_UNOBFUSCATED=true npm run mocha -- fdw_it/fdw.it.spec.js"
alias nodeIT="IT_UNOBFUSCATED=true npm run mocha -- it/*.spec.js"
alias npmc="cd ~/immuta/bodata/service && npm run console:dev"
alias npms="cd ~/immuta/bodata/service && npm run server:dev"


# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
eval /Users/jmurray/opt/anaconda3/bin/conda "shell.fish" "hook" $argv | source
# <<< conda initialize <<<

function fingerBash
    docker exec -it immuta-fingerprint /bin/bash 
end

function mochaFile
    npx _mocha --inline-diffs -r source-map-support/register -r ts-node/register --timeout 999999 --colors $argv
end

function im --wraps="immuta"
    pushd $CLI_DIR
    go run main.go $argv
    popd
end

function imComplete
    pushd $CLI_DIR
    go run main.go completion fish > ~/.config/fish/completions/immuta.fish
    popd
end

function kubePub --wraps="kubectl"
    kubectl --context kube-1.partner.immuta.com:jmurray $argv
end