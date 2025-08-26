{
  pkgs,
  lib,
  nixosConfig,
  ...
}:
let

  gcfg = nixosConfig.myOptions.graphics;

in
{
  config = lib.mkIf gcfg.enable {
    services.hypridle = {
      enable = true;
      systemdTarget = "hyprland-session.target";
      settings = {
        general = {
          lock_cmd = "pidof hyprlock || hyprlock"; # avoid starting multiple hyprlock instances.
        };
        listener = {
          timeout = 900;
          on-timeout = "loginctl lock-session";
        };
      };
    };
    programs.hyprlock = {
      enable = true;

      settings = {
        general = {
          disable_loading_bar = true;
          grace = 300;
          hide_cursor = true;
          no_fade_in = false;
        };
      };
    };
  };
}
