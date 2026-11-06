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
    # Keep pre-26.11 behavior: don't source home-manager session variables.
    loadSessionVariables = false;
    configFile = {
      source = ./files/config.base.nu;
    };
    envFile = {
      source = ./files/env.base.nu;
    };
  };
}
