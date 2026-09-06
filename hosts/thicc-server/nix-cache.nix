# Binary cache for the tailnet, replacing the old attic setup.
#
# Harmonia serves this machine's own /nix/store, so there is no push step:
# whatever `nix-cache-build` below builds is immediately available to the
# other hosts. Caddy fronts it at cache.jrnet.win (see caddy/reverse-proxies.nix).
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  # Hosts whose system closure is prebuilt nightly so the laptops and desktop
  # pull instead of compiling. graphicalIso is here so a rescue image is warm.
  cachedHosts = [
    "framework"
    "desktop"
    "thicc-server"
    "graphicalIso"
  ];

  repoUrl = "https://github.com/JRMurr/NixOsConfig";

  stateDir = "/var/lib/nix-cache-build";
  checkoutDir = "${stateDir}/repo";

  # Every build gets an --out-link here, which nix registers as an indirect GC
  # root. Without this, `nh clean` reclaims the closures and the cache empties.
  gcrootDir = "${stateDir}/gcroots";

  # Lower is preferred. cache.nixos.org is 40, so ours wins.
  cachePriority = 30;

  # --keep-going: one broken derivation shouldn't cost us the whole host's worth
  # of cacheable paths. Everything not depending on the failure still gets built,
  # and nix still exits non-zero so the host is reported as failed.
  buildHost = host: ''
    echo "==> ${host}"
    if ! nix build --keep-going --out-link "${gcrootDir}/${host}" \
      "${checkoutDir}#nixosConfigurations.${host}.config.system.build.toplevel"; then
      echo "FAILED: ${host}" >&2
      failed=1
    fi
  '';
in
{
  age.secrets.harmonia-key.file = "${inputs.secrets}/secrets/harmonia-key.age";

  services.harmonia.cache = {
    enable = true;
    # Loaded through systemd LoadCredential, which reads the file as root before
    # the unit drops to the harmonia user, so agenix's default 0400 root:root is fine.
    signKeyPaths = [ config.age.secrets.harmonia-key.path ];
    settings = {
      # Caddy is the only thing that should reach this directly.
      bind = "127.0.0.1:5000";
      priority = cachePriority;
    };
  };

  systemd.timers.nix-cache-build = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      RandomizedDelaySec = "30m";
      Persistent = true;
      Unit = "nix-cache-build.service";
    };
  };

  # sudo systemctl start nix-cache-build.service
  systemd.services.nix-cache-build = {
    path = [
      pkgs.git
      pkgs.openssh # the `secrets` flake input is fetched over ssh
      config.nix.package
    ];

    environment = {
      HOME = stateDir;
      XDG_CONFIG_HOME = "${stateDir}/config";
    };

    script = ''
      set -eu

      rm -rf ${checkoutDir}
      git clone --depth 1 ${repoUrl} ${checkoutDir}
      mkdir -p ${gcrootDir}

      failed=0
      ${lib.concatMapStringsSep "\n" buildHost cachedHosts}

      rm -rf ${checkoutDir}

      # Build every host even if one breaks, but still report failure so a
      # silently rotting cache shows up in `systemctl status`.
      exit $failed
    '';

    serviceConfig = {
      Type = "oneshot";
      StateDirectory = "nix-cache-build";
      WorkingDirectory = stateDir;
    };
  };
}
