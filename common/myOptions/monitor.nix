{ config, lib, ... }:
with lib;
let
  # TODO: add assertion to make sure workspace is set and name is uniuqe

  # TODO: can extend from offical options?

  # mostly stolen from https://github.com/nix-community/home-manager/blob/778af87a981eb2bfa3566dff8c3fb510856329ef/modules/programs/autorandr.nix#L50
  # main changes are monitor option has a name param and fingerprint on it
  # also added workspace number for i3

  monitorConfig = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "The output name";
        example = "DP-0";
        default = "";
      };

      description = mkOption {
        type = types.str;
        description = ''
          The output's EDID description (make + model + serial), as reported by
          `hyprctl monitors`. Connector names are not stable for docked or
          hot-plugged displays — the same panel re-enumerates as DP-3, DP-5,
          DP-6, ... depending on the port and the boot — so compositors that can
          match on the description (Hyprland's `desc:` prefix) should prefer it
          over `name`. Leave empty to match by connector name only.
        '';
        example = "Dell Inc. AW3225QF 9Q22YZ3";
        default = "";
      };

      fingerprint = mkOption {
        type = types.str;
        description = ''
          The EDID value for this monitor
          Use <code>autorandr --fingerprint</code> to get current setup values.
        '';
        example = "DP-0";
        default = "";
      };

      workspace = mkOption {
        type = types.nullOr types.ints.unsigned;
        description = "The default i3 workspace for this monitor";
        default = null;
        example = 0;
      };

      enable = mkOption {
        type = types.bool;
        description = "Whether to enable the output.";
        default = true;
      };

      primary = mkOption {
        type = types.bool;
        description = "Whether output should be marked as primary";
        default = false;
      };

      mainBar = mkOption {
        type = types.bool;
        description = ''
          Whether this output should get the full status bar (as opposed to the
          reduced bar). Independent of `primary`: e.g. a docked external monitor
          that is not the X11 primary can still host the main bar.
        '';
        default = false;
      };

      position = mkOption {
        type = types.str;
        description = "Output position";
        default = "";
        example = "5760x0";
      };

      resolution = mkOption {
        # mode in autorandr
        type = types.str;
        description = "Output resolution.";
        default = "";
        example = "3840x2160";
      };

      rate = mkOption {
        type = types.str;
        description = "Output framerate.";
        default = "";
        example = "60.00";
      };

      dpi = mkOption {
        type = types.nullOr types.ints.positive;
        description = "Output DPI configuration.";
        default = null;
        example = 96;
      };

      rotate = mkOption {
        type = types.nullOr (
          types.enum [
            "normal"
            "left"
            "right"
            "inverted"
          ]
        );
        description = "Output rotate configuration.";
        default = null;
        example = "left";
      };

      crtc = mkOption {
        type = types.nullOr types.ints.unsigned;
        description = "Output video display controller. Use `xrandr --verbose` to get";
        default = null;
        example = 0;
      };

      scale = mkOption {
        type = types.nullOr types.str;
        description = "output's scale, 1 is non scaled";
        default = "1";
        example = "1.5";
      };

      wallpaper = mkOption {
        type = types.nullOr types.str;
        description = "Monitor's default wallpaper";
        default = null;
        example = "$HOME/Wallpapers/pic.png";
      };
    };
  };
in
{
  options = {
    myOptions.graphics.monitors = mkOption {
      type = types.listOf monitorConfig;
      default = [ ];
    };
  };
}
