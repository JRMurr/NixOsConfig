{ inputs, ... }:
{
  imports = [
    ./cargo.nix
    ./direnv.nix
    ./dunst.nix
    ./fish
    ./git
    ./gitui.nix
    ./helix.nix
    ./i3
    ./kitty.nix
    ./nushell
    ./polybar
    ./programs.nix
    ./redshift.nix
    ./rofi.nix
    ./spicetify.nix
    ./starship.nix
    ./theme.nix
    ./xsession.nix
    # ./clipcat.nix #TODO: sad and barely helped :(
  ];

  programs.bash.enable = true;

  # adds home-manager-help tool
  manual.html.enable = true;

  nixpkgs.config = {
    # allowUnfree = true;
    manual.manpages.enable = true;
  };

  systemd.user.startServices = true;

  services.ssh-agent.enable = true;
}
