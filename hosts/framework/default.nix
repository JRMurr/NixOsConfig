{ config, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./graphics.nix
    ../../common
    ./networking.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  services.openssh.enable = true;
  system.stateVersion = "21.11";
}
