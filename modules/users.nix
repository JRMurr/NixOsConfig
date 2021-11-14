{ config, pkgs, lib, ... }: {

  users.mutableUsers = false;

  users.users.jr = {
    isNormalUser = true;

    extraGroups = [ "wheel" "networkmanager" "audio" "docker" ];
    hashedPassword = lib.fileContents /etc/nixos/secrets/jr-pass;

    shell = pkgs.fish;
  };

  services.getty.autologinUser = "jr";

  security.sudo = { enable = true; };

  home-manager.users.jr = { xdg.enable = true; };
}
