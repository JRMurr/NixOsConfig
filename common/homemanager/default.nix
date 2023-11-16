{ ... }: {
  imports = [
    ./cargo.nix
    ./clipcat.nix
    ./direnv.nix
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
    ./starship.nix
    ./xsession.nix
  ];

  # adds home-manager-help tool
  manual.html.enable = true;

  nixpkgs.config = {
    # allowUnfree = true;
    manual.manpages.enable = true;
  };

  systemd.user.startServices = true;

  services.ssh-agent.enable = true;
}
