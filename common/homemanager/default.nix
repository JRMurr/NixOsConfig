{ ... }: {
  imports = [
    ./asciiArt.nix
    ./clipcat.nix
    ./direnv.nix
    ./fish
    ./git.nix
    ./gitui.nix
    ./helix.nix
    ./i3
    ./kitty.nix
    ./nushell.nix
    ./programs.nix
    ./polybar
    ./redshift.nix
    ./rofi.nix
    ./starship.nix
    ./xsession.nix
  ];

  # adds home-manager-help tool
  manual.html.enable = true;

  nixpkgs.config = {
    allowUnfree = true;
    manual.manpages.enable = true;
  };

  systemd.user.startServices = true;
}
