{ pkgs, config, ... }: {

  environment.systemPackages = with pkgs; [
    git
    htop
    firefox
    vim
    wget
    mkpasswd
    nixfmt
    kitty
    arandr
    pcmanfm
    bat
    killall
    piper # add mouse hotkeys
    spotify
    feh
    tdesktop # telegram
    pavucontrol
    # manix
    lxappearance
    exa
    zoxide
    streamlink-twitch-gui-bin
    streamlink
    vlc
    jq
    fzf
    lsof
    unzip

    gimp

    gparted
    rnix-lsp # nix lang server
  ];
  services.clipcat.enable = true;
  # home-manager.users.jr = { services.clipmenu.enable = true; };
}
