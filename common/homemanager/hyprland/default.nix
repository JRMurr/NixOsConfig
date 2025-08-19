{
  pkgs,
  lib,
  config,
  nixosConfig,
  ...
}:
let

  # Original i3 config used Mod4; Hyprland calls that "SUPER"
  modifier = "SUPER";

  gcfg = nixosConfig.myOptions.graphics;
  monitors = gcfg.monitors;

  rotateToTransform =
    rot:
    if rot == "left" then
      "1"
    else if rot == "right" then
      "3"
    else if rot == "inverted" then
      "2"
    else
      0;

  # scaleOf =
  #   m:
  #   if m ? scale then
  #     if builtins.isAttrs m.scale then toString (m.scale.x or m.scale.y or 1) else toString m.scale
  #   else
  #     "1";
  # TODO: can do https://wiki.hypr.land/Configuring/Monitors/#monitor-v2
  # to not make it a line ...
  hyprMonitorLine =
    m:
    let
      name = m.name;
      # disable takes precedence if enable=false
      disabled = m.enable == false;

      pos = m.position or "auto";
      resolution =
        let
          res = m.resolution or "preferred";
          rate = if m ? rate then "@${m.rate}" else "";
        in
        "${res}${rate}";

      transform = if m ? rotate then rotateToTransform m.rotate else 0;

      cfg =
        if disabled then
          { disabled = 1; }
        else
          {
            mode = resolution;
            position = pos;
            scale = m.scale or "1";
            transform = transform;
          };
    in
    { output = name; } // cfg;

  workspacePins = lib.concatMap (
    m: lib.optional (m ? workspace) "workspace = ${toString m.workspace}, monitor:${m.name or ""}"
  ) monitors;

  # https://gist.github.com/udf/4d9301bdc02ab38439fd64fbda06ea43#planet-status-h4xed
  # mkMergeTopLevel =
  #   with lib;
  #   names: attrs: getAttrs names (mapAttrs (k: v: mkMerge v) (foldAttrs (n: a: [ n ] ++ a) [ ] attrs));

  monitorLines = map hyprMonitorLine monitors;

  setDefaultWallpaperExec = builtins.concatMap (
    monitor:
    if monitor.wallpaper == null then
      [ ]
    else
      [
        "hyprctl hyprpaper reload ${monitor.name}, ${monitor.wallpaper}"
      ]
  ) monitors;

  wallpaperDir = "$HOME/Wallpapers/";

  # https://wiki.hypr.land/Hypr-Ecosystem/hyprpaper/#using-this-keyword-to-randomize-your-wallpaper
  randomWallpaper = pkgs.writeShellApplication {
    name = "random-wallpaper";

    runtimeInputs = [
      pkgs.jq
      config.wayland.windowManager.hyprland.finalPackage
    ];

    text = ''
      WALLPAPER_DIR="${wallpaperDir}"
      # Get the name of the focused monitor with hyprctl
      FOCUSED_MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

      # NOTE: below is broken, list loaded does not seem to know what monitor has each wallpaper loaded
      # Get a random wallpaper that is not the current one
      # CURRENT_WALL=$(hyprctl hyprpaper listloaded)
      # WALLPAPER=$(find "$WALLPAPER_DIR" -type f ! -name "$(basename "$CURRENT_WALL")" | shuf -n 1)

      WALLPAPER=$(find "$WALLPAPER_DIR" -type f | shuf -n 1)

      # Apply the selected wallpaper
      hyprctl hyprpaper reload "$FOCUSED_MONITOR","$WALLPAPER"
    '';
  };
in

