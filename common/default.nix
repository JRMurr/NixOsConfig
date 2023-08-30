{ pkgs, lib, ... }: {
  imports = [
    # where all my custom options are defined (system wide)
    ./myOptions

    ./audio.nix
    ./autorandr.nix
    ./devlopment.nix
    ./containers.nix
    ./essentials.nix
    ./fonts.nix
    ./gestures
    ./kernel.nix
    ./network-shares.nix
    ./programs.nix
    # ./plymouth.nix
    ./ssh.nix
    ./sudo.nix
    ./tailscale.nix
    ./users
    ./xserver.nix
  ];

  nixpkgs.config.allowUnfree = true;
  nix = {
    settings = {
      trusted-users = [ "root" "jr" ];
      auto-optimise-store = true;
      substituters = [
        "https://nix-community.cachix.org?priority=10"
        "https://jrmurr.cachix.org?priority=1"
        "https://cache.nixos.org/?priority=20"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "jrmurr.cachix.org-1:nE2/Ms3YbTPe8SrFOWsHfcNAuJtJtz9UCoohiSn6Elg="
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # https://github.com/NixOS/nixpkgs/issues/180175
  systemd.services.NetworkManager-wait-online.enable = false;
}
