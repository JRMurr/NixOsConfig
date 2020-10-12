{ config, pkgs, lib, ... }: {

  users.mutableUsers = false;

  users.users.jr = {
    isNormalUser = true;

    extraGroups = [ "wheel" "networkmanager" ];
    hashedPassword = lib.fileContents /etc/nixos/secrets/jr-pass;

    shell = pkgs.fish;
  };

  services.mingetty.autologinUser = "jr";

  security.sudo = { enable = true; };
}
