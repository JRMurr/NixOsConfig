{ ... }: {
  imports = [
    ./direnv.nix
    ./asciiArt.nix
    ./git.nix
    ./fish.nix
    ./kitty.nix
    ./rofi.nix
    ./i3
    ./polybar
    ./xsession.nix
    ./nushell.nix
  ];

  # https://nix-community.github.io/home-manager/release-notes.html#sec-release-22.11-highlights
  home.stateVersion = "18.09";

  # adds home-manager-help tool
  manual.html.enable = true;

  nixpkgs.config = {
    allowUnfree = true;
    manual.manpages.enable = true;
  };

  systemd.user.startServices = true;
}
