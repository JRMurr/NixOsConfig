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
      extraConfig = ''
        @blocked not remote_ip 100.64.0.0/10 192.168.50.0/24 127.0.0.1/32 ::1
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
