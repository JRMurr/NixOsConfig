{ config, pkgs, lib, ... }: {
  security.sudo = {
    enable = true;

    extraRules = [{
      users = [ "jr" ];
      commands = [{
        command = "${pkgs.nixos-rebuild}/bin/nixos-rebuild";
        options = [ "NOPASSWD" ];
      }];

    }];
  };
}
