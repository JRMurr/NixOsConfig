{ pkgs, lib, config, nixosConfig, ... }:
# TODO: switch this to services.autorandr on unstable / nix 22.05 version. That will enable the serivce so autorandr SHOULD detect monitor change events
with lib;
let
  gcfg = nixosConfig.myOptions.graphics;
  monitors = gcfg.monitors;
  monitorsByName =
    attrsets.mapAttrs (_: head) (lists.groupBy (x: x.name) monitors);

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

