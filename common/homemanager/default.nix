{ ... }:
{
  imports = [
    ./cargo.nix
    ./direnv.nix
    ./dunst.nix
    ./fish
    ./git
    ./gitui.nix
    ./helix.nix
    ./hyprland
    # ./i3
    ./kitty.nix
    ./nushell
    # ./polybar
    ./programs.nix
    ./redshift.nix
    ./rofi.nix
    ./slumber
    ./spicetify.nix
    ./starship.nix
    ./theme.nix
    ./xsession.nix
    ./zed.nix
    # ./clipcat.nix #TODO: sad and barely helped :(
  ];

  programs.bash.enable = true;

  # adds home-manager-help tool
  # manual.html.enable = true;

  # nixpkgs.config = {
  #   # allowUnfree = true;
  #   # manual.manpages.enable = true; # disabled as of 11-25-2024, probs just needs a fix upstream
  # };

  systemd.user.startServices = true;

  services.ssh-agent.enable = true;

  services.gnome-keyring.enable = true;

  xdg.userDirs.createDirectories = true;
  xdg.userDirs.enable = true;
}
