{ config, pkgs, lib, inputs, ... }:
let passwords = import inputs.passwords;
in {

  users.mutableUsers = false;

  users.users.jr = {
    isNormalUser = true;

    extraGroups = [ "wheel" "networkmanager" "audio" "docker" ];
    # https://nixos.org/manual/nixos/stable/options.html#opt-users.users._name_.hashedPassword
    hashedPassword = passwords.jr;

    shell = pkgs.fish;
  };

  services.getty.autologinUser = "jr";

  security.sudo = { enable = true; };

  home-manager.users.jr = { xdg.enable = true; };
}
