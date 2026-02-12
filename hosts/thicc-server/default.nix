{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../common

    #./attic.nix
    #./blocky
    #./caddy
    #./dashy.nix
    #./factorio.nix
    #./freshrss.nix
    #./it-tools.nix
    #./monitoring
    #./linkding.nix
    #./mopidy.nix
    #./postgres.nix
  ];

  time.timeZone = "America/New_York";
  networking.hostName = "thicc-server";

  myOptions = {
    graphics.enable = false;
    networkShares.enable = true;
    containers.enable = true;
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };
  virtualisation.docker.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?
}
