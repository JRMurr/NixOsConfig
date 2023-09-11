_:
let port = 9001;
in {
  services.prometheus = {
    retentionTime = "15d";
    port = port;
    enable = true;
    # rules = [ ];
    # extraFlags = [ ];
    # globalConfig = { };
    # enableReload = true;
    # alertmanagers = [ ];
  };
  myCaddy.reverseProxies = {
    "prometheus" = { upstream = "thicc-server:${builtins.toString port}"; };
  };
}
