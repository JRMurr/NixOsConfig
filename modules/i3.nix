{ pkgs, lib, config, ... }:

let
  modifier = "Mod4"; # windows key
  xcfg = config.services.xserver;
  cfg = xcfg.desktopManager;
in {

  programs.nm-applet.enable = true;
  services.xserver.videoDrivers = [ "Nouveau" ];
  services.xserver = {
    enable = true;
    # screenSection = ''
    #   Option "metamodes" "nvidia-auto-select +0+0 { ForceCompositionPipeline = On }"
    # '';
    displayManager.lightdm.enable = true;
    displayManager = {
      autoLogin.enable = true;
      autoLogin.user = "jr";
    };
    #     displayManager.sessionCommands = ''${pkgs.xlibs.xrandr}/bin/xrandr --fb 4137x4080 --output DP-3 --gamma 1.0:1.0:1.0 --mode 3840x2160 --pos 297x0 --rate 60.00 --reflect normal --rotate normal --output DP-4 --gamma 1.0:1.0:1.0 --mode 1920x1080 --pos 0x2160 --rate 60.00 --reflect normal --rotate left
    # xrandr --fb 4137x4080 --output DP-1 --gamma 1.0:1.0:1.0 --mode 2560x1440 --pos 1080x2160 --primary --rate 120 --reflect normal --rotate normal'';
    desktopManager.xterm.enable = false;
    desktopManager = {
      wallpaper = {
        mode = "scale";
        combineScreens = true;
      };
    };
    windowManager.i3.enable = true;
    displayManager.defaultSession = "none+i3";
  };

  # services.picom = {
  #   enable = true;
  #   # fade = true;
  #   # inactiveOpacity = "0.9";
  #   # shadow = true;
  #   # fadeDelta = 4;
  #   vSync = true;
  # };

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
          # "${modifier}+Shift+e" = "exec xfce4-session-logout";
          "${modifier}+Shift+a" = "exec autorandr --load normal";
          "${modifier}+Ctrl+m" = "exec pavucontrol";
          "${modifier}+F2" = "exec firefox";
          "${modifier}+d" =
            "exec ${pkgs.dmenu}/bin/dmenu_run -i"; # run case insensitive
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
        floating = { criteria = [{ class = "Pavucontrol"; }]; };
      };
      extraConfig = ''
        workspace 1 output DP-1
        workspace 2 output DP-3
        workspace 3 output DP-4
      '';
    };

    xdg.configFile = {
      i3status = {
        source = ./i3status.conf;
        target = "../.i3status.conf";
      };
    };
  };
}
