{ ... }: {
  imports = [
    ./autorandr.nix
    ./direnv.nix
    ./asciiArt.nix
    ./git.nix
    ./fish.nix
    ./kitty.nix
    ./rofi.nix
    ./i3
    ./polybar
  ];

  # adds home-manager-help tool
  manual.html.enable = true;

  nixpkgs.config = {
    allowUnfree = true;
    manual.manpages.enable = true;
  };

  systemd.user.startServices = true;
}
