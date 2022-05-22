{ pkgs, lib, config, ... }:
let gcfg = config.myOptions.graphics;

in {
  config = lib.mkIf gcfg.enable {
    services.xserver = {
      enable = true;

      # write config to /etc/X11/xorg.conf for easy debugging
      exportConfiguration = true;

      displayManager = {
        autoLogin.enable = true;
        autoLogin.user = "jr";
        lightdm = {
          enable = true;
          greeters.gtk.cursorTheme = {
            package = pkgs.gnome3.adwaita-icon-theme;
            size = 10;
          };
          # https://github.com/NixOS/nixos-artwork/tree/master/wallpapers
          background =
            pkgs.nixos-artwork.wallpapers.simple-dark-gray.gnomeFilePath;
        };
      };

      desktopManager.xterm.enable = false;
      desktopManager = {
        wallpaper = {
          mode = "fill";
          combineScreens = false;
        };
      };
      windowManager.i3.enable = true;
      displayManager.defaultSession = "none+i3";

      # enable monitors here before arandr to try to get them to start ealier
      # this appears to do nothing but i tried
      xrandrHeads = let
        monitorConfigMap = config: {
          output = config.name;
          primary = config.primary;
        };
      in builtins.map monitorConfigMap gcfg.monitors;
    };
  };
}
