{ ... }: {
  imports = [
    ./asciiArt.nix
    ./direnv.nix
    ./fish
    ./git.nix
    ./helix.nix
    ./i3
    ./kitty.nix
    ./nushell.nix
    ./polybar
    ./redshift.nix
    ./rofi.nix
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
