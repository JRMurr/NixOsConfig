{ pkgs, ... }: {
  imports = [
    # where all my custom options are defined (system wide)
    ./myOptions

    ./users
    ./audio.nix
    ./fonts.nix
    ./devlopment.nix
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
