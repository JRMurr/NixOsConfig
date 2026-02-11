{
  pkgs,
  lib,
  config,
  osConfig,
  ...
}:
let
  gcfg = osConfig.myOptions.graphics;
in
{
  config = lib.mkIf gcfg.enable {
    services.udiskie = {
      enable = true;
      tray = "always";
    };
    # services.dunst.enable = true;
    xsession = {
      enable = true;
      initExtra = "xset s off -dpms";
    };
  };
}
