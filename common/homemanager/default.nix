{ ... }:
{
  imports = [
    ./cargo.nix
    ./claude
    ./direnv.nix
    ./fish
    ./git
    ./gitui.nix
    ./helix.nix
    ./hyprland
    ./kitty.nix
    ./nushell
    # ./noctalia.nix
    ./programs.nix
    ./redshift.nix
    ./rofi.nix
    ./slumber
    ./spicetify.nix
    ./starship.nix
    ./theme.nix
    ./xsession.nix
    ./zed.nix
  ];

  programs.bash.enable = true;

  systemd.user.startServices = true;

  services.ssh-agent.enable = true;

  services.gnome-keyring.enable = true;

  xdg.userDirs.createDirectories = true;
  xdg.userDirs.enable = true;
}
