{
  pkgs,
  lib,
  config,
  osConfig,
  ...
}:
let
  gcfg = osConfig.myOptions.graphics;
  isLaptop = osConfig.myOptions.laptop;

  monitors = gcfg.monitors;

  # ==============================================================================
  # Bar layouts
  # ==============================================================================
  #
  # HyprPanel used left/middle/right; wayle uses left/center/right and a flat
  # per-monitor `[[bar.layout]]` list keyed by connector name. The module names
  # also changed from HyprPanel's identifiers:
  #   workspaces   -> hyprland-workspaces   (compositor-specific in wayle)
  #   windowtitle  -> window-title
  # everything else (dashboard, media, volume, network, bluetooth, battery,
  # systray, clock, notifications) kept its name.
  #
  # Note: wayle's `dashboard` is a power-menu button (lock/logout/reboot/
  # poweroff), NOT HyprPanel's app-launcher-with-shortcuts. The old Firefox /
  # YouTube Music / Discord / rofi shortcuts and the "JR" launcher icon have no
  # wayle equivalent and were intentionally dropped in the migration — apps are
  # launched via the Hyprland `Super+D` rofi bind instead.
  simpleBar = monitorName: {
    monitor = monitorName;
    left = [
      "dashboard"
      "hyprland-workspaces"
    ];
    center = [ "media" ];
    right = [
      "volume"
      "systray"
      "notifications"
    ];
  };

  mainBar = monitorName: {
    monitor = monitorName;
    left = [
      "dashboard"
      "hyprland-workspaces"
      "window-title"
    ];
    center = [ "media" ];
    right = [
      "volume"
      "network"
      "bluetooth"
    ]
    ++ lib.optional isLaptop "battery"
    ++ [
      "systray"
      "clock"
      "notifications"
    ];
  };

  # A monitor gets the full bar if it is the primary output or is explicitly
  # flagged `mainBar` (e.g. the docked external display). HyprPanel keyed this off
  # `primary` alone, leaving the host's `mainBar` flag dangling; wayle honours both.
  barFor =
    monitorName: monitorConfig:
    if monitorConfig.primary || monitorConfig.mainBar then
      mainBar monitorName
    else
      simpleBar monitorName;

  # wayle addresses monitors by connector name only — unlike Hyprland it has no
  # EDID/description matcher. Outputs whose connector name is unstable (the Dell,
  # which re-enumerates as DP-3/DP-5/DP-6/... depending on how it is docked) are
  # identified by `description` instead, so they cannot be named here at all.
  # They take wayle's "*" layout, which applies to every monitor without an
  # explicit entry; the stably-named outputs each get their own entry and so win
  # over the fallback.
  #
  # TODO: only one description-matched monitor is expressible, since they would
  # all collapse onto the single "*" layout. Fine while the Dell is the only one;
  # revisit if wayle grows description matching.
  namedMonitors = lib.filter (m: m.description == "") monitors;
  unnamedMonitors = lib.filter (m: m.description != "") monitors;

  barLayouts =
    map (m: barFor m.name m) namedMonitors ++ map (m: barFor "*" m) (lib.take 1 unnamedMonitors);

  # ==============================================================================
  # Theme (Catppuccin Mocha, mauve accent)
  # ==============================================================================
  #
  # HyprPanel shipped Catppuccin theme JSON we merged in. wayle has no Catppuccin
  # theme-provider, so we set theme-provider = "wayle" and hand the mocha palette
  # to `styling.palette`. Accent (`primary`) is mauve to match the previous
  # mocha-mauve look. Hexes from https://catppuccin.com/palette (Mocha).
  mochaPalette = {
    bg = "#1e1e2e"; # base
    surface = "#313244"; # surface0
    elevated = "#45475a"; # surface1
    fg = "#cdd6f4"; # text
    "fg-muted" = "#a6adc8"; # subtext0
    primary = "#cba6f7"; # mauve (accent)
    red = "#f38ba8";
    yellow = "#f9e2af";
    green = "#a6e3a1";
    blue = "#89b4fa";
  };

in
{
  services.wayle = {
    package = pkgs.wayle;
    enable = true;
    # Full field reference: https://wayle.app/config
    # Live-reloads on save; start from empty and only override what you want.
    settings = {
      styling = {
        "theme-provider" = "wayle";
        palette = mochaPalette;
      };

      bar = {
        # HyprPanel had theme.bar.scaling = 75 (percent); wayle's scale is a
        # multiplier. `scalingPriority = "hyprland"` has no wayle analogue.
        scale = 0.75;
        location = "top";
        layout = barLayouts;
      };

      modules = {
        # HyprPanel: workspaces { monitorSpecific; show_numbered; show_icons }.
        "hyprland-workspaces" = {
          "monitor-specific" = true;
          numbering = "absolute"; # was show_numbered = true
          "app-icons-show" = false; # was show_icons = false
          # HyprPanel hid the special ghostty scratchpad via ignored = "-.*".
          # wayle has a dedicated switch for it: special workspaces (negative
          # ids, here special:term-ws = -98) are shown by default.
          "show-special" = false;
        };

        # HyprPanel clock menu: military = false (12h), hideSeconds = true.
        clock = {
          format = "%I:%M %p";
          "dropdown-show-seconds" = false;
        };

        # HyprPanel weather lived inside the clock menu and used a weatherapi.com
        # key from an agenix secret. wayle's open-meteo provider is keyless, so
        # the secret is gone (see hyprland/default.nix). Right-click the clock
        # opens this weather dropdown.
        weather = {
          provider = "open-meteo";
          location = "Washington DC";
          units = "imperial"; # TODO: confirm wayle's unit enum value for °F
        };
      };
    };
  };

  # ==============================================================================
  # Start ordering: bind to hyprland-session.target, not graphical-session.target
  # ==============================================================================
  #
  # wayle's home-manager module is compositor-agnostic, so it wires the unit to
  # `graphical-session.target` and gates it on `ConditionEnvironment=WAYLAND_DISPLAY`.
  # On this systemd user session, graphical-session.target is reached during normal
  # login (Main User Target -> HM tray/X-session targets) BEFORE Hyprland exports
  # WAYLAND_DISPLAY. So at boot the unit is pulled in, finds the env var missing,
  # and is *skipped* — and a skipped condition is never re-evaluated. Hyprland only
  # runs `dbus-update-activation-environment ... && start hyprland-session.target`
  # ~4s later (hyprland.start event), by which point it's too late.
  #
  # hyprland-session.target is reached *after* that env import, so pulling wayle from
  # it (like waybar/hyprlock/swaylock/hyprpaper do here) means WAYLAND_DISPLAY is
  # present when the condition is checked. Install.WantedBy is the one that controls
  # *when* the unit is pulled, so it must move too — mkForce because the module's
  # `[ "graphical-session.target" ]` would otherwise merge and keep the early pull.
  systemd.user.services.wayle = {
    Unit.After = lib.mkForce [ "hyprland-session.target" ];
    Unit.PartOf = lib.mkForce [ "hyprland-session.target" ];
    Install.WantedBy = lib.mkForce [ "hyprland-session.target" ];
  };
}
