{
  config,
  pkgs,
  lib,
  nixosConfig,
  ...
}:
let
  gcfg = nixosConfig.myOptions.graphics;
  rCfg = nixosConfig.myOptions.redShift;
in
{
  config = lib.mkIf (gcfg.enable && !rCfg.disable) {
    # # https://nixos.wiki/wiki/Redshift

    services.redshift = {
      enable = true;
      provider = "manual";
      # u aint stealing my exact location from this
      latitude = 38.886383;
      longitude = -77.036322;
      # brightness = {
      #   day = "1";
      #   night = "1";
      # };
      temperature = {
        day = 5500;
        night = 3700;
      };
      tray = true;
    };
  };

}
