{ config, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../../common

    ./attic.nix
    ./blocky
    ./caddy
    ./dashy.nix
    ./freshrss.nix
    ./it-tools.nix
    ./monitoring
    ./mopidy.nix
    ./postgres.nix
  ];

  time.timeZone = "America/New_York";
  networking.hostName = "thicc-server";
  myOptions.graphics.enable = false;
  myOptions.networkShares.enable = true;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  services.openssh.enable = true;
  # services.openssh.permitRootLogin = "yes";
  services.openssh.settings.PermitRootLogin = "yes";
  virtualisation.docker.enable = true;
  programs.fish.enable = true;

  myOptions.containers.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
}
