{ pkgs, lib, config, ... }:

let
  modifier = "Mod4"; # windows key
  xcfg = config.services.xserver;
  cfg = xcfg.desktopManager;
  xdgConfig = config.home-manager.users.jr.xdg;
in {

  programs.nm-applet.enable = true;

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
    xsession.numlock.enable = true;
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
          "${modifier}+d" = "exec rofi -show run";
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
        workspace 1 output DP-4
        workspace 2 output HDMI-0
        workspace 3 output USB-C-0
        title_align center
      '';
    };

    services = {
      polybar = {
        enable = true;
        package = pkgs.polybarFull;
        script = "polybar myBar &";
        settings = {
          "bar/myBar" = {
            bottom = true;
            modules-center = "title";
            modules-right = "eth-speed ram cpu date time";
          };

          "module/date" = {
            type = "internal/date";
            interval = 1;
            date = " %Y-%m-%d";
            label = "%date%";
            format-prefix = " ";
          };

          "module/time" = {
            type = "internal/date";
            interval = 1;
            time = "%H:%M";
            label = "%time%";
            format-prefix = " ";
          };

          "module/title" = {
            type = "internal/xwindow";
            label = "%title%";
            format = "<label>";
            format-font = 4;
          };

          "module/cpu" = {
            type = "internal/cpu";
            interval = "0.5";
            format = "<label>";
            label = "﬙ %percentage%%";
          };

          "module/ram" = {
            type = "internal/memory";
            interval = 3;
            format = "<label>";
            label = " %gb_free%/%gb_total%";
          };

          "module/eth" = {
            type = "internal/network";
            interface = "enp10s0";
            interval = 2;
            ping-interval = 2;

            format-connected = "<label-connected>";
            format-disconnected = "<label-disconnected>";
            format-packetloss = "<label-connected>";

            label-connected = " %ifname% %local_ip%  (%linkspeed%)";
            label-disconnected = "%ifname: not connected";
          };

          "module/eth-speed" = {
            type = "internal/network";
            interface = "enp10s0";
            interval = "0.5";
            ping-interval = 1;

            format-connected = "<label-connected>";
            format-disconnected = "";
            format-packetloss = "";
            label-connected = " %downspeed%   %upspeed%";
          };

        };
      };
    };

    # xdg.configFile = {
    #   i3status = {
    #     source = ./i3status.conf;
    #     target = "../.i3status.conf";
    #   };
    # };
  };
}
