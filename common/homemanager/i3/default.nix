{ pkgs, lib, config, nixosConfig, ... }:

let
  modifier = "Mod4"; # windows key
  gcfg = nixosConfig.myOptions.graphics;
  gesturesEnable = nixosConfig.myOptions.gestures.enable;
  xcfg = nixosConfig.services.xserver;
  cfg = xcfg.desktopManager;

  wallPaperPath = xcfg.displayManager.lightdm.background;

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
          "${modifier}+Shift+a" = "exec autorandr normal";
          "${modifier}+Ctrl+m" = "exec pavucontrol";
          "${modifier}+F2" = "exec firefox";
          "${modifier}+d" = "exec rofi -show run";
          "${modifier}+Shift+Escape" =
            "exec rofi -show p -modi p:rofi-power-menu";
          "--release ${modifier}+Shift+s" =
            "exec scrot -s ~/Pictures/%Y-%m-%d-%H-%M-%S.png";

          # move focused workspace between monitors
          "${modifier}+Ctrl+greater" = "move workspace to output right";
          "${modifier}+Ctrl+less" = "move workspace to output left";
        };
        startup = [
          {
            command = "systemctl --user restart polybar";
            always = true;
            notification = false;
          }
          # {
          #   command = "feh --bg-${cfg.wallpaper.mode} ${
          #       lib.optionalString cfg.wallpaper.combineScreens "--no-xinerama"
          #     } ${wallPaperPath}";
          #   notification = false;
          # }
          {
            command = "pa-applet";
            notification = false;
          }
        ] ++ lib.lists.optional gesturesEnable {
          command = "fusuma -d -c ~/.config/fusuma/config.yml";
          always = true;
          notification = false;
        }; # i think i need notification to add the no--startup-id
        window = {
          titlebar = false;
          hideEdgeBorders = "smart";
        };
        workspaceLayout = "tabbed";
        floating = {
          criteria = [
            { title = "Steam - Update News"; }
            { class = "Pavucontrol"; }
            {
              title = "Bevy App";
              # class = "insta-client";
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
