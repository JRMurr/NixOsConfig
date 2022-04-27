{ pkgs, config, ... }:
with pkgs;
# move some of these like bat jq exa etc to home.packages
let
  cliPrograms =
    [ git htop vim wget mkpasswd bat killall exa zoxide jq fzf lsof unzip ];
  imageStuff = [ feh gimp ];
  messaging = [
    tdesktop # telegram
    discord
  ];
  desktopEnviorment = [ lxappearance arandr ];
  video = [ streamlink-twitch-gui-bin streamlink vlc ];
  devStuff = [
    nixfmt
    rnix-lsp # nix lang server
  ];
  graphicalPrograms = [
    spotify
    piper # add mouse hotkeys
    firefox
    kitty
    gparted
    baobab # space sniffer alternative
    pcmanfm
  ];
in {
  environment.systemPackages = with pkgs;
    cliPrograms ++ imageStuff ++ messaging ++ desktopEnviorment ++ video
    ++ devStuff ++ graphicalPrograms;
  # services.clipcat.enable = true;
  # home-manager.users.jr = { services.clipmenu.enable = true; };
}
