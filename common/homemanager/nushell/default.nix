{ pkgs, ... }:
{
  home.packages = [ pkgs.carapace ];

  xdg.configFile.nushell = {
    recursive = true;
    source = ./files;
  };

  programs.direnv = {
    enableNushellIntegration = true;
  };

  programs.nushell = {
    enable = true;
    configFile = {
      source = ./files/config.base.nu;
    };
    envFile = {
      source = ./files/env.base.nu;
    };
  };
}
