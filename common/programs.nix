{ pkgs, config, ... }:
with pkgs;
# move some of these like bat jq exa etc to home.packages
let
  gcfg = config.myOptions.graphics;

  cliPrograms =
    [ git htop vim wget mkpasswd bat killall exa zoxide jq fzf lsof unzip ];
  imageStuff = [ feh gimp ];
  messaging = [
    tdesktop # telegram
    discord
  ];
  desktopEnviorment = [ lxappearance arandr ];
  video = [ streamlink-twitch-gui-bin streamlink vlc ];
  miscGraphicalPrograms = [
    spotify
    piper # add mouse hotkeys
    firefox
    kitty
    gparted
    baobab # space sniffer alternative
    pcmanfm
    vscode
    dbeaver
  ];

  allGraphicalPrograms = if gcfg.enable then
    miscGraphicalPrograms ++ video ++ desktopEnviorment ++ messaging
    ++ imageStuff
  else
    [ ];
in {
  environment.systemPackages = with pkgs; cliPrograms ++ allGraphicalPrograms;
}
