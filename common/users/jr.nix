{ config, pkgs, lib, inputs, ... }:
let
  sysVersion = config.system.nixos.release;
  onUnStable = lib.versionAtLeast sysVersion "23.11";

  inputGroup = lib.lists.optional config.myOptions.gestures.enable "input";
  groups = [ "wheel" "networkmanager" "audio" "docker" ] ++ inputGroup;
  userOpts = config.myOptions.users;
in {
  age.secrets.jr-pass.file = "${inputs.secrets}/secrets/jr-pass.age";
  services.getty.autologinUser = lib.mkIf userOpts.jrAutoLogin "jr";
  home-manager.users.jr = (import ./jr { inherit inputs; });

  users.users.jr = lib.mkIf userOpts.makeJr {
    isNormalUser = true;

    extraGroups = groups;
    passwordFile = lib.mkIf (!onUnStable) config.age.secrets.jr-pass.path;
    hashedPasswordFile = lib.mkIf onUnStable config.age.secrets.jr-pass.path;

    shell = pkgs.fish;
    openssh.authorizedKeys.keyFiles = [ ./jr-keys.txt ];
  };

}
