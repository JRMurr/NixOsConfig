# Push notifications, mainly so a failed nightly cache build reaches a phone
# instead of sitting in `systemctl status` until someone thinks to look.
#
# Deliberately the only service here that is NOT gated to the tailnet: a push
# is worthless if it only arrives when you are already home. Access control is
# therefore ntfy's own, not Caddy's -- `auth-default-access = "deny-all"` means
# every read and write needs a token, including the local publisher below.
{
  config,
  pkgs,
  ...
}:
let
  port = 2586;
  domain = "ntfy.${config.myCaddy.domain}";
  topic = "thicc-server";

  # Published over loopback rather than through Caddy: the alert most worth
  # receiving is the one where DNS or the reverse proxy is what broke.
  publishUrl = "http://127.0.0.1:${toString port}/${topic}";

  # ntfy drops messages over 4096 bytes, and a failing nix build produces far
  # more than that.
  maxBodyBytes = 3500;
  bodyLines = 10;

  termUrl = "https://term.${config.myCaddy.domain}";
  commitsUrl = "https://github.com/JRMurr/NixOsConfig/commits/main";

  # Bootstrap, once, after the first deploy. All of it needs root: the module
  # runs ntfy with DynamicUser, so the auth db is really under /var/lib/private,
  # which is 0700 root. Running these unprivileged reports the db as missing
  # rather than as unreadable.
  #   sudo ntfy user add --role=user phone   # what the Android app logs in as
  #   sudo ntfy access phone thicc-server rw
  #   sudo ntfy user add --role=user publisher
  #   sudo ntfy access publisher thicc-server wo
  #   sudo sh -c 'umask 077; ntfy token add publisher \
  #     | grep -oE "tk_[-_A-Za-z0-9]{29}" > /var/lib/ntfy-publish-token'
  tokenFile = "/var/lib/ntfy-publish-token";
in
{
  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "https://${domain}";
      listen-http = "127.0.0.1:${toString port}";
      behind-proxy = true;
      auth-default-access = "deny-all";
    };
  };

  myCaddy.reverseProxies.ntfy = {
    upstream = "127.0.0.1:${toString port}";
  };

  # Attach to any unit with `onFailure = [ "notify-failure@<unit>.service" ]`.
  # TODO: promote to common/myOptions if a second host ever needs it; today
  # only thicc-server can reach the publish endpoint over loopback.
  systemd.services."notify-failure@" = {
    description = "Push an ntfy alert for failed unit %i";

    path = [
      pkgs.curl
      pkgs.systemd
    ];

    serviceConfig = {
      Type = "oneshot";
      # Fails loudly at unit start if the bootstrap above was never run, rather
      # than silently publishing unauthenticated.
      LoadCredential = "token:${tokenFile}";
    };

    scriptArgs = "%i";
    script = ''
      unit="$1"

      # Scoped to the run that just failed, not the tail of the journal, which
      # would otherwise mix in the previous run.
      log=$(journalctl -u "$unit" --invocation=-0 --no-pager -o cat)

      # Lead with the lines naming what broke. nix-cache-build prints its own
      # FAILED:/EVAL FAILED: markers, so the notification opens with the host
      # that broke instead of a screenful of `building '/nix/store/...'`. Any
      # other unit has no markers and falls back to the tail.
      body=$(printf '%s\n' "$log" | grep -E '^(EVAL )?FAILED:|^error:' | head -n ${toString bodyLines})
      body="''${body:-$(printf '%s\n' "$log" | tail -n ${toString bodyLines})}"
      body=$(printf '%s' "''${body:-(no journal output)}" | tail -c ${toString maxBodyBytes})

      curl -sS --fail-with-body \
        -H "Authorization: Bearer $(cat "$CREDENTIALS_DIRECTORY/token")" \
        -H "Title: $unit failed on thicc-server" \
        -H "Priority: high" \
        -H "Tags: rotating_light" \
        -H "Actions: view, Terminal, ${termUrl}; view, Commits, ${commitsUrl}" \
        -d "$body" \
        ${publishUrl}
    '';
  };
}
