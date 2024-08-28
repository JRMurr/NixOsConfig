{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  virtualHost = "rss.jrnet.win";

in
{
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
    baseUrl = "https://${virtualHost}";
    virtualHost = null;
  };

  services.postgresql = {
    ensureUsers = [
      {
        name = "freshrss";
        ensureDBOwnership = true;
        # ensurePermissions = {
        #   "DATABASE freshrss" = "ALL";
        #   "SCHEMA public" = "ALL";
        #   "ALL TABLES IN SCHEMA public" = "ALL";
        # };
      }
    ];
    ensureDatabases = [ "freshrss" ];
  };

  # https://github.com/jay-aye-see-kay/nixfiles/blob/0fa095fdc3a4e7a64a442c75b65f1e2c881fce13/hosts/pukeko/services.nix#L61
  services.caddy.virtualHosts."${virtualHost}" = {
    extraConfig = ''
      tls {
        dns cloudflare {env.CF_API_TOKEN}
        resolvers 1.1.1.1
      }
      root * ${pkgs.freshrss}/p 
      php_fastcgi unix/${config.services.phpfpm.pools.freshrss.socket} {
          env FRESHRSS_DATA_PATH ${config.services.freshrss.dataDir}
      }
      file_server
    '';
  };

  services.phpfpm.pools.freshrss.settings = {
    # use the provided phpfpm pool, but override permissions for caddy
    "listen.owner" = lib.mkForce "caddy";
    "listen.group" = lib.mkForce "caddy";
  };

  # services.nginx.defaultHTTPListenPort = 8282;
  # virtualHosts.${virtualHost}.listen = [{
  #   addr = "localhost";
  #   port = 8282;
  #   # ssl = false;
  # }];
}
