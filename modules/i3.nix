{ pkgs, lib, config, ... }:

let
  modifier = "Mod4"; # windows key
  xcfg = config.services.xserver;
  cfg = xcfg.desktopManager;
in {

  services.xserver.videoDrivers = [ "Nouveau" ];
  services.xserver = {
    enable = true;
    displayManager = { defaultSession = "xfce+i3"; };
    desktopManager = {
      xfce = {
        enable = true;
        noDesktop = true;
        enableXfwm = false;
      };
      wallpaper = {
        mode = "scale";
        combineScreens = true;
      };
    };
    windowManager.i3.enable = true;
  };

  # set to normal display setup, maybe use xrandr to get size?
  services.fractalart = {
    enable = true;
    width = 4137;
    height = 4080;
  };

  home-manager.users.jr = {

    xsession.windowManager.i3 = {
      enable = true;
      config = {
        modifier = "${modifier}";
        terminal = "kitty";
        keybindings = lib.mkOptionDefault {
          "${modifier}+Shift+e" = "exec xfce4-session-logout";
          "${modifier}+Shift+a" = "exec autorandr --load normal";
        };
        startup = [
          {
            command = "autorandr --load normal";
            notification = true;
          }
          {
            command = "feh --bg-${cfg.wallpaper.mode} ${
                lib.optionalString cfg.wallpaper.combineScreens "--no-xinerama"
              } $HOME/.background-image";
            notification = true;
          }
        ]; # i think i need notification to add the no--startup-id
        window = { titlebar = false; };
      };
      extraConfig = ''
        workspace 1 output DP-1
        workspace 2 output DP-3
        workspace 3 output DP-4
      '';
    };
  };
}
