{ pkgs, config, ... }:
let
  repo = "$HOME/NixOsConfig";
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
    # its own dotfiles back in the way. Builds run locally: thicc-server's nightly
    # job fills cache-lan, and offloading everything through qemu was slower than
    # building the leftovers natively. ./README.md has the --builders flag for
    # one-off offloads.
    rebuildCmd = "home-manager switch --flake ${repo}#steamos@frame -b backup";
  };

  # Wraps the session in the host's locales, ld.so cache and XDG data dirs,
  # which NixOS would otherwise provide.
  targets.genericLinux.enable = true;

  # Plasma takes its environment from the systemd user manager, not a login shell,
  # so without this its PATH lacks the profile and launcher entries like kitty's
  # `Exec=kitty` fail.
  systemd.user.sessionVariables.PATH = "${config.home.profileDirectory}/bin:/nix/var/nix/profiles/default/bin\${PATH:+:$PATH}";

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

      # cache.jrnet.win resolves to thicc-server's tailscale address, unreachable
      # from here; cache-lan is the same harmonia at its LAN address. Its nightly
      # job builds this generation too.
      substituters = [
        "https://cache-lan.jrnet.win?priority=1"
        "https://cache.nixos.org/?priority=20"
        "https://nix-community.cachix.org?priority=25"
      ];
      # Replaces nix's default rather than extending it, so cache.nixos.org's key
      # has to be listed too; without it every substitute from there is rejected.
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "cache.jrnet.win-1:FVkbrXPDdxta7+tgKfTAZJCoT0ptqfl3TUSE1M9TrBU="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      fallback = true;
      connect-timeout = 5;
    };
  };
}
