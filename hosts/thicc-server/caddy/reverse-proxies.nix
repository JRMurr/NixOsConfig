{ config, lib, ... }: {
  myCaddy.reverseProxies = {
    # s3 = { upstream = "fatnas:7000"; };
    music = { upstream = "thicc-server:6680"; };
    pihole = {
      upstream = "thicc-server:81";
      extraConfig = "redir / /admin{uri}";
    };
    cache = {
      upstream = "thicc-server:8080";
      proxyOptions = ''
        header_up Host caddy
      '';
    };
    deluge = {
      upstream = "thicc-server:8080";
      proxyOptions = ''
        header_up X-Frame-Options SAMEORIGIN
      '';
    };
    nas = { upstream = "fatnas:5000"; };
  };
}