{
  imports = [
    ./waybar.nix
    ./hyprlock.nix
  ];
  config = lib.mkIf gcfg.enable {

    home.packages = with pkgs; [
      wlogout
      nwg-look
    ];

    gtk.cursorTheme = {
      # package = pkgs.comixcursors.Opaque_Black;
      name = "Adwaita";
    };

    # wallpaper service
    services.hyprpaper = {
      enable = true;
      settings = {
        ipc = "on";
        splash = false;
      };
    };

    wayland.windowManager.hyprland.enable = true;
    wayland.windowManager.hyprland.settings = lib.mkMerge [
      {
        "$mainMod" = "${modifier}";
        "$terminal" = "kitty";
        "$fileManager" = "dolphin";
        "$menu" = "rofi -show run";
        monitorv2 = monitorLines;

        exec-once = [
          "hyprctl setcursor Adwaita 24"
          # start kitty in the special kitty ws
          # idk if this works (it does not...)
          # "[workspace kitty-ws silent] kitty"
        ]
        ++ setDefaultWallpaperExec;

        # init kitty-ws with a slightly transparent smaller terminal
        workspace = [
          "special:kitty-ws, on-created-empty:[float; size 90% 90%; opacity 0.95] kitty"
        ];
      }
      #####################
      ####### BINDS #######
      #####################
      {
        bind = [
          "$mainMod, P, pseudo" # dwindle pseudo-tile
          "$mainMod, J, togglesplit" # dwindle split toggle

          # Move focus with mainMod + arrows
          "$mainMod, left, movefocus, l"
          "$mainMod, right, movefocus, r"
          "$mainMod, up, movefocus, u"
          "$mainMod, down, movefocus, d"

          # tabbed groups https://wiki.hypr.land/Configuring/Dispatchers/#grouped-tabbed-windows
          "$mainMod, w, togglegroup"
          "$mainMod SHIFT, left, movewindoworgroup, l"
          "$mainMod SHIFT, right, movewindoworgroup, r"
          "$mainMod SHIFT, up, movewindoworgroup, u"
          "$mainMod SHIFT, down, movewindoworgroup, d"

          # kitty special workspace
          "$mainMod, n, togglespecialworkspace, kitty-ws"
          # "$mainMod SHIFT, n, movetoworkspace, special:kitty-ws"

          "$mainMod,RETURN,exec,kitty" # $mod+Enter: terminal
          "$mainMod,D,exec,rofi -show run" # $mod+d: launcher
          "$mainMod SHIFT,Q,killactive" # $mod+Shift+q: kill
          "$mainMod SHIFT,C,exec,hyprctl reload" # $mod+Shift+c: reload config
          "$mainMod SHIFT,R,exec,hyprctl reload" # i3 “restart” → reload hypr config
          "$mainMod SHIFT,E,exec,wlogout" # $mod+Shift+e: exit menu
          "$mainMod,F,fullscreen" # $mod+f: toggle fullscreen
          "$mainMod SHIFT,SPACE,togglefloating" # $mod+Shift+space: toggle float
          "$mainMod Control_L,M,exec,pavucontrol" # from your custom i3
          "$mainMod,F2,exec,firefox"
          "$mainMod Control_L, L,exec,loginctl lock-session"
          "$mainMod SHIFT,w,exec,${pkgs.lib.getExe randomWallpaper}"

          # Workspaces 1–10
          "$mainMod,1,workspace,1"
          "$mainMod,2,workspace,2"
          "$mainMod,3,workspace,3"
          "$mainMod,4,workspace,4"
          "$mainMod,5,workspace,5"
          "$mainMod,6,workspace,6"
          "$mainMod,7,workspace,7"
          "$mainMod,8,workspace,8"
          "$mainMod,9,workspace,9"
          "$mainMod,0,workspace,10"

          # Move focused window to workspace (i3: $mod+Shift+[1-0])
          "$mainMod SHIFT,1,movetoworkspace,1"
          "$mainMod SHIFT,2,movetoworkspace,2"
          "$mainMod SHIFT,3,movetoworkspace,3"
          "$mainMod SHIFT,4,movetoworkspace,4"
          "$mainMod SHIFT,5,movetoworkspace,5"
          "$mainMod SHIFT,6,movetoworkspace,6"
          "$mainMod SHIFT,7,movetoworkspace,7"
          "$mainMod SHIFT,8,movetoworkspace,8"
          "$mainMod SHIFT,9,movetoworkspace,9"
          "$mainMod SHIFT,0,movetoworkspace,10"
        ];

        bindm = [
          "$mainMod, mouse:272, movewindow" # LMB drag to move
          "$mainMod, mouse:273, resizewindow" # RMB drag to resize
        ];

        bindel = [
          # Volume / mic / brightness
          ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
          ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          ", XF86AudioMute,        exec, wpctl set-mute   @DEFAULT_AUDIO_SINK@ toggle"
          ", XF86AudioMicMute,     exec, wpctl set-mute   @DEFAULT_AUDIO_SOURCE@ toggle"
          ", XF86MonBrightnessUp,   exec, brightnessctl -e4 -n2 set 5%+"
          ", XF86MonBrightnessDown, exec, brightnessctl -e4 -n2 set 5%-"
        ];

        bindl = [
          "$mainMod SHIFT, s, exec, ${lib.getExe pkgs.hyprshot} -m region"
          ", XF86AudioNext,  exec, playerctl next"
          ", XF86AudioPause, exec, playerctl play-pause"
          ", XF86AudioPlay,  exec, playerctl play-pause"
          ", XF86AudioPrev,  exec, playerctl previous"
        ];
      }
      #####################
      ### LOOK AND FEEL ###
      #####################
      {

        # Refer to https://wiki.hypr.land/Configuring/Variables/

        # https://wiki.hypr.land/Configuring/Variables/#general
        general = {
          gaps_in = 5;
          gaps_out = 10;

          border_size = 1;

          # https://wiki.hypr.land/Configuring/Variables/#variable-types for info about colors
          "col.active_border" = "$accent"; # rgba(33ccffee) rgba(00ff99ee) 45deg
          "col.inactive_border" = "rgba(595959aa)";

          # Set to true enable resizing windows by clicking and dragging on borders and gaps
          resize_on_border = false;

          # Please see https://wiki.hypr.land/Configuring/Tearing/ before you turn this on
          allow_tearing = false;

          layout = "dwindle";
        };

        # https://wiki.hypr.land/Configuring/Variables/#decoration
        decoration = {
          rounding = 4;
          rounding_power = 4;

          # Focused / unfocused opacity
          active_opacity = 1.0;
          inactive_opacity = 1.0;

          shadow = {
            enabled = true;
            range = 4;
            render_power = 3;
            color = "rgba(1a1a1aee)";
          };

          blur = {
            enabled = true;
            size = 3;
            passes = 1;
            vibrancy = 0.1696;
          };
        };

        group.groupbar = {
          gradients = true;
          "col.active" = "$base";
          "col.inactive" = "$crust";
        };

        animations = {
          enabled = true;

          # Default curves, see https://wiki.hypr.land/Configuring/Animations/#curves
          # NAME,           X0,   Y0,   X1,   Y1
          bezier = [
            "easeOutQuint,   0.23, 1,    0.32, 1"
            "easeInOutCubic, 0.65, 0.05, 0.36, 1"
            "linear,         0,    0,    1,    1"
            "almostLinear,   0.5,  0.5,  0.75, 1"
            "quick,          0.15, 0,    0.1,  1"
          ];

          # Default animations, see https://wiki.hypr.land/Configuring/Animations/
          #  NAME,      ONOFF, SPEED, CURVE,        [STYLE]
          animation = [
            "global,        1, 10,   default"
            "border,        1, 5.39, easeOutQuint"
            "windows,       1, 4.79, easeOutQuint"
            "windowsIn,     1, 4.1,  easeOutQuint, popin 87%"
            "windowsOut,    1, 1.49, linear,       popin 87%"
            "fadeIn,        1, 1.73, almostLinear"
            "fadeOut,       1, 1.46, almostLinear"
            "fade,          1, 3.03, quick"
            "layers,        1, 3.81, easeOutQuint"
            "layersIn,      1, 4,    easeOutQuint, fade"
            "layersOut,     1, 1.5,  linear,       fade"
            "fadeLayersIn,  1, 1.79, almostLinear"
            "fadeLayersOut, 1, 1.39, almostLinear"
            "workspaces,    1, 1.94, almostLinear, fade"
            "workspacesIn,  1, 1.21, almostLinear, fade"
            "workspacesOut, 1, 1.94, almostLinear, fade"
            "zoomFactor,    1, 7,    quick"
          ];
        };

        # windowrule = [
        #   "floating:1 onworkspace:s[true]"
        # ];
      }
      # https://wiki.hypr.land/Configuring/Workspace-Rules/#smart-gaps-ignoring-special-workspaces
      {
        workspace = [
          "w[tv1]s[false], gapsout:0, gapsin:0"
          "f[1]s[false], gapsout:0, gapsin:0"
        ];
        windowrule = [
          "bordersize 0, floating:0, onworkspace:w[tv1]s[false]"
          "rounding 0, floating:0, onworkspace:w[tv1]s[false]"
          "bordersize 0, floating:0, onworkspace:f[1]s[false]"
          "rounding 0, floating:0, onworkspace:f[1]s[false]"
        ];
      }

    ];

    wayland.windowManager.hyprland.extraConfig = ''
      # This is an example Hyprland config file.
      # Refer to the wiki for more information.
      # https://wiki.hypr.land/Configuring/

      # Please note not all available settings / options are set here.
      # For a full list, see the wiki

      # You can split this configuration into multiple files
      # Create your files separately and then link them to this file like this:
      # source = ~/.config/hypr/myColors.conf

      ### MY PROGRAMS ###
      ###################

      # See https://wiki.hypr.land/Configuring/Keywords/

      # Set programs that you use


      #############################
      ### ENVIRONMENT VARIABLES ###
      #############################

      # See https://wiki.hypr.land/Configuring/Environment-variables/

      env = XCURSOR_SIZE,24
      env = HYPRCURSOR_SIZE,24

      ###################
      ### PERMISSIONS ###
      ###################

      # See https://wiki.hypr.land/Configuring/Permissions/
      # Please note permission changes here require a Hyprland restart and are not applied on-the-fly
      # for security reasons

      # ecosystem {
      #   enforce_permissions = 1
      # }

      # permission = /usr/(bin|local/bin)/grim, screencopy, allow
      # permission = /usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland, screencopy, allow
      # permission = /usr/(bin|local/bin)/hyprpm, plugin, allow

      # See https://wiki.hypr.land/Configuring/Dwindle-Layout/ for more
      dwindle {
          pseudotile = true # Master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
          preserve_split = true # You probably want this
      }

      # See https://wiki.hypr.land/Configuring/Master-Layout/ for more
      master {
          new_status = master
      }

      # https://wiki.hypr.land/Configuring/Variables/#misc
      misc {
          force_default_wallpaper = 0 # Set to 0 or 1 to disable the anime mascot wallpapers
          disable_hyprland_logo = true # If true disables the random hyprland logo / anime girl background. :(
      }


      #############
      ### INPUT ###
      #############

      # https://wiki.hypr.land/Configuring/Variables/#input
      input {
          kb_layout = us
          kb_variant =
          kb_model =
          kb_options =
          kb_rules =

          follow_mouse = 1

          sensitivity = 0 # -1.0 - 1.0, 0 means no modification.

          touchpad {
              natural_scroll = false
          }
      }

      # https://wiki.hypr.land/Configuring/Variables/#gestures
      gestures {
          workspace_swipe = false
      }

      # Example per-device config
      # See https://wiki.hypr.land/Configuring/Keywords/#per-device-input-configs for more
      device {
          name = epic-mouse-v1
          sensitivity = -0.5
      }

      ##############################
      ### WINDOWS AND WORKSPACES ###
      ##############################

      # See https://wiki.hypr.land/Configuring/Window-Rules/ for more
      # See https://wiki.hypr.land/Configuring/Workspace-Rules/ for workspace rules

      # Example windowrule
      # windowrule = float,class:^(kitty)$,title:^(kitty)$

      # Ignore maximize requests from apps. You'll probably like this.
      windowrule = suppressevent maximize, class:.*

      # Fix some dragging issues with XWayland
      windowrule = nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0
    '';
  };
}
