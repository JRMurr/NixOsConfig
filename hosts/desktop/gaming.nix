{ pkgs, config, ... }:
{

  programs.steam.enable = true;
  # Enable native nixos libs isntead of steam ones
  # nixpkgs.config.packageOverrides = pkgs: {
  #   steam = pkgs.steam.override {
  #     nativeOnly = true;
  #   };
  # };
}
