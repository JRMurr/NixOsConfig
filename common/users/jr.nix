{ config, pkgs, lib, inputs, ... }:
let
  passwords = import inputs.passwords;
  inputGroup = lib.lists.optional config.myOptions.gestures.enable "input";
  groups = [ "wheel" "networkmanager" "audio" "docker" ] ++ inputGroup;
  userOpts = config.myOptions.users;
in {
  services.getty.autologinUser = lib.mkIf userOpts.jrAutoLogin "jr";
  home-manager.users.jr = (import ./jr { inherit inputs; });
  
  users.users.jr = lib.mkIf userOpts.makeJr {
    isNormalUser = true;

    extraGroups = groups;
    # https://nixos.org/manual/nixos/stable/options.html#opt-users.users._name_.hashedPassword
    hashedPassword = passwords.jr;

    shell = pkgs.fish;
    openssh.authorizedKeys.keyFiles = [ ./jr-keys.txt ];
  };

}
