{ pkgs, config, ... }:
with pkgs;
# TODO: move some of this to homemnager
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
  cliPrograms =
    [ git gh htop vim wget mkpasswd lsof unzip asciinema nixpkgs-review ];
  imageStuff = [ feh gimp ];
  messaging = [
    tdesktop # telegram
    discord
  ];
  desktopEnviorment = [ lxappearance arandr rofi-power-menu ];
  video = [ streamlink-twitch-gui-bin streamlink vlc ];
  audio = [ spotify spotify-tui ];
  miscGraphicalPrograms = [
    piper # add mouse hotkeys
    firefox
    kitty
    gparted
    baobab # space sniffer alternative
    pcmanfm
    vscode
    dbeaver
    deluge
    notion-app-enhanced
  ];

  allGraphicalPrograms = if gcfg.enable then
    miscGraphicalPrograms ++ video ++ desktopEnviorment ++ messaging
    ++ imageStuff ++ audio
  else
    [ ];
in {
  # these two are for vscode to stop yelling at me
  programs.dconf.enable = true;
  services.gnome.gnome-keyring.enable = true;

  environment.systemPackages = with pkgs; cliPrograms ++ allGraphicalPrograms;
}
