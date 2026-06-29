{
  pkgs,
  lib,
  config,
  osConfig,
  ...
}:
let

  inherit (lib.generators) mkLuaInline;

  # Original i3 config used Mod4; Hyprland calls that "SUPER"
  modifier = "SUPER";

  gcfg = osConfig.myOptions.graphics;
  monitors = gcfg.monitors;
  colors = osConfig.myOptions.theme.colors;

  # ==============================================================================
  # Lua dispatcher / bind helpers
  # ==============================================================================
  #
  # Since Hyprland 0.55 the config is Lua: each bind is an `hl.bind(keys,
  # dispatcher, opts?)` call rather than a `bind = mod, key, dispatcher, args`
  # string. home-manager's lua renderer turns a `settings.bind` list entry of the
  # form `{ _args = [ keys dispatcher opts ]; }` into exactly that call, running
  # each arg through its Lua generator. A `mkLuaInline` value is emitted verbatim
  # (so it becomes a real `hl.dsp.*()` call, not a quoted string); plain strings
  # are quoted; attrsets become Lua tables.
  #
  # mkBind/mkBindF wrap the dispatcher in mkLuaInline for us so call sites read
  # like the wiki examples.

  mkBind = keys: dispatcher: { _args = [ keys (mkLuaInline dispatcher) ]; };
  mkBindF = keys: dispatcher: flags: { _args = [ keys (mkLuaInline dispatcher) flags ]; };

  # Common dispatchers as small builders to avoid hand-escaping quotes.
  exec = cmd: ''hl.dsp.exec_cmd("${cmd}")'';
  focusDir = d: ''hl.dsp.focus({ direction = "${d}" })'';
  moveDir = d: ''hl.dsp.window.move({ direction = "${d}", group_aware = true })'';
  focusWs = n: "hl.dsp.focus({ workspace = ${toString n} })";
  moveToWs = n: "hl.dsp.window.move({ workspace = ${toString n} })";

  # ==============================================================================
  # Monitor configuration -> hl.monitor(spec)
  # ==============================================================================
  #
  # Transforms map to Hyprland's integer rotation codes. monitorv2's per-key
  # hyprlang form is gone; hl.monitor takes a single spec table instead.
  rotateToTransform =
    rot:
    if rot == "left" then
      1
    else if rot == "right" then
      3
    else if rot == "inverted" then
      2
    else
      0;

  hyprMonitorSpec =
    m:
    let
      pos = m.position or "auto";
      resolution =
        let
          res = m.resolution or "preferred";
          rate = if m ? rate then "@${m.rate}" else "";
        in
        "${res}${rate}";
      transform = if m ? rotate then rotateToTransform m.rotate else 0;
    in
    if m.enable == false then
      {
        output = m.name;
        disabled = true;
      }
    else
      {
        output = m.name;
        mode = resolution;
        position = pos;
        scale = m.scale or 1;
        inherit transform;
      };

  monitorSpecs = map hyprMonitorSpec monitors;

  # Pin workspaces declared on a monitor to that monitor (was `workspace = N,
  # monitor:X`, now a workspace rule).
  workspacePins = lib.concatMap (
    m:
    lib.optional (m ? workspace) {
      workspace = toString m.workspace;
      monitor = m.name;
    }
  ) monitors;

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

  kittyWorkspace = "kitty-ws";

  # https://www.reddit.com/r/hyprland/comments/14pzqi6/is_it_possible_to_limit_only_one_window_client_on/lgh8b2u/
  limitWorkspace = pkgs.writeShellApplication {
    name = "limitWorkspace";

    runtimeInputs = [
      config.wayland.windowManager.hyprland.finalPackage
      pkgs.gawk
      pkgs.socat
    ];

    # lints annoy me...
    checkPhase = "";

    text = ''
      handle() {
        line=$1
        if [[ "$line" = openwindow* ]]; then
          read -r window_address workspace window_class window_title <<<$(echo "$line" | awk -F "[>,]" '{print $3,$4,$5,$6}')
          if [[ "$workspace" == special:${kittyWorkspace} && "$window_class" != ${kittyWorkspace} ]]; then
            hyprctl dispatch movetoworkspace e+0,address:0x''${window_address}
          fi
        fi
      }

      socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do handle "$line"; done
    '';
  };

  # Things to run once on session start. Was `exec-once`; the Lua API listens on
  # the `hyprland.start` event instead (see extraConfig below).
  startupExecs = [
    "hyprctl setcursor Adwaita 24"
    "${lib.getExe limitWorkspace}" # TODO: this does not seem to trigger after a rebuild???
    # "noctalia-shell"
  ]
  ++ setDefaultWallpaperExec;

