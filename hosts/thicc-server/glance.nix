{ config, pkgs, lib, ... }:
let
  cfg = config.services.glance;

  settings = {
    server = {
      host = cfg.host;
      port = cfg.port;
      assets-path = cfg.asset-path;
    };
  } // cfg.extraSettings;
  settingsString = builtins.toJSON (lib.filterAttrsRecursive (n: v: v != null) settings);
  settingsFile = pkgs.writeText "glance.yml" settingsString;
in
{
  options = {
    services.glance = with lib; {
      enable = mkEnableOption "Glance";
      package = mkPackageOption pkgs "glance" {
        example = "glance";
      };
      port = mkOption {
        type = types.port;
        default = 8080;
        description = ''
          The port to which the service should bind.
        '';
      };

      host = mkOption {
        type = types.str;
        default = "0.0.0.0";
        description = ''
          The address to which the service should bind.
        '';
      };

      asset-path = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = ''
          The path to a directory that will be served by the server under the /assets/ path.
          This is handy for widgets like the Monitor where you have to specify an icon URL and you want to self host all the icons rather than pointing to an external source.
        '';
      };

      extraSettings = mkOption {
        type = types.attrs;
        default = { };
        description = ''
          Extra glance options to be merged into the config
        '';
      };
    };
  };

  config = {
    systemd.services.glance = {
      serviceConfig = {
        Restart = "always";
        ExecStart = toString [
          "${cfg.package}/bin/glance"
          "--config=${settingsFile}"
        ];
      };
    };
  };


}
