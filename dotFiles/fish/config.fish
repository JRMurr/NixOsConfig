set -q XDG_CONFIG_HOME; or set XDG_CONFIG_HOME ~/.config

# setup zoxide https://github.com/ajeetdsouza/zoxide#installation
if type -q zoxide
    zoxide init fish | source
    set -g _ZO_DATA_DIR $HOME/.local/share/zoxide
    set -g _ZO_ECHO 1
end

# load all the custom funcs 
for file in ~/.config/fish/customFuncs/common/*
    source $file
end

set -g Z_DATA $HOME/.local/share/z/data
set -g Z_DATA_DIR $HOME/.local/share/z
set -g Z_EXCLUDE $HOME

set -g ASCII_DIR (realpath ~/asciiArt)
# bob the fish stuff
source ~/.config/fish/config/bobTheFish.fish

#aliases
source ~/.config/fish/aliases.fish

# Load additional config based on hostname
set host_config ~/.config/fish/config.(hostname).fish
test -r $host_config; and source $host_config

if test -d  ~/.config/fish/customFuncs/(hostname)
    for file in ~/.config/fish/customFuncs/(hostname)/*
        source $file
    end
end

# if [ $PWD = (realpath ~) ]; randomAsciiImage; end