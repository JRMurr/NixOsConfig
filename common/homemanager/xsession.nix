{ pkgs, lib, config, nixosConfig, ... }:
let gcfg = nixosConfig.myOptions.graphics;
in {
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
