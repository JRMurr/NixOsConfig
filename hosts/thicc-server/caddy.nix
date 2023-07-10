{ config, pkgs, lib, ... }:
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
  services.tailscale.permitCertUid = "caddy";
  services.caddy = {
    enable = true;
    logFormat = lib.mkForce "level info";
    virtualHosts = {
      "${tailscaleHost}" = {
        extraConfig = ''
          ${proxyConfigStr}
          reverse_proxy :4000 # default to dashy
        '';
      };
    };
  };
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}