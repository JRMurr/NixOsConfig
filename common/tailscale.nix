{
  config,
  pkgs,
  lib,
  ...
}:
let
  tailscaleCfg = config.myOptions.tailscale;
in
{
  config = lib.mkIf tailscaleCfg.enable {
    environment.systemPackages = [ pkgs.tailscale ];

    services.tailscale.enable = true;

    networking.firewall.checkReversePath = "loose";

    # Intentionally no `networking.nameservers`: tailscaled registers 100.100.100.100
    # with resolvconf itself. Listing it statically as well put quad100 in
    # tailscaled's own upstream set, so it forwarded queries to itself until the
    # forwarder queue filled ("dns udp query: request queue full") and every
    # stalled query fanned out to the remaining upstreams -- 1.1.1.1 and 8.8.8.8
    # get auto-upgraded to DoH, which is where the storm of TCP/443 connections
    # came from. DHCP still supplies a resolver when tailscaled is down.
    networking.search = [ "johnreillymurray.gmail.com.beta.tailscale.net" ];

  };
}
