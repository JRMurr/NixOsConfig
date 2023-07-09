{ config, pkgs, lib, ... }:
let
  tailscaleCfg = config.myOptions.tailscale;
  tailscaleHost = "${config.networking.hostName}.${tailscaleCfg.tailNetName}";

  toProxyConfig =
    { external_path_prefix, redirect_path, extra_directives ? "" }: ''
      handle_path ${external_path_prefix}* {
        ${extra_directives}
        reverse_proxy ${redirect_path}
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
    }
    {
      external_path_prefix =
        "/piHole"; # TODO figure out different subdomains instead https://caddy.community/t/reverse-proxy-into-docker-container-sub-path/9232/4
      redirect_path = "localhost:81";
      extra_directives = ''
        rewrite * /admin{uri}
      '';
    }
  ];

  proxyConfigStr = lib.concatMapStringsSep "\n" toProxyConfig proxyConfigs;
in {
  services.tailscale.permitCertUid = "caddy";
  services.caddy = {
    enable = true;
    logFormat = lib.mkForce "level info";
    #       #   reverse_proxy :4000
    # rewrite * /api{uri}
    virtualHosts."${tailscaleHost}" = {
      extraConfig = ''
        ${proxyConfigStr}
        reverse_proxy :4000 # default to dashy
      '';
    };
  };
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
