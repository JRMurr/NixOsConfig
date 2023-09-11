{ config, ... }:
let
  myDomain = config.myCaddy.domain;
  grafanaDomain = "grafana.${myDomain}";
  port = 3030;
in {
  services.grafana = {
    enable = true;
    settings = {
      server = {
        # Listening Address
        http_addr = "0.0.0.0";
        # and Port
        http_port = port;
        # Grafana needs to know on which domain and URL it's running
        domain = grafanaDomain;
        # root_url = "https://${grafanaDomain}";
      };
    };
  };

  myCaddy.reverseProxies = {
    "grafana" = { upstream = "thicc-server:${builtins.toString port}"; };
  };
}
