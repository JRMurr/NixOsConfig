{ config, pkgs, lib, ... }: {
  security.sudo = {
    enable = true;

    extraRules = [{
      users = [ "jr" ];
      commands = [
        {
          command = "${pkgs.nixos-rebuild}/bin/nixos-rebuild";
          options = [ "NOPASSWD" ];
        }
        {
          # sudoers sad on symlink?
          command = "/run/current-system/sw/bin/nixos-rebuild";
          options = [ "NOPASSWD" ];
        }
      ];

    }];
  };
}
