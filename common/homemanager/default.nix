{ ... }:
{
  imports = [
    # CLI-only modules, shared with the standalone hosts/frame config.
    ./cli.nix
    ./fromOs.nix

    ./ghostty.nix
    # ./helix.nix
    ./hyprland
    ./kitty.nix
    # ./noctalia.nix
    # ./redshift.nix
    ./rofi.nix
    #./slumber
    ./spicetify.nix
    ./xsession.nix
    ./zed.nix
  ];

  services.gnome-keyring.enable = true;
}
