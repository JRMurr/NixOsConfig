{ config, lib, ... }:
with lib;
let
  reverseProxyCfg = types.submodule ({ name, config, ... }: {
    options = {
      enable = mkOption {
        type = types.bool;
        description = "Whether to enable this reverse proxy.";
        default = true;
      };
      prefix = mkOption {
        type = types.str;
        description = "url prefix for redirct, defaults to attr name";
        example = "cache";
        default = name;
      };
      upstream = mkOption {
        type = types.str;
        description = "where to redirct";
        example = "localhost:8080";
      };
      proxyOptions = mkOption {
        type = types.str;
        default = "";
        description = "options to set on the reverse_proxy";
        example = "header_up Host caddy";
      };
      extraConfig = mkOption {
        type = types.lines;
        default = "";
        example = ''
          redir / /admin{uri}
        '';
        description = lib.mdDoc ''
          Additional lines of configuration appended to the automatically
          generated `Caddyfile`.
        '';
      };
    };
  });
in {
  options.myCaddy = {
    reverseProxies = mkOption {
      type = with types; attrsOf reverseProxyCfg;
      default = { };
      example = literalExpression ''
        {
          "cache" = {
            upstream = "thicc-server:8080";
            extraConfig = '''
             header_up Host caddy
            ''';
          };
        };
      '';
    };
  };
}
