{ pkgs, ... }: {
  imports = [
    ./users

    ./fonts.nix
    ./desktop
    ./devlopment.nix
    ./gaming.nix
    ./programs.nix
  ];

  nixpkgs.config.allowUnfree = true;
  nix = {
    # enable flakes
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    autoOptimiseStore = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
}
