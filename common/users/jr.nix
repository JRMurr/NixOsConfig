{ config, pkgs, lib, inputs, ... }:
let passwords = import inputs.passwords;

in {
  users.users.jr = {
    isNormalUser = true;

    extraGroups = [ "wheel" "networkmanager" "audio" "docker" ]
      ++ lib.lists.optional config.myOptions.gestures.enable "login";
    # https://nixos.org/manual/nixos/stable/options.html#opt-users.users._name_.hashedPassword
    hashedPassword = passwords.jr;

    shell = pkgs.fish;
  };

  services.getty.autologinUser = "jr";
  home-manager.users.jr = (import ./jr);
}
