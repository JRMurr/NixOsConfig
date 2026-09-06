{ config, lib, ... }:
{
  myCaddy.reverseProxies = {
    # s3 = { upstream = "fatnas:7000"; };
    music = {
      upstream = "thicc-server:6680";
    };
    komga = {
      upstream = "fatnas:25600";
    };
    pihole = {
      upstream = "thicc-server:81";
      extraConfig = "redir / /admin{uri}";
    };
    # Nix binary cache (harmonia). Kept off the public internet: the store path
    # names alone would expose every package and version on the server.
    cache = {
      upstream = "127.0.0.1:5000";
      # private_ranges covers RFC1918 and fd00::/8, which is what tailscale
      # (fd7a:115c:a1e0::/48) and the LAN use for v6. Listing only v4 subnets
      # here 403s any client that happens to prefer AAAA. 100.64.0.0/10 is
      # tailscale's v4 CGNAT range and is not part of private_ranges.
      extraConfig = ''
        @blocked not remote_ip private_ranges 100.64.0.0/10
        respond @blocked "Forbidden" 403
      '';
    };
    deluge = {
      upstream = "fatnas:8112";
      proxyOptions = ''
        header_up X-Frame-Options SAMEORIGIN
      '';
    };
    nas = {
      upstream = "fatnas:5000";
    };
  };
}
