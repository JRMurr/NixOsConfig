# Browser terminal, so a 3am "nightly build failed" push can be acted on from a
# phone without a laptop.
#
# Three independent layers stand in front of a root shell, because that is what
# this ultimately is:
#   1. Caddy refuses anything that is not tailnet or LAN (same gate as `cache`).
#   2. HTTP basic auth.
#   3. ttyd's default entrypoint is `login`, so PAM asks for a unix password too.
# Layer 3 is why `user` is left at root -- `login` needs it, and it means a
# leaked basic-auth password alone does not yield a shell.
{
  config,
  inputs,
  ...
}:
let
  port = 7681;
in
{
  age.secrets.ttyd-password.file = "${inputs.secrets}/secrets/ttyd-password.age";

  services.ttyd = {
    enable = true;
    inherit port;

    # Caddy is the only thing that should reach this.
    interface = "lo";

    username = "jr";
    passwordFile = config.age.secrets.ttyd-password.path;

    writeable = true;

    # Passes `--check-origin`, which *rejects* cross-origin websocket upgrades.
    # The NixOS option description has this backwards.
    checkOrigin = true;

    # xterm.js defaults to a size that is unreadable on a phone.
    clientOptions.fontSize = "16";
  };

  # Once logged in, `tmux new -A -s phone` is worth the habit: mobile networks
  # drop the websocket constantly and tmux is what makes that survivable.
  myCaddy.reverseProxies.term = {
    upstream = "127.0.0.1:${toString port}";
    # Mirrors the `cache` gate: private_ranges covers RFC1918 and fd00::/8,
    # 100.64.0.0/10 is tailscale's CGNAT range.
    extraConfig = ''
      @blocked not remote_ip private_ranges 100.64.0.0/10
      respond @blocked "Forbidden" 403
    '';
  };
}
