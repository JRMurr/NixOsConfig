{ pkgs, ... }:
let
  repo = "$HOME/NixOsConfig";

  # Same spec as the --builders flag in ./README.md: thicc-server by LAN address,
  # its host key pinned, aarch64 under qemu.
  builder = "ssh-ng://jr@192.168.50.42 aarch64-linux /home/steamos/.ssh/id_builder 8 1 big-parallel - c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUZwamJtYStiMkg1SUFBMWNjZ0NEditlVWRkS3Bhc0Y2NkdJYURsZ1dFZTEK";
in
{
  # Steam Frame: aarch64 SteamOS, immutable root, so standalone home-manager
  # rather than a nixosConfiguration. Nix itself is installed out of band, see
  # ./README.md.
  imports = [
    ../../common/homemanager/cli.nix
    ../../common/homemanager/kitty.nix
  ];

  home = {
    username = "steamos";
    homeDirectory = "/home/steamos";
    stateVersion = "26.11";
  };

  myOptions = {
    graphics.enable = true;
    llm.skills = [ "hegel" ];
    # Nothing caches the flake-input builds for aarch64, and compiling nixd under
    # qemu takes hours. These come from cache.nixos.org instead.
    nixTooling = "nixpkgs";

    # `nh os switch` is meaningless here. -b backup because a SteamOS update puts
    # its own dotfiles back in the way. --max-jobs 0 is what forces the offload:
    # this host is aarch64 itself, so otherwise nix just builds locally.
    rebuildCmd = "home-manager switch --flake ${repo}#steamos@frame -b backup --max-jobs 0 --builders '${builder}'";
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
