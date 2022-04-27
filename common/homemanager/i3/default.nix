{ pkgs, lib, config, nixosConfig, ... }:

let
  modifier = "Mod4"; # windows key
  gcfg = nixosConfig.myOptions.graphics;
  xcfg = nixosConfig.services.xserver;
  cfg = xcfg.desktopManager;

  monitorToWorkspaceCfg = with lib;
    config:
    if config.enable then
      "workspace ${toString config.workspace} output ${config.name}"
    else
      "";
  monitorWorkspaceConfigs =
    lib.concatMapStringsSep "\n" monitorToWorkspaceCfg gcfg.monitors;
in {
  config = lib.mkIf gcfg.enable {
    home.packages = with pkgs; [ xorg.xwininfo scrot pa_applet ];

    xsession.numlock.enable = true;
    xsession.windowManager.i3 = {
      enable = true;
      config = {
        bars = [ ];
        modifier = "${modifier}";
        terminal = "kitty";
        keybindings = lib.mkOptionDefault {
          # "${modifier}+Shift+e" = "exec xfce4-session-logout";
          "${modifier}+Shift+a" = "exec autorandr --change";
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
            command = "autorandr --change";
            notification = false;
          }
          {
            command = "feh --bg-${cfg.wallpaper.mode} ${
                lib.optionalString cfg.wallpaper.combineScreens "--no-xinerama"
              } $HOME/.background-image";
            notification = false;
          }
          {
            command = "pa-applet";
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
              class = "insta-client";
            }
          ];
        };
      };
      extraConfig = ''
        ${monitorWorkspaceConfigs}
        title_align center
      '';
    };
  };

}
