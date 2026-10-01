{ pkgs, ... }:
{
  # Steam Frame: aarch64 SteamOS, immutable root, so standalone home-manager
  # rather than a nixosConfiguration. Nix itself is installed out of band, see
  # ./README.md.
  imports = [ ../../common/homemanager/cli.nix ];

  home = {
    username = "steamos";
    homeDirectory = "/home/steamos";
    stateVersion = "26.11";
  };

  # No display server reachable from here yet; graphical modules stay out of
  # ../../common/homemanager/cli.nix entirely.
  myOptions = {
    graphics.enable = false;
    llm.skills = [ "hegel" ];
  };

  # Wraps the session in the host's locales, ld.so cache and XDG data dirs,
  # which NixOS would otherwise provide.
  targets.genericLinux.enable = true;

  fonts.fontconfig.enable = true;

  # Standalone installs have to carry the CLI themselves.
  programs.home-manager.enable = true;

  # SteamOS keeps /etc/passwd on the read-only root, so fish cannot be the login
  # shell without `steamos-readonly disable`. Hand off from bash instead.
  programs.bash.initExtra = ''
    [[ $- == *i* && -z $FISH_LAUNCHED ]] && FISH_LAUNCHED=1 exec ${pkgs.fish}/bin/fish
  '';

  # common/default.nix sets these system-wide on the NixOS hosts; a standalone
  # install has to write its own ~/.config/nix/nix.conf. Only honoured if this
  # user is a trusted-user in /etc/nix/nix.conf -- see ./README.md.
  nix = {
    package = pkgs.nix;

    settings = {
      # Builds are offloaded to thicc-server with a `--builders` flag rather than
      # a buildMachines entry for now, see ./README.md. This setting only matters
      # together with that flag: it lets the builder fetch build inputs itself
      # instead of having them uploaded from here.
      builders-use-substitutes = true;

      # cache.jrnet.win is deliberately absent: blocky maps jrnet.win to
      # thicc-server's tailscale address, which is unreachable from here. The
      # builder's own store covers the same paths.
      substituters = [
        "https://cache.nixos.org/?priority=20"
        "https://nix-community.cachix.org?priority=25"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      fallback = true;
      connect-timeout = 5;
    };
  };
}