in

{
  imports = lib.optionals (gcfg.enable) [
    # ./waybar.nix
    ./hyprpanel
    # ./hyprlock.nix
    ./swaylock.nix
  ];
  config = lib.mkIf gcfg.enable {

    # Catppuccin's hyprland module emits `colors._var = mkLuaInline
    # "require('themes.catppuccin')"`, which the Lua renderer CAN handle now that
    # we're on configType = "lua". We keep it off here on purpose: this change is
    # the bare hyprlang->lua port, validated on its own. Re-enabling catppuccin
    # (and dropping the manual palette wiring below) is a deliberate follow-up
    # once the core lua config is confirmed working in a live session.
    catppuccin.hyprland.enable = false;

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

    # TODO: upstream this, hyprpaper start after hyprland
    # make configurable like hypridle
    systemd.user.services.hyprpaper.Unit = {
      After = lib.mkForce [ "hyprland-session.target" ];
      PartOf = lib.mkForce [ "hyprland-session.target" ];
    };

    # hyprpanel needs WAYLAND_DISPLAY which isn't set until hyprland-session.target
    systemd.user.services.hyprpanel.Unit = {
      After = lib.mkForce [ "hyprland-session.target" ];
      PartOf = lib.mkForce [ "hyprland-session.target" ];
    };
    systemd.user.services.hyprpanel.Install = {
      WantedBy = lib.mkForce [ "hyprland-session.target" ];
    };

    wayland.windowManager.hyprland.enable = true;

    # Hyprland 0.55+ deprecates hyprlang in favour of Lua. home-manager renders
    # `settings` as `hl.*()` calls into ~/.config/hypr/hyprland.lua under this
    # mode. (Default would be "hyprlang" only because our home.stateVersion is
    # ancient; set explicitly.)
    wayland.windowManager.hyprland.configType = "lua";

    wayland.windowManager.hyprland.settings = lib.mkMerge [
      # Monitors + workspace->monitor pins
      {
        monitor = monitorSpecs;
        workspace_rule = workspacePins;
      }

      # float windows that make sense
      {
        # `hyprctl clients` to inspect open windows. Each rule is one
        # hl.window_rule({ match = {...props}, ...effects }).
        window_rule = [
          {
            match.class = "org\\.pulseaudio\\.pavucontrol";
            float = true;
            size = [
              1100
              1100
            ];
            center = true;
          }
          # file picker dialogs
          {
            match.title = "(Open File)";
            float = true;
          }
        ];
      }

      # kitty special workspace
      {
        # Create the special workspace and spawn kitty in it
        workspace_rule = [
          {
            workspace = "special:${kittyWorkspace}";
            on_created_empty = "kitty --class ${kittyWorkspace}";
          }
        ];

        # Make that kitty a floating 90% x 90% slightly transparent window *on
        # that special workspace*. size/move take vec2 tables; opacity is a string
        # multiplier.
        window_rule = [
          {
            match = {
              class = "^${kittyWorkspace}$";
              workspace = "special:${kittyWorkspace}";
            };
            float = true;
            center = true;
            size = [
              "(monitor_w*0.9)"
              "(monitor_h*0.9)"
            ];
            opacity = "0.95";
          }
        ];
      }

      #####################
      ####### BINDS #######
      #####################
      {
        bind = [
          (mkBind "${modifier} + P" "hl.dsp.window.pseudo()") # dwindle pseudo-tile

          # Move focus with mainMod + arrows
          (mkBind "${modifier} + left" (focusDir "l"))
          (mkBind "${modifier} + right" (focusDir "r"))
          (mkBind "${modifier} + up" (focusDir "u"))
          (mkBind "${modifier} + down" (focusDir "d"))

          # tabbed groups https://wiki.hypr.land/Configuring/Dispatchers/#grouped-tabbed-windows
          (mkBind "${modifier} + w" "hl.dsp.group.toggle()")
          (mkBind "${modifier} + SHIFT + left" (moveDir "l"))
          (mkBind "${modifier} + SHIFT + right" (moveDir "r"))
          (mkBind "${modifier} + SHIFT + up" (moveDir "u"))
          (mkBind "${modifier} + SHIFT + down" (moveDir "d"))

          # kitty special workspace
          (mkBind "${modifier} + n" ''hl.dsp.workspace.toggle_special("${kittyWorkspace}")'')

          (mkBind "${modifier} + RETURN" (exec "kitty")) # terminal
          (mkBind "${modifier} + D" (exec "rofi -show run")) # launcher
          (mkBind "${modifier} + SHIFT + Q" "hl.dsp.window.close()") # kill
          (mkBind "${modifier} + SHIFT + C" (exec "hyprctl reload")) # reload config
          (mkBind "${modifier} + SHIFT + R" (exec "hyprctl reload")) # i3 "restart"
          (mkBind "${modifier} + SHIFT + E" (exec "wlogout")) # exit menu
          (mkBind "${modifier} + SHIFT + ESCAPE" (exec "rofi -show p -modi p:rofi-power-menu")) # power menu
          (mkBind "${modifier} + F" "hl.dsp.window.fullscreen()") # toggle fullscreen
          (mkBind "${modifier} + SHIFT + SPACE" "hl.dsp.window.float()") # toggle float
          (mkBind "${modifier} + CTRL + M" (exec "pavucontrol"))
          (mkBind "${modifier} + F2" (exec "firefox"))
          (mkBind "${modifier} + CTRL + L" (exec "loginctl lock-session"))
          (mkBind "${modifier} + SHIFT + w" (exec "${lib.getExe randomWallpaper}"))
        ]
        # Workspaces 1-10 (key "0" -> workspace 10)
        ++ (map (
          k: mkBind "${modifier} + ${k}" (focusWs (if k == "0" then 10 else lib.toInt k))
        ) (lib.genList (i: toString (lib.mod (i + 1) 10)) 10))
        # Move focused window to workspace (i3: $mod+Shift+[1-0])
        ++ (map (
          k: mkBind "${modifier} + SHIFT + ${k}" (moveToWs (if k == "0" then 10 else lib.toInt k))
        ) (lib.genList (i: toString (lib.mod (i + 1) 10)) 10))
        # Mouse: drag to move / resize (was bindm)
        ++ [
          (mkBindF "${modifier} + mouse:272" "hl.dsp.window.drag()" { mouse = true; })
          (mkBindF "${modifier} + mouse:273" "hl.dsp.window.resize()" { mouse = true; })
        ]
        # Volume / mic / brightness (was bindel: repeat + works while locked)
        ++ (map (b: mkBindF b.keys (exec b.cmd) { repeating = true; locked = true; }) [
          {
            keys = "XF86AudioRaiseVolume";
            cmd = "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+";
          }
          {
            keys = "XF86AudioLowerVolume";
            cmd = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
          }
          {
            keys = "XF86AudioMute";
            cmd = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          }
          {
            keys = "XF86AudioMicMute";
            cmd = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
          }
          {
            keys = "XF86MonBrightnessUp";
            cmd = "brightnessctl -e4 -n2 set 5%+";
          }
          {
            keys = "XF86MonBrightnessDown";
            cmd = "brightnessctl -e4 -n2 set 5%-";
          }
        ])
        # Screenshot + media (was bindl: works while locked)
        ++ [
          (mkBindF "${modifier} + SHIFT + s" (exec "${lib.getExe pkgs.hyprshot} -m region") {
            locked = true;
          })
          (mkBindF "XF86AudioNext" (exec "playerctl next") { locked = true; })
          (mkBindF "XF86AudioPause" (exec "playerctl play-pause") { locked = true; })
          (mkBindF "XF86AudioPlay" (exec "playerctl play-pause") { locked = true; })
          (mkBindF "XF86AudioPrev" (exec "playerctl previous") { locked = true; })
        ];
      }

      #####################
      ### LOOK AND FEEL ###
      #####################
      #
      # All the old `general {}` / `decoration {}` / etc. blocks collapse into a
      # single hl.config({ ... }) table. Refer to
      # https://wiki.hypr.land/Configuring/Basics/Variables/
      {
        config = {
          general = {
            gaps_in = 5;
            gaps_out = 10;

            border_size = 1;

            # gradient = a color string, or { colors = {...}, angle = N }
            "col.active_border" = {
              colors = [
                "rgba(ca9ee6ff)" # catppuccin mauve
                "rgba(f2d5cfff)" # -> rosewater
              ];
              angle = 45;
            };
            "col.inactive_border" = "rgba(595959aa)";

            resize_on_border = false;
            allow_tearing = false;

            layout = "dwindle";
          };

          decoration = {
            rounding = 10;
            rounding_power = 4;

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
              size = 8;
              passes = 3;
              new_optimizations = true;
              noise = 0.02;
              contrast = 0.9;
              brightness = 0.8;
              vibrancy = 0.1696;
            };
          };

          group.groupbar = {
            gradients = true;
            # palette hex values include a leading '#' which Hyprland's rgb() rejects
            "col.active" = "rgb(${lib.removePrefix "#" colors.base})";
            "col.inactive" = "rgb(${lib.removePrefix "#" colors.crust})";
          };

          animations.enabled = true;

          # was the `dwindle {}` / `master {}` / `input {}` / `misc {}` blocks in
          # extraConfig
          dwindle.preserve_split = true; # You probably want this
          master.new_status = "master";

          input = {
            kb_layout = "us";
            follow_mouse = 1;
            sensitivity = 0; # -1.0 - 1.0, 0 means no modification.
            touchpad.natural_scroll = false;
          };

          misc = {
            force_default_wallpaper = 0; # disable the anime mascot wallpapers
            disable_hyprland_logo = true;
          };
        };

        # Beziers (was `bezier = name, x0,y0,x1,y1`) -> hl.curve(name, { points })
        curve = [
          {
            _args = [
              "easeOut" # smooth decel, no overshoot
              {
                type = "bezier";
                points = [
                  [
                    0.25
                    1
                  ]
                  [
                    0.5
                    1
                  ]
                ];
              }
            ];
          }
          {
            _args = [
              "liner"
              {
                type = "bezier";
                points = [
                  [
                    1
                    1
                  ]
                  [
                    1
                    1
                  ]
                ];
              }
            ];
          }
        ];

        # Animations (was `animation = name, onoff, speed, curve[, style]`)
        animation = [
          {
            leaf = "windows";
            enabled = true;
            speed = 3;
            curve = "easeOut";
          }
          {
            leaf = "windowsIn";
            enabled = true;
            speed = 3;
            curve = "easeOut";
            style = "popin 90%";
          }
          {
            leaf = "windowsOut";
            enabled = true;
            speed = 2;
            curve = "easeOut";
            style = "popin 90%";
          }
          {
            leaf = "windowsMove";
            enabled = true;
            speed = 3;
            curve = "easeOut";
          }
          {
            leaf = "border";
            enabled = true;
            speed = 1;
            curve = "liner";
          }
          {
            leaf = "borderangle";
            enabled = true;
            speed = 30;
            curve = "liner";
            style = "loop";
          }
          {
            leaf = "fade";
            enabled = true;
            speed = 3;
            curve = "easeOut";
          }
          {
            leaf = "workspaces";
            enabled = true;
            speed = 3;
            curve = "easeOut";
          }
          {
            leaf = "specialWorkspace";
            enabled = true;
            speed = 3;
            curve = "easeOut";
            style = "fade";
          }
          {
            leaf = "zoomFactor";
            enabled = true;
            speed = 3;
            curve = "easeOut";
          }
        ];

        # Environment variables (was `env = KEY,VALUE`)
        env = [
          {
            _args = [
              "XCURSOR_SIZE"
              "24"
            ];
          }
          {
            _args = [
              "HYPRCURSOR_SIZE"
              "24"
            ];
          }
        ];

        # Per-device input (was `device { name = ...; sensitivity = ...; }`)
        device = [
          {
            name = "epic-mouse-v1";
            sensitivity = -0.5;
          }
        ];
      }

      # https://wiki.hypr.land/Configuring/Workspace-Rules/#smart-gaps-ignoring-special-workspaces
      {
        workspace_rule = [
          {
            workspace = "w[tv1]s[false]";
            gaps_out = 0;
            gaps_in = 0;
          }
          {
            workspace = "f[1]s[false]";
            gaps_out = 0;
            gaps_in = 0;
          }
        ];
        window_rule = [
          {
            match = {
              float = false;
              workspace = "w[tv1]s[false]";
            };
            border_size = 0;
            rounding = 0;
          }
          {
            match = {
              float = false;
              workspace = "f[1]s[false]";
            };
            border_size = 0;
            rounding = 0;
          }

          # Ignore maximize requests from apps.
          {
            match.class = ".*";
            suppress_event = "maximize";
          }
          # Fix some dragging issues with XWayland
          {
            match = {
              class = "^$";
              title = "^$";
              xwayland = true;
              float = true;
              fullscreen = false;
              pin = false;
            };
            no_focus = true;
          }
        ];
      }
    ];

    # Autostart: the Lua API runs things on the `hyprland.start` event rather than
    # `exec-once`. extraConfig is appended verbatim to hyprland.lua, so this is
    # raw Lua.
    wayland.windowManager.hyprland.extraConfig = ''
      hl.on("hyprland.start", function()
      ${lib.concatMapStringsSep "\n" (c: ''  hl.exec_cmd("${c}")'') startupExecs}
      end)
    '';
  };
}
