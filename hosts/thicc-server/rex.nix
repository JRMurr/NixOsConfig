# Rex server (beta). Module docs: the `rex` flake input's nixos-module.nix.
#
# Two ways in:
#   - rex.jrnet.win: Caddy -> Rex's Unix socket. Caddy can't hand Rex a
#     tailscale identity, so Caddy checks it instead via tailscale-nginx-auth
#     (whois on the client's tailnet address) and admits only `tailnetLogin`.
#   - thicc-server.<tailnet>.ts.net: Tailscale Serve, identified by Rex itself.
{ config, ... }:
let
  rexCfg = config.services.rex;
  authCfg = config.services.tailscaleAuth;

  tailnetLogin = "johnreillymurray@gmail.com";
in
{
  services.rex = {
    enable = true;

    # Sessions run as me, not a dedicated `rex` user.
    user = "jr";

    tailscaleServe.enable = true;

    webSocketOriginPatterns = [ "https://rex.${config.myCaddy.domain}" ];
  };

  services.tailscaleAuth.enable = true;

  # Rex's socket is 0660 in group `rex`; the auth socket likewise in its group.
  users.users.caddy.extraGroups = [
    rexCfg.group
    authCfg.group
  ];

  # forward_auth copies Tailscale-User from the auth response and strips
  # it from the request when absent, so clients can't spoof it. The auth
  # service already rejects non-tailnet and tagged callers.
  myCaddy.reverseProxies.rex = {
    upstream = "unix/${rexCfg.socketPath}";
    extraConfig = ''
      forward_auth unix/${authCfg.socketPath} {
        uri /auth
        header_up Remote-Addr {remote_host}
        header_up Remote-Port {remote_port}
        header_up Original-URI {uri}
        copy_headers Tailscale-User
      }

      @notMe not header Tailscale-User ${tailnetLogin}
      respond @notMe "Forbidden" 403
    '';
  };
}
