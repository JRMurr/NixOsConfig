{ pkgs, lib, config, ... }:

let modifier = "Mod4"; # windows key
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
    };
    windowManager.i3.enable = true;
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
        startup = [{
          command = "autorandr --load normal";
          notification = true;
        }]; # i think i need notification to add the no--startup-id
        window = { titlebar = false; };
      };
    };
  };
}
