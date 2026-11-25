{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.myCaddy;
  reverseProxies = lib.attrValues cfg.reverseProxies;
  myDomain = cfg.domain;
  # builtins.listToAttrs
  mkReverseProxyConf =
    proxyConf:
    let
      mkHost = (name: "${name}.${myDomain}");
    in
    {
      name = mkHost proxyConf.prefix;
      value = {
        serverAliases = builtins.map mkHost proxyConf.serverAliases;
        useACMEHost = myDomain;
        extraConfig = ''
          ${proxyConf.extraConfig}
          reverse_proxy ${proxyConf.upstream} {
            ${proxyConf.proxyOptions}
          }
        '';
      };
    };

  reverseProxyVhosts = builtins.listToAttrs (builtins.map mkReverseProxyConf reverseProxies);

  toProxyConfig =
    {
      external_path_prefix,
      redirect_path,
      redirect_directives ? "",
      extra_directives ? "",
    }:
    ''
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
in
{
  imports = [
    ./options.nix
    ./reverse-proxies.nix
  ];
  services.tailscale.permitCertUid = "caddy";
  services.caddy = {
    enable = true;
    email = "johnreillymurray@gmail.com";
    logFormat = lib.mkForce "level info";
    virtualHosts =
      let
      in
      {
        "${myDomain}" = {
          useACMEHost = myDomain;
          extraConfig = ''
            ${proxyConfigStr}
            reverse_proxy :4000 # default to dashy
          '';
        };
      }
      // reverseProxyVhosts;
  };
  systemd.services.caddy.serviceConfig = {
    AmbientCapabilities = "CAP_NET_BIND_SERVICE";
  };

  # One wildcard cert issued by lego (in the binary cache), instead of caddy's
  # cloudflare DNS plugin, whose source hash broke on every caddy bump.
  security.acme = {
    acceptTerms = true;
    defaults.email = config.services.caddy.email;
    certs.${myDomain} = {
      extraDomainNames = [ "*.${myDomain}" ];
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1:53";
      environmentFile = config.age.secrets.caddy-cloudflare.path;
    };
  };

  # The secret holds CF_API_TOKEN, which lego does not read.
  systemd.services."acme-order-renew-${myDomain}".script = lib.mkBefore ''
    export CF_DNS_API_TOKEN="$CF_API_TOKEN"
  '';

  # Read by systemd as root via EnvironmentFile, so the default root owner works.
  age.secrets.caddy-cloudflare.file = "${inputs.secrets}/secrets/caddy-cloudflare.age";
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
  networking.firewall.allowedUDPPorts = [
    80
    443
  ];
}
