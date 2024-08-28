{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
let
  gcfg = config.myOptions.graphics;
  monitors = gcfg.monitors;
  monitorsByName =
    # TODO: make  gcfg.monitors an attrsOf type so it can be an attrset and not a list
    attrsets.mapAttrs (_: head) (lists.groupBy (x: x.name) monitors);

  # monitor values to autorander config values
  monitorConfigMap = config: {
    enable = config.enable;
    primary = config.primary;
    position = config.position;
    mode = config.resolution;
    rate = config.rate;
    rotate = config.rotate;
    crtc = config.crtc;
    dpi = config.dpi;
    scale = config.scale;
  };
in
{
  config = lib.mkIf gcfg.enable {
    services.autorandr = {
      enable = true;
      defaultTarget = "normal";
      profiles = {
        "normal" = {
          fingerprint = attrsets.mapAttrs (name: value: value.fingerprint) monitorsByName;
          config = attrsets.mapAttrs (name: value: monitorConfigMap value) monitorsByName;
        };
      };
    };

    # hopefully run on init
    systemd.services.autorandr = {
      wantedBy = [ "graphical.target" ];
      after = [ "graphical.target" ];
    };
  };
}
