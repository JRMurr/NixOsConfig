{ pkgs, ... }:
{
  home.packages = [ pkgs.carapace ];

  xdg.configFile.nushell = {
    recursive = true;
    source = ./files;
  };

  programs.direnv = {
    enableNushellIntegration = false; # 23.05 setting is sad
  };

  programs.nushell = {
    enable = true;
    configFile = {
      source = ./files/config.base.nu;
    };
    envFile = {
      source = ./files/env.base.nu;
    };
    # shellAliases = { ll = "ls -l"; };
    # TODO: can replace below when off 23.05 and use direnv option disabled above
    extraConfig = ''
      $env.config = ($env | default {} config).config
      $env.config = ($env.config | default {} hooks)
      $env.config = ($env.config | update hooks ($env.config.hooks | default [] pre_prompt))
      $env.config = ($env.config | update hooks.pre_prompt ($env.config.hooks.pre_prompt | append {
        code: "
          let direnv = (${pkgs.direnv}/bin/direnv export json | from json)
          let direnv = if ($direnv | length) == 1 { $direnv } else { {} }
          $direnv | load-env 
          "
      }))
    '';
  };
}
