{ config, pkgs, lib, ... }: {
  imports = [ ./jr.nix ];

  users.mutableUsers = false;

  security.sudo = { enable = true; };

}
