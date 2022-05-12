{ pkgs, config, ... }:
with pkgs;

let
  gcfg = config.myOptions.graphics;

  cliPrograms = [ git gh htop vim wget mkpasswd lsof unzip ];
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
