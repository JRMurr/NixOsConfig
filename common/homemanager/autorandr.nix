{ pkgs, lib, config, nixosConfig, ... }:
with lib;
let
  gcfg = nixosConfig.myOptions.graphics;
  monitors = gcfg.monitors;
  monitorsByName = attrsets.mapAttrs (name: value: head value)
    (lists.groupBy (x: x.name) monitors);

  # monitor values to autorander config values
  monitorConfigMap = config: {
    enable = config.enable;
    primary = config.primary;
    position = config.position;
    mode = config.resolution;
    rate = config.rate;
    rotate = config.rotate;
  };
in {
  config = lib.mkIf gcfg.enable {
    programs.autorandr = {
      enable = true;
      profiles = {
        "normal" = {
          fingerprint =
            attrsets.mapAttrs (name: value: value.fingerprint) monitorsByName;
          config = attrsets.mapAttrs (name: value: monitorConfigMap value)
            monitorsByName;
        };
      };
    };
  };
}

