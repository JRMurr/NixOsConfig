{ pkgs, config, ... }:
with pkgs;

let
  gcfg = config.myOptions.graphics;
  rofi-power-menu = stdenv.mkDerivation rec {
    pname = "rofi-power-menu";
    version = "3.0.2";
    src = fetchFromGitHub {
      owner = "jluttine";
      repo = pname;
      rev = version;
      sha256 = "0yrnjihjs8cl331rmipr3xih503yh0ir60mwsxwh976j2pn3qiq6";
    };
    buildPhase = "";
    installPhase = ''
      install -Dm755 rofi-power-menu $out/bin/rofi-power-menu
    '';
  };
  cliPrograms = [ git gh htop vim wget mkpasswd lsof unzip ];
  imageStuff = [ feh gimp ];
  messaging = [
    tdesktop # telegram
    discord
  ];
  desktopEnviorment = [ lxappearance arandr rofi-power-menu ];
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
    deluge
  ];

  allGraphicalPrograms = if gcfg.enable then
    miscGraphicalPrograms ++ video ++ desktopEnviorment ++ messaging
    ++ imageStuff
  else
    [ ];
in {
  environment.systemPackages = with pkgs; cliPrograms ++ allGraphicalPrograms;
}
