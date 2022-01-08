{ pkgs, lib, config, ... }:

let
  modifier = "Mod4"; # windows key
  xcfg = config.services.xserver;
  cfg = xcfg.desktopManager;
  xdgConfig = config.home-manager.users.jr.xdg;
in {
  # services.picom = {
  #   enable = true;
  #   # fade = true;
  #   # inactiveOpacity = "0.9";
  #   # shadow = true;
  #   # fadeDelta = 4;
  #   vSync = true;
  # };

  # set to normal display setup, maybe use xrandr to get size?
  # services.fractalart = {
  #   enable = true;
  #   width = 4137;
  #   height = 4080;
  # };

  environment.systemPackages = with pkgs; [ xorg.xwininfo ];

  home-manager.users.jr = {
    xsession.numlock.enable = true;
    xsession.windowManager.i3 = {
      enable = true;
      config = {
        bars = [ ];
        modifier = "${modifier}";
        terminal = "kitty";
        keybindings = lib.mkOptionDefault {
          # "${modifier}+Shift+e" = "exec xfce4-session-logout";
          "${modifier}+Shift+a" = "exec autorandr --load normal";
          "${modifier}+Ctrl+m" = "exec pavucontrol";
          "${modifier}+F2" = "exec firefox";
          "${modifier}+d" = "exec rofi -show run";
        };
        startup = [
          {
            command = "systemctl --user restart polybar";
            always = true;
            notification = false;
          }
          {
            command = "autorandr --load normal";
            notification = false;
          }
          {
            command = "feh --bg-${cfg.wallpaper.mode} ${
                lib.optionalString cfg.wallpaper.combineScreens "--no-xinerama"
              } $HOME/.background-image";
            notification = false;
          }
        ]; # i think i need notification to add the no--startup-id
        window = { titlebar = false; };
        floating = {
          criteria = [
            { title = "Steam - Update News"; }
            { class = "Pavucontrol"; }
            {
              title = "bevy";
              class = "insta-gib";
            }
          ];
        };
      };
      extraConfig = ''
        workspace 1 output DP-0
        workspace 2 output HDMI-0
        workspace 3 output USB-C-0
        title_align center
      '';
    };
  };
}
