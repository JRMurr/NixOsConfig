{
  pkgs,
  lib,
  config,
  nixosConfig,
  ...
}:

let
  modifier = "Mod4"; # windows key
  gcfg = nixosConfig.myOptions.graphics;
  gesturesEnable = nixosConfig.myOptions.gestures.enable;
  xcfg = nixosConfig.services.xserver;
  cfg = xcfg.desktopManager;

  wallPaperPath = xcfg.displayManager.lightdm.background;

  monitorToWorkspaceCfg =
    with lib;
    config:
    if config.enable then "workspace ${toString config.workspace} output ${config.name}" else "";
  monitorWorkspaceConfigs = lib.concatMapStringsSep "\n" monitorToWorkspaceCfg gcfg.monitors;
in
{
  config = lib.mkIf gcfg.enable {
    home.packages = with pkgs; [
      xorg.xwininfo
      scrot
      pa_applet
      kitti3
      i3lock-blur
    ];

    # TODO: find a good spot for this + needs the system service on
    services.blueman-applet.enable = true;

    xsession.numlock.enable = true;

    # taken from  https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/services/x11/window-managers/i3.nix#L12
    xsession.initExtra = ''
      systemctl --user import-environment PATH DISPLAY XAUTHORITY DESKTOP_SESSION XDG_CONFIG_DIRS XDG_DATA_DIRS XDG_RUNTIME_DIR XDG_SESSION_ID DBUS_SESSION_BUS_ADDRESS || true
      dbus-update-activation-environment --systemd --all || true
    '';

    xsession.windowManager.i3 = {
      enable = true;
      config = {
        bars = [ ];
        modifier = "${modifier}";
        terminal = "kitty";
        keybindings = lib.mkOptionDefault {
          "${modifier}+Ctrl+l" = "exec xautolock -locknow";
          "${modifier}+Shift+a" = "exec autorandr normal";
          "${modifier}+Ctrl+m" = "exec pavucontrol";
          "${modifier}+n" = "nop kitti3";
          "${modifier}+F2" = "exec firefox";
          "${modifier}+d" = "exec rofi -show run";
          "${modifier}+Shift+Escape" = "exec rofi -show p -modi p:rofi-power-menu";

          "--release ${modifier}+Shift+s" = "exec scrot -s ~/Pictures/%Y-%m-%d-%H-%M-%S.png";

          # move focused workspace between monitors
          "${modifier}+Ctrl+greater" = "move workspace to output right";
          "${modifier}+Ctrl+less" = "move workspace to output left";
        };
        startup =
          [
            {
              command = "systemctl --user restart polybar";
              always = true;
              notification = false;
            }
            {
              command =
                let
                  kitti3Args = {
                    position = "CC";
                    shape = "0.9 0.9";
                  };
                  kittyArgs = {
                    override = [ "background_opacity=0.95" ];
                  };
                  toArgs =
                    args:
                    let
                      argList = lib.cli.toGNUCommandLine { } args;
                    in
                    lib.strings.concatStringsSep " " argList;
                in
                "kitti3 ${toArgs kitti3Args} -- ${toArgs kittyArgs}";
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
          ]
          ++ lib.lists.optional gesturesEnable {
            command = "fusuma -d -c ~/.config/fusuma/config.yml";
            always = true;
            notification = false;
          }; # i think i need notification to add the no--startup-id
        window = {
          titlebar = false;
          hideEdgeBorders = "smart";
        };
        workspaceLayout = "tabbed";
        gaps = {
          inner = 5;
          smartGaps = true;
          outer = 0;
        };
        floating = {
          criteria = [
            { title = "Steam - Update News"; }
            { class = "Pavucontrol"; }
            {
              title = "My Bevy App";
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
