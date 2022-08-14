{ config, pkgs, lib, inputs, ... }:
let
  passwords = import inputs.passwords;
  inputGroup = lib.lists.optional config.myOptions.gestures.enable "input";
  groups = [ "wheel" "networkmanager" "audio" "docker" ] ++ inputGroup;

in {
  services.getty.autologinUser = "jr";
  home-manager.users.jr = (import ./jr);
  users.users.jr = {
    isNormalUser = true;

    extraGroups = groups;
    # https://nixos.org/manual/nixos/stable/options.html#opt-users.users._name_.hashedPassword
    hashedPassword = passwords.jr;

    shell = pkgs.fish;
    openssh.authorizedKeys.keyFiles = [ ./jr-keys.txt ];
  };

}
