{
  pkgs,
  osConfig,
  lib,
  ...
}:
let
  slumberPkg = pkgs.slumber;
  themeCfg = osConfig.myOptions.theme;
  baseColors = themeCfg.colors;

  slumberConf = {
    theme = {
      primary_text_color = baseColors.text;
      primary_color = baseColors.background-alt; # baseColors.accent;
      secondary_color = baseColors.foreground;
      # secondary_color =
    };
  };

in
{
  home.packages = [
    slumberPkg
  ];
  # https://slumber.lucaspickering.me/api/configuration/index.html

  xdg.configFile."slumber/config.yml" = {
    text = builtins.toJSON slumberConf;
  };
}
