{ config, pkgs, lib, inputs, ... }:
let
  passwords = import inputs.passwords;
  tmp = lib.lists.optional config.myOptions.gestures.enable "input";
  groups = [ "wheel" "networkmanager" "audio" "docker" ] ++ tmp;
in {
  users.users.jr = {
    isNormalUser = true;

    extraGroups = groups;
    # https://nixos.org/manual/nixos/stable/options.html#opt-users.users._name_.hashedPassword
    hashedPassword = passwords.jr;

    shell = pkgs.fish;
  };

  services.getty.autologinUser = "jr";
  home-manager.users.jr = (import ./jr);
}
