{ config, pkgs, lib, ... }: {
  imports = [ ./jr.nix ];

  users.mutableUsers = false;

  security.sudo = { enable = true; };
  home-manager.extraSpecialArgs = { systemConfig = config; };
  home-manager.users.jr = (import ./jr);
}
