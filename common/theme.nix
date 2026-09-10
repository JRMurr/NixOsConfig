{ config, lib, ... }:
let

  gcfg = config.myOptions.graphics;
  catCfg = config.catppuccin;

  catppuccin-sources = catCfg.sources;

  # https://catppuccin.com/palette
  # https://github.com/catppuccin/palette/blob/main/palette.json
  palette = (lib.importJSON (catppuccin-sources.palette + "/palette.json")).${catCfg.flavor}.colors;

  hexColors = lib.attrsets.mapAttrs (_: color: color.hex) palette;

  aliasedColors = hexColors // {
    # https://github.com/catppuccin/catppuccin/blob/main/docs/style-guide.md
    background = hexColors.base;
    background-alt = hexColors.crust;
    foreground = hexColors.surface0;

    border-active = hexColors.lavender;
    border-inactive = hexColors.overlay0;
    cursor = hexColors.rosewater;

    accent = hexColors.${catCfg.accent};
  };

in
{
  options = with lib; {
    myOptions.theme.colors = mkOption {
      type = types.attrsOf types.str;
      default = hexColors;
    };
  };

  config = {
    # `enable` is only a global toggle now; `autoEnable` enrolls the ports. Both
    # must be defined unconditionally: catppuccin warns whenever `autoEnable` is
    # left at its default priority, and gating these behind `gcfg.enable` meant
    # headless hosts never defined it. Ports stay dormant on those hosts because
    # they key off `autoEnable`, not `enable`.
    catppuccin.enable = true;
    catppuccin.autoEnable = gcfg.enable;

    myOptions.theme.colors = lib.mkIf gcfg.enable aliasedColors;
  };
}
