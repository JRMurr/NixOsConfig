# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  # home-manager = builtins.fetchTarBall "https://github.com/rycee/home-manager/archive/master.tar.gz"
in {
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
    # (import "${home-manager}/nixos")    
    #<home-manager/nixos>
    (import "${
        builtins.fetchTarball
        "https://github.com/rycee/home-manager/archive/release-20.03.tar.gz"
      }/nixos")
    ./modules/users.nix
    ./modules/i3.nix
    ./modules/fonts.nix
    ./modules/kitty.nix
    ./modules/autorandr.nix
  ];

  # Use the GRUB 2 boot loader.
  # boot.loader.grub.enable = true;
  # boot.loader.grub.version = 2;
  boot.loader.systemd-boot.enable = true;
  # boot.loader.grub.useOSProber = true;
  # boot.loader.grub.efiSupport = true;
  # boot.loader.grub.efiInstallAsRemovable = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";
  # Define on which hard drive you want to install Grub.
  # boot.loader.grub.device = "/dev/disk/by-uuid/BC77-ADCA"; # or "nodev" for efi only

  networking.hostName = "nixos-john"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp42s0.useDHCP = true;
  networking.interfaces.wlp39s0.useDHCP = true;

  networking.firewall.allowedTCPPorts = [ 57621 ]; # for spotify

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
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable sound.
  sound.enable = true;
  hardware = {
    pulseaudio = { 
      enable = true;
      support32Bit = true;
    };
    opengl = { enable = true; };
  };

  services = {
    fstrim.enable = true;
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
  nixpkgs.config.allowUnfree = true;

  # nix = {
  #   package = pkgs.nixUnstable;
  #   extraOptions = ''
  #     experimental-features = nix-command
  #   '';
  # };

  environment = {
    systemPackages = with pkgs; [
      git
      htop
      firefox
      vim
      wget
      mkpasswd
      nixfmt
      vscode
      kitty
      arandr
      pcmanfm
      discord
      bat
      docker-compose
      python3
      rustup
      spotify
      feh
      tdesktop
    ];
  };
  virtualisation.docker.enable = true;

  home-manager.users.jr = {
    xdg.configFile = {
      fish = {
        recursive = true;
        source = ./dotFiles/fish;
      };
      gitconfig = {
        source = ./dotFiles/gitconfig;
        target = "../.gitconfig";
      };
      asciiArt = {
        recursive = true;
        source = ./dotFiles/asciiArt;
        target = "../asciiArt"; # puts it in ~/asciiArt
      };
    };
  };
}

