{ pkgs, lib, config, ... }:
let gcfg = config.myOptions.graphics;
in {
  config = lib.mkIf gcfg.enable {
    services.xserver = {
      enable = true;
      dpi = 100;

      displayManager.lightdm = {
        enable = true;
        greeters.gtk.cursorTheme = {
          package = pkgs.gnome3.adwaita-icon-theme;
          size = 10;
        };
      };

      displayManager = {
        autoLogin.enable = true;
        autoLogin.user = "jr";
      };

      desktopManager.xterm.enable = false;
      desktopManager = {
        wallpaper = {
          mode = "scale";
          combineScreens = false;
        };
      };
      windowManager.i3.enable = true;
      displayManager.defaultSession = "none+i3";
    };
  };
}
