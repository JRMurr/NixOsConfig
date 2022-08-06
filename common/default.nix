{ pkgs, ... }: {
  imports = [
    # where all my custom options are defined (system wide)
    ./myOptions

    ./audio.nix
    ./autorandr.nix
    ./devlopment.nix
    ./essentials.nix
    ./fonts.nix
    ./gestures
    ./kernel.nix
    ./network-shares.nix
    ./programs.nix
    ./ssh.nix
    ./tailscale.nix
    ./users
    ./xserver.nix
  ];

  nixpkgs.config.allowUnfree = true;
  nix = {
    settings = {
      trusted-users = [ "root" "jr" ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
}
