{ config, pkgs, lib, inputs, ... }:
let
  tailscaleCfg = config.myOptions.tailscale;
  tailscaleHost = "${config.networking.hostName}.${tailscaleCfg.tailNetName}";
  virtualHost = "freshrss";
in {
  age.secrets.freshrss-user-pass = {
    file = "${inputs.secrets}/secrets/freshrss-user-pass.age";
    mode = "770";
    owner = "freshrss";
    group = "freshrss";
  };

  services.freshrss = {
    enable = true;
    defaultUser = "jr";
    passwordFile = config.age.secrets.freshrss-user-pass.path;
    database = {
      host = "/var/lib/postgresql";
      type = "pgsql";
    };
    baseUrl = "https://${tailscaleHost}/rss";
    virtualHost = virtualHost;
  };
  services.postgresql = {
    ensureUsers = [{ name = "freshrss"; }];
    ensureDatabases = [ "freshrss" ];
  };

  services.nginx.defaultHTTPListenPort = 8282;
  # virtualHosts.${virtualHost}.listen = [{
  #   addr = "localhost";
  #   port = 8282;
  #   # ssl = false;
  # }];
}
