{ pkgs, lib, ... }:
let
  caches = import ./nix-caches.nix;
in
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
  # Only terminals we ssh from. enableAllTerminfo builds every terminal in
  # nixpkgs, and some obscure one breaks on most updates.
  environment.systemPackages = map (p: p.terminfo) [
    pkgs.kitty
    pkgs.ghostty
  ];
  # nixpkgs.config.allowUnfree = true;
  nix = {
    settings = {
      trusted-users = [
        "root"
        "jr"
      ];
      auto-optimise-store = true;
      # harmonia on thicc-server, serves at the root (attic used a /main path)
      substituters = lib.mkBefore ([ caches.harmonia.tailnet ] ++ caches.public);
      trusted-public-keys = caches.keys;
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
