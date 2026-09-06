# Binary cache for the tailnet, replacing the old attic setup.
#
# Harmonia serves this machine's own /nix/store, so there is no push step:
# whatever the nightly job below builds is immediately available to the other
# hosts. Caddy fronts it at cache.jrnet.win (see caddy/reverse-proxies.nix).
#
# The same nightly job bumps flake.lock. It only pushes an update that still
# evaluates on every cached host, so a broken nixpkgs bump never reaches the
# laptops, and the run that accepts an update also warms the cache with the
# closure those laptops will pull.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  # wsl is deliberately absent: it does not evaluate on its own (see SESSION.md),
  # so gating updates on it would block every update forever.
  cachedHosts = [
    "framework"
    "desktop"
    "thicc-server"
    "graphicalIso"
  ];

  # `secrets` is a private repo, bumped deliberately via ./updateSecrets.sh, and
  # auto-updating it would need a second read-only credential. `self` is not a
  # real input and `nix flake update` rejects it.
  updatableInputs = lib.subtractLists [ "self" "secrets" ] (builtins.attrNames inputs);

  # Fetched over https so a missing or broken deploy key costs us only the
  # push, never the nightly build. Pushes go over ssh using the agenix key.
  repoUrlFetch = "https://github.com/JRMurr/NixOsConfig";
  repoUrlPush = "git@github.com:JRMurr/NixOsConfig.git";

  stateDir = "/var/lib/nix-cache-build";
  checkoutDir = "${stateDir}/repo";
  updateLog = "${stateDir}/flake-update.log";

  # Every build gets an --out-link here, which nix registers as an indirect GC
  # root. Without this, `nh clean` reclaims the closures and the cache empties.
  gcrootDir = "${stateDir}/gcroots";

  # Lower is preferred. cache.nixos.org is 40, so ours wins.
  cachePriority = 30;

  flakeRef = host: "${checkoutDir}#nixosConfigurations.${host}.config.system.build.toplevel";

  # Cheap gate. Catches most of what a bad bump does -- renamed options, dropped
  # packages, module type errors -- in seconds rather than hours of building.
  evalHost = host: ''
    if ! nix eval --raw "${flakeRef host}.drvPath" > /dev/null; then
      echo "EVAL FAILED: ${host}" >&2
      evalOk=0
    fi
  '';

  # --keep-going: one broken derivation shouldn't cost us the whole host's worth
  # of cacheable paths. Everything not depending on the failure still gets built,
  # and nix still exits non-zero so the host is reported as failed.
  buildHost = host: ''
    echo "==> ${host}"
    if ! nix build --keep-going --out-link "${gcrootDir}/${host}" "${flakeRef host}"; then
      echo "FAILED: ${host}" >&2
      failed=1
    fi
  '';

  updatePhase = ''
    lockBefore=$(sha256sum flake.lock)

    echo "==> updating flake inputs"
    nix flake update ${lib.concatStringsSep " " updatableInputs} 2>&1 | tee ${updateLog} || true

    if [ "$(sha256sum flake.lock)" = "$lockBefore" ]; then
      echo "flake.lock unchanged, nothing to push"
    else
      evalOk=1
      ${lib.concatMapStringsSep "\n" evalHost cachedHosts}

      if [ "$evalOk" = 1 ]; then
        git commit -q flake.lock \
          -m "flake.lock: automated update" \
          -m "$(grep '^•' ${updateLog} || true)"
        git push origin HEAD:main
        echo "pushed flake.lock update"
      else
        echo "eval gate failed, keeping the previous lock" >&2
        git checkout -- flake.lock
      fi
    fi
  '';
in
{
  age.secrets = {
    harmonia-key.file = "${inputs.secrets}/secrets/harmonia-key.age";
    # Write access to NixOsConfig, used only to push the nightly flake.lock bump.
    nixos-config-deploy-key.file = "${inputs.secrets}/secrets/nixos-config-deploy-key.age";
  };

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
      GIT_SSH_COMMAND = "ssh -i ${config.age.secrets.nixos-config-deploy-key.path} -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new";
    };

    script = ''
      set -eu

      rm -rf ${checkoutDir}
      git clone ${repoUrlFetch} ${checkoutDir}
      cd ${checkoutDir}
      git remote set-url --push origin ${repoUrlPush}
      git config user.name "thicc-server"
      git config user.email "nix-cache-build@thicc-server"

      mkdir -p ${gcrootDir}

      ${updatePhase}

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
