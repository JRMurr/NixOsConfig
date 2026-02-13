{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./graphics.nix
    ./brightness
    ../../common
    ./networking.nix
    ./programs.nix
    ./fingerprint-reader.nix
  ];

  time.timeZone = "America/New_York";
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  services.openssh.enable = true;

  virtualisation.docker.enable = true;
  programs.fish.enable = true;

  myOptions.laptop = true;
  myOptions.gestures.enable = true;
  myOptions.musicPrograms.enable = false;

  # fonts.optimizeForVeryHighDPI = true;
  fonts.fontconfig.antialias = true;
  fonts.fontconfig.subpixel = {
    rgba = "none";
    lcdfilter = "none";
  };

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # https://fwupd.org/lvfs/devices/work.frame.Laptop.TGL.BIOS.firmware
  # https://www.reddit.com/r/framework/comments/zfudd0/how_do_you_update_biosfirmware/
  services.fwupd = {
    enable = true;
    extraRemotes = [ "lvfs-testing" ];
    uefiCapsuleSettings = {
      DisableCapsuleUpdateOnDisk = true;
    };
  };
  # environment.etc."fwupd/uefi_capsule.conf" = {
  #   text = ''
  #     DisableCapsuleUpdateOnDisk=true
  #   '';
  # };

  programs.steam.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
}
