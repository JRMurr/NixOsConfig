{ config, lib, ... }:
with lib;
let
  # TODO: add assertion to make sure workspace is set and name is uniuqe 
  graphicsCfg = config.myOptions.graphics;
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

      position = mkOption {
        type = types.str;
        description = "Output position";
        default = "";
        example = "5760x0";
      };

      resolution = mkOption { # mode in autorandr
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
        type = types.nullOr (types.enum [ "normal" "left" "right" "inverted" ]);
        description = "Output rotate configuration.";
        default = null;
        example = "left";
      };

      crtc = mkOption {
        type = types.nullOr types.ints.unsigned;
        description = lib.mdDoc
          "Output video display controller. Use `xrandr --verbose` to get";
        default = null;
        example = 0;
      };
    };
  };
in {
  options = {
    myOptions.graphics.monitors = mkOption {
      type = types.listOf monitorConfig;
      default = [ ];
    };
  };
}
