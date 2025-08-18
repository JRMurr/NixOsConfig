{
  pkgs,
  lib,
  config,
  ...
}:
let
  gcfg = config.myOptions.graphics;

in
{
  options.myOptions = {
    graphics.wallPaper = {
      # https://github.com/NixOS/nixpkgs/blob/dfd82985c273aac6eced03625f454b334daae2e8/nixos/modules/services/x11/desktop-managers/default.nix#L31
      mode = lib.mkOption {
        type = lib.types.enum [
          "center"
          "fill"
          "max"
          "scale"
          "tile"
        ];
        default = "scale";
        example = "fill";
        description = ''
          The file <filename>~/.background-image</filename> is used as a background image.
          This option specifies the placement of this image onto your desktop.
          Possible values:
          <literal>center</literal>: Center the image on the background. If it is too small, it will be surrounded by a black border.
          <literal>fill</literal>: Like <literal>scale</literal>, but preserves aspect ratio by zooming the image until it fits. Either a horizontal or a vertical part of the image will be cut off.
          <literal>max</literal>: Like <literal>fill</literal>, but scale the image to the maximum size that fits the screen with black borders on one side.
          <literal>scale</literal>: Fit the file into the background without repeating it, cutting off stuff or using borders. But the aspect ratio is not preserved either.
          <literal>tile</literal>: Tile (repeat) the image in case it is too small for the screen.
        '';
      };
    };
  };
  config = lib.mkIf gcfg.enable {

    hardware.nvidia.open = false;

    programs.hyprland.enable = true; # enable Hyprland
    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    # TODO-REFACTOR: these were under xserver pre 24.05
    services = {
      libinput = {
        enable = true;
        # disabling touchpad acceleration
        touchpad = {
          accelProfile = "flat";
        };
      };

      displayManager = {
        # defaultSession = "none+i3";
        autoLogin.enable = true;
        autoLogin.user = "jr";
      };
    };

    services.xserver = {
      enable = true;

      # write config to /etc/X11/xorg.conf for easy debugging
      exportConfiguration = true;

      displayManager = {
        lightdm = {
          enable = true;
          greeters.gtk.cursorTheme = {
            package = pkgs.adwaita-icon-theme;
            size = 10;
          };
          # # https://github.com/NixOS/nixos-artwork/tree/master/wallpapers
          # background =
          #   pkgs.nixos-artwork.wallpapers.simple-dark-gray.gnomeFilePath;
        };
      };

      desktopManager.xterm.enable = false;
      desktopManager = {
        wallpaper = {
          mode = gcfg.wallPaper.mode;
          combineScreens = false;
        };
      };
      # windowManager.i3.enable = true;

      # enable monitors here before arandr to try to get them to start ealier
      # this appears to do nothing but i tried
      xrandrHeads =
        let
          monitorConfigMap = config: {
            output = config.name;
            primary = config.primary;
          };
        in
        builtins.map monitorConfigMap gcfg.monitors;
    };

    services.picom = {
      enable = true;
    };

  };
}
