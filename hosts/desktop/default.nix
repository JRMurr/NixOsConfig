# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./graphics.nix
    ../../common
    ./networking.nix
    ./gaming.nix
    ./udisk.nix
    ./programs.nix
  ];

  boot.loader = {
    systemd-boot = {
      enable = true;
      consoleMode = "auto";
    };
    efi.canTouchEfiVariables = true;
  };

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  #   pinentryFlavor = "gnome3";
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  hardware = {
    opengl = {
      enable = true;
      setLdLibraryPath = true;
    };
  };

  services = {
    fstrim.enable = true;
    blueman.enable = true;
    ratbagd.enable = true; # for mouse
    #  fwupd.enable = true;
    # acpid.enable = true;
    #tlp.enable = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?

  # auto upgrade with nixos-rebuild switch --upgrade
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = true;
  system.autoUpgrade.flake = "github:kloenk/JRMurr/NixOsConfig";

  # nix = {
  #   package = pkgs.nixUnstable;
  #   extraOptions = ''
  #     experimental-features = nix-command
  #   '';
  # };

  # environment = {
  #   systemPackages = with pkgs; [

  #   ];
  # };
  virtualisation.docker.enable = true;
}

