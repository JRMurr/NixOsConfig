{ config, lib, ... }:
let

  gcfg = config.myOptions.graphics;
  catCfg = config.catppuccin;

  catppuccin-sources = catCfg.sources;

  # https://catppuccin.com/palette
  # https://github.com/catppuccin/palette/blob/main/palette.json
  palette = (lib.importJSON "${catppuccin-sources.palette}/palette.json").${catCfg.flavor}.colors;

  hexColors = lib.attrsets.mapAttrs (_: color: color.hex) palette;

  aliasedColors = hexColors // {
    # https://github.com/catppuccin/catppuccin/blob/main/docs/style-guide.md
    background = hexColors.base;
    background-alt = hexColors.crust;
    foreground = hexColors.surface0;

    border-active = hexColors.lavender;
    border-inactive = hexColors.overlay0;
    cursor = hexColors.rosewater;




  };

in
{
  options = with lib; {
    myOptions.theme.colors = mkOption {
      type = types.attrsOf types.str;
      default = hexColors;
    };
  };

  config = lib.mkIf gcfg.enable
    {
      catppuccin.enable = true;

      myOptions.theme.colors = aliasedColors;
    };
}
