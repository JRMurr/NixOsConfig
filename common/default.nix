{ pkgs, ... }: {
  imports = [
    # where all my custom options are defined (system wide)
    ./myOptions

    ./autorandr.nix
    ./gestures
    ./xserver.nix
    ./users
    ./audio.nix
    ./fonts.nix
    ./devlopment.nix
    ./programs.nix
    ./tailscale.nix
    ./ssh.nix
    ./kernel.nix
    ./network-shares.nix
  ];

  nixpkgs.config.allowUnfree = true;
  nix = {
    # enable flakes
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    settings = { auto-optimise-store = true; };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
}
