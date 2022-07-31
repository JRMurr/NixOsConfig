{ ... }: {
  imports = [
    ./asciiArt.nix
    ./direnv.nix
    ./fish.nix
    ./git.nix
    ./helix.nix
    ./i3
    ./kitty.nix
    ./nushell.nix
    ./polybar
    ./rofi.nix
    ./xsession.nix
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
