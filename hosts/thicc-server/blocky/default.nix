{ config, pkgs, ... }:
let
  port = config.services.blocky.settings.ports.http;

in
{
  # https://nixos.wiki/wiki/Blocky
  # https://github.com/JayRovacsek/nix-config/blob/878d57de91dc28440ff5635fd70f23fbe9342cfa/modules/blocky/default.nix
  networking.firewall =
    let
      inherit (config.services.blocky.settings.ports) dns tls http;
    in
    {
      allowedTCPPorts = [
        dns
        tls
        http
      ];
      allowedUDPPorts = [ dns ];
    };
  services.blocky = {
    enable = true;
    #
    # SEE ALSO: https://0xerr0r.github.io/blocky/latest/configuration/#logging-configuration
    #
    settings = {
      ports = {
        # optional: DNS listener port(s) and bind ip address(es), default 53 (UDP and TCP). Example: 53, :53, "127.0.0.1:5353,[::1]:5353"
        dns = 53;
        # optional: Port(s) and bind ip address(es) for DoT (DNS-over-TLS) listener. Example: 853, 127.0.0.1:853
        tls = 853;
        # optional: Port(s) and optional bind ip address(es) to serve HTTPS used for prometheus metrics, pprof, REST API, DoH... If you wish to specify a specific IP, you can do so such as 192.168.0.1:443. Example: 443, :443, 127.0.0.1:443,[::1]:443
        # https = 443;
        # optional: Port(s) and optional bind ip address(es) to serve HTTP used for prometheus metrics, pprof, REST API, DoH... If you wish to specify a specific IP, you can do so such as 192.168.0.1:4000. Example: 4000, :4000, 127.0.0.1:4000,[::1]:4000
        http = 3050;
      };
      upstreams.groups.default = [
        "https://one.one.one.one/dns-query" # Using Cloudflare's DNS over HTTPS server for resolving queries.
        "https://dns.google/dns-query"
      ];
      # For initially solving DoH/DoT Requests when no system Resolver is available.
      bootstrapDns = {
        upstream = "https://one.one.one.one/dns-query";
        ips = [
          "1.1.1.1"
          "1.0.0.1"
        ];
      };
      blocking = {
        blackLists = {
          #Adblocking
          ads = [ "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts" ];
        };
        whiteLists = {
          ads = [ ./whitelist.txt ];
        };
        # definition: which groups should be applied for which client
        clientGroupsBlock = {
          # default will be used, if no special definition for a client name exists
          default = [ "ads" ];
        };
      };

      clientLookup = {
        upstream = "192.168.50.1";
        singleNameOrder = [
          2
          1
        ];
      };
      customDNS = {
        mapping =
          let
            myDomain = config.myCaddy.domain;
          in
          {
            # TODO: figure out how to use local ip and tailscale
            "${myDomain}" = "100.95.204.122";
          };
      };

      # optional: configuration for prometheus metrics endpoint
      prometheus = {
        # enabled if true
        enable = true;
        # url path, optional (default '/metrics')
        path = "/metrics";
      };
    };
  };

  services.prometheus.scrapeConfigs = [
    {
      job_name = "blocky";
      static_configs = [ { targets = [ "127.0.0.1:${builtins.toString port}" ]; } ];
    }
  ];

  myCaddy.reverseProxies = {
    "blocky" = {
      upstream = "thicc-server:${builtins.toString port}";
    };
  };
}
