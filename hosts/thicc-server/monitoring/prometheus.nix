{ config, ... }:
let
  port = 9001;
in
{
  services.prometheus = {
    retentionTime = "15d";
    port = port;
    enable = true;
    # rules = [ ];
    # extraFlags = [ ];
    # globalConfig = { };
    # enableReload = true;
    # alertmanagers = [ ];

    # https://xeiaso.net/blog/prometheus-grafana-loki-nixos-2020-11-20
    exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = 9002;
      };
    };

    scrapeConfigs = [
      {
        job_name = "thicc-server";
        static_configs = [
          { targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ]; }
        ];
      }
    ];
  };

  services.grafana.provision.datasources.settings.datasources = [
    {
      name = "Prometheus";
      type = "prometheus";
      access = "proxy";
      url = "http://127.0.0.1:${toString config.services.prometheus.port}";
    }
  ];
  myCaddy.reverseProxies = {
    "prometheus" = {
      upstream = "thicc-server:${builtins.toString port}";
    };
  };
}
