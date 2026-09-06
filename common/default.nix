{ pkgs, lib, ... }:
{
  imports = [
    # where all my custom options are defined (system wide)
    ./myOptions

    ./audio.nix
    # ./autorandr.nix
    ./containers.nix
    ./devlopment.nix
    ./essentials.nix
    ./fonts.nix
    ./gestures
    ./kernel.nix
    ./lock.nix
    ./network-shares.nix
    ./portals.nix
    ./programs.nix
    ./ssh.nix
    ./sudo.nix
    ./tailscale.nix
    ./theme.nix
    ./thunar.nix
    ./users
    ./xserver.nix
    # ./plymouth.nix
  ];
  security.pam.services.swaylock = { };
  environment.enableAllTerminfo = true;
  # nixpkgs.config.allowUnfree = true;
  nix = {
    settings = {
      trusted-users = [
        "root"
        "jr"
      ];
      auto-optimise-store = true;
      substituters = lib.mkBefore [
        # harmonia on thicc-server, serves at the root (attic used a /main path)
        "https://cache.jrnet.win?priority=1"
        "https://nix-community.cachix.org?priority=25"
        # "https://jrmurr.cachix.org?priority=2"
        "https://cache.nixos.org/?priority=20"
        "https://cache.numtide.com"
      ];
      trusted-public-keys = [
        "cache.jrnet.win-1:FVkbrXPDdxta7+tgKfTAZJCoT0ptqfl3TUSE1M9TrBU="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        # "jrmurr.cachix.org-1:nE2/Ms3YbTPe8SrFOWsHfcNAuJtJtz9UCoohiSn6Elg="
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      ];
      # Off the tailnet cache.jrnet.win is unreachable; without these a rebuild
      # stalls 15s per path before giving up on it.
      fallback = true;
      connect-timeout = 5;
    };
    # gc = {
    #   automatic = true;
    #   dates = "weekly";
    #   options = "--delete-older-than 30d";
    # };
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 30d --keep 10";
    flake = "/etc/nixos";
  };

  environment.pathsToLink = [
    "/share/fish"
    "/share/xdg-desktop-portal"
    "/share/applications"
  ];

  # https://github.com/NixOS/nixpkgs/issues/180175
  systemd.services.NetworkManager-wait-online.enable = false;
}
