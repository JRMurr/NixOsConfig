{ config, pkgs, lib, inputs, ... }:
let
  tailscaleCfg = config.myOptions.tailscale;
  tailscaleHost = "${config.networking.hostName}.${tailscaleCfg.tailNetName}";

  toProxyConfig = { external_path_prefix, redirect_path
    , redirect_directives ? "", extra_directives ? "" }: ''
      handle_path ${external_path_prefix}* {
        ${extra_directives}
        reverse_proxy ${redirect_path} {
          ${redirect_directives}
        }
      }
    '';
  # TODO: make this an option
  proxyConfigs = [
    {
      external_path_prefix = "/nas/synology";
      redirect_path = "fatnas:5000";
    }
    {
      external_path_prefix = "/deluge";
      redirect_path = "fatnas:8112";
      # https://dev.deluge-torrent.org/wiki/UserGuide/WebUI/ReverseProxy
      redirect_directives = ''
        header_up X-Deluge-Base "/deluge/"
        header_up X-Frame-Options SAMEORIGIN
      '';
    }
    {
      external_path_prefix = "/attic";
      redirect_path = "thicc-server:8080";
      redirect_directives = ''
        header_up Host caddy
      '';
    }
    # {
    #   external_path_prefix = "/rss";
    #   redirect_path = "thicc-server:8282";
    #   # redirect_directives = ''
    #   #   header_up Host caddy
    #   # '';
    # }
    {
      # this might not be working...
      external_path_prefix = "/s3"; # minio
      redirect_path = "fatnas:7000";
    }
    {
      external_path_prefix = "/iris";
      redirect_path = "thicc-server:6680/iris";
    }
    # TODO: need to use subdomains for pihole to work https://docs.pi-hole.net/guides/webserver/caddy/
    # tailscale does not support multiple subdomains for a machine :(
    # {
    #   external_path_prefix =
    #     "/piHole"; 
    #   redirect_path = "localhost:81";
    #   extra_directives = ''
    #     rewrite * /admin{uri}
    #   '';
    # }
  ];

  proxyConfigStr = lib.concatMapStringsSep "\n" toProxyConfig proxyConfigs;

  myDomain = "jrnet.win";
in {
  services.tailscale.permitCertUid = "caddy";
  services.caddy = {
    enable = true;
    email = "johnreillymurray@gmail.com";
    package = pkgs.caddyWithPlugins.override (prev: {
      plugins = [{ name = "github.com/caddy-dns/cloudflare"; }];
      vendorHash = "sha256-mwIsWJYKuEZpOU38qZOG1LEh4QpK4EO0/8l4UGsroU8=";
    });
    logFormat = lib.mkForce "level info";
    virtualHosts = {
      # "${tailscaleHost}" = {
      #   extraConfig = ''
      #     ${proxyConfigStr}
      #     reverse_proxy :4000 # default to dashy
      #   '';
      # };

      # TOOD: need to buy a real domain to use that....
      # see https://caddyserver.com/docs/automatic-https#dns-challenge so i dont need to expose caddy externally
      "${myDomain}" = {
        extraConfig = ''
          tls {
            dns cloudflare {env.CF_API_TOKEN}
          }
          ${proxyConfigStr}
          reverse_proxy :4000 # default to dashy
        '';
      };
      "rss.${myDomain}" = {
        extraConfig = ''
          reverse_proxy :8282
        '';
      };
    };
  };
  systemd.services.caddy.serviceConfig = {
    EnvironmentFile = config.age.secrets.caddy-cloudflare.path;
    AmbientCapabilities = "CAP_NET_BIND_SERVICE";
  };
  age.secrets.caddy-cloudflare = {
    file = "${inputs.secrets}/secrets/caddy-cloudflare.age";
    owner = config.services.caddy.user;
    group = config.services.caddy.group;
  };
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
