{ pkgs, lib, ... }: {
  imports = [
    # where all my custom options are defined (system wide)
    ./myOptions

    ./audio.nix
    ./autorandr.nix
    ./containers.nix
    ./devlopment.nix
    ./essentials.nix
    ./fonts.nix
    ./gestures
    ./kernel.nix
    ./network-shares.nix
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

  # nixpkgs.config.allowUnfree = true;
  nix = {
    settings = {
      trusted-users = [ "root" "jr" ];
      auto-optimise-store = true;
      substituters = lib.mkBefore [
        # "https://cache.jrnet.win/main?priority=1" # server died :cry:
        "https://nix-community.cachix.org?priority=25"
        "https://jrmurr.cachix.org?priority=2"
        "https://cache.nixos.org/?priority=20"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "jrmurr.cachix.org-1:nE2/Ms3YbTPe8SrFOWsHfcNAuJtJtz9UCoohiSn6Elg="
        "main:doBjjo8BjzYQ+YJG6YNQ/7RqgVsgYWL+1Pv86p0/7fk="
        "main:I3Ud+URwX+SiyP9pBRP3gV5BCGVjQ1/QDapsUHFt9JQ="
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  environment.pathsToLink = [ "/share/fish" ];

  # https://github.com/NixOS/nixpkgs/issues/180175
  systemd.services.NetworkManager-wait-online.enable = false;
}
