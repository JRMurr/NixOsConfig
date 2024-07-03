{ config, pkgs, lib, inputs, ... }:
let
  cfg = config.myCaddy;
  reverseProxies = lib.attrValues cfg.reverseProxies;
  myDomain = cfg.domain;
  tlsConf = ''
    tls {
      dns cloudflare {env.CF_API_TOKEN}
      resolvers 1.1.1.1
    }
  '';
  # builtins.listToAttrs
  mkReverseProxyConf = proxyConf:
    let mkHost = (name: "${name}.${myDomain}");
    in {
      name = mkHost proxyConf.prefix;
      value = {
        serverAliases = builtins.map mkHost proxyConf.serverAliases;
        extraConfig = ''
          ${tlsConf}
          ${proxyConf.extraConfig}
          reverse_proxy ${proxyConf.upstream} {
            ${proxyConf.proxyOptions}
          }
        '';
      };
    };

  reverseProxyVhosts =
    builtins.listToAttrs (builtins.map mkReverseProxyConf reverseProxies);

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
    # {
    #   # this might not be working...
    #   external_path_prefix = "/s3"; # minio
    #   redirect_path = "fatnas:7000";
    # }
    # {
    #   external_path_prefix = "/iris";
    #   redirect_path = "thicc-server:6680/iris";
    # }
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
in {
  imports = [ ./options.nix ./reverse-proxies.nix ];
  services.tailscale.permitCertUid = "caddy";
  services.caddy = {
    enable = true;
    email = "johnreillymurray@gmail.com";
    package = pkgs.caddyWithPlugins.override (prev: {
      plugins = [{ name = "github.com/caddy-dns/cloudflare"; }];
      vendorHash = "sha256-IkK9aUaVoKXpY4S34b1tO8fhnn1wwXsPeavVuYCwiYo=";
    });
    logFormat = lib.mkForce "level info";
    virtualHosts = let
    in {
      "${myDomain}" = {
        extraConfig = ''
          ${tlsConf}
          ${proxyConfigStr}
          reverse_proxy :4000 # default to dashy
        '';
      };
    } // reverseProxyVhosts;
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
  networking.firewall.allowedUDPPorts = [ 80 443 ];
}
