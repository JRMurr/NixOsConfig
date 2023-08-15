set -q XDG_CONFIG_HOME; or set XDG_CONFIG_HOME ~/.config

# # setup zoxide https://github.com/ajeetdsouza/zoxide#installation
if type -q zoxide
    # this is setup by homemanager but not the env vars
    # zoxide init fish | source
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

set -U fish_greeting

# bob the fish stuff
source ~/.config/fish/config/dracula.fish
# source ~/.config/fish/config/bobTheFish.fish

#aliases
source ~/.config/fish/aliases.fish

set my_host (hostname)

if string match -q "*DESKTOP-251DD4K*" $my_host
    # wsl hostname is weird on boot
    set my_host wsl
end

# Load additional config based on hostname
set host_config ~/.config/fish/config.(echo $my_host).fish
test -r $host_config; and source $host_config

if test -d ~/.config/fish/customFuncs/(echo $my_host)
    for file in ~/.config/fish/customFuncs/(echo $my_host)/*
        source $file
    end
end

# if [ $PWD = (realpath ~) ]; randomAsciiImage; end
