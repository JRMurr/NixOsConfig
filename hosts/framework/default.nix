{ config, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ../../common ./networking ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "21.11";
}
