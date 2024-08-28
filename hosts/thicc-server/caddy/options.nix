{ config, lib, ... }:
with lib;
let
  reverseProxyCfg = types.submodule (
    { name, config, ... }:
    {
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
        serverAliases = mkOption {
          type = with types; listOf str;
          default = [ ];
          example = [
            "rss"
            "freshrss"
          ];
          description = lib.mdDoc ''
            Additional names of virtual hosts served by this reverse proxy
          '';
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
    }
  );
in
{
  options.myCaddy = {
    domain = mkOption {
      type = types.str;
      description = "the domain to use";
      example = "jrnet.win";
      default = "jrnet.win";
    };
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
