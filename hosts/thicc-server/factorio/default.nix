{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  version = "2.1.12";

  # Both the server and the sync service below are pointed at this one path, so
  # neither relies on factorio's implicit `<write-data>/mods` default. It has to
  # live inside the state dir: DynamicUser implies ProtectSystem=strict, and
  # factorio needs to write mod-list.json/mod-settings.dat here.
  modDir = "/var/lib/${config.services.factorio.stateDirName}/mods";

  # ==============================================================================
  # Mod manifest
  # ==============================================================================
  #
  # Mods can't be fetched at build time: the mod portal only serves downloads to
  # an authenticated user, and any credential baked into a fixed-output
  # derivation's URL ends up world-readable in the nix store. So instead we pin
  # each mod's public metadata (version, download path, sha1) and let a systemd
  # oneshot do the authenticated fetch at runtime, verifying against that sha1.
  #
  # The pins live in JSON rather than in this file because `factorio-mod` rewrites
  # them — see mod-tool.py. Don't hand-edit unless you're removing something.
  #
  #   factorio-mod add https://mods.factorio.com/mod/even-distribution
  #   factorio-mod update
  #
  # Round-tripping through fromJSON turns a malformed manifest into an eval error
  # instead of a service failure at runtime.
  #
  # NOTE: the manifest has to be tracked by git — flake eval only sees files in
  # the git tree, so a fresh `git add` is required the first time.
  factorioMods = builtins.fromJSON (builtins.readFile ./mods.json);

  manifest = pkgs.writeText "factorio-mods.json" (builtins.toJSON factorioMods);

  # The game version the pins are resolved against: mods declare compatibility as
  # major.minor, so 2.1.12 means we want mods built for 2.1 or older.
  gameVersion = lib.versions.majorMinor version;

  # ==============================================================================
  # Mod sync
  # ==============================================================================
  #
  # Runs before factorio.service, downloading anything in the manifest that is
  # missing or whose on-disk hash doesn't match, and pruning zips that are no
  # longer listed. Anything already present with the right hash is left alone, so
  # a portal outage is a no-op rather than a failure.
  #
  # Written with writeShellApplication so shellcheck runs at build time.
  syncScript = pkgs.writeShellApplication {
    name = "factorio-mods-sync";
    runtimeInputs = with pkgs; [
      curl
      jq
      coreutils
    ];
    text = ''
      # FACTORIO_USER / FACTORIO_TOKEN come from the agenix EnvironmentFile.
      # shellcheck disable=SC2154

      MODS_DIR="${modDir}"
      mkdir -p "$MODS_DIR"

      # Fetch anything missing or corrupt. Reading via process substitution (not a
      # pipe) keeps the loop in the main shell so `exit` actually aborts the run.
      while read -r mod; do
        name=$(jq -r .name <<<"$mod")
        version=$(jq -r .version <<<"$mod")
        downloadPath=$(jq -r .downloadPath <<<"$mod")
        sha1=$(jq -r .sha1 <<<"$mod")
        zip="''${name}_''${version}.zip"
        target="$MODS_DIR/$zip"

        if [[ -f "$target" ]] && sha1sum -c --status - <<<"$sha1  $target"; then
          continue
        fi

        echo "fetching $zip"
        # Stage inside MODS_DIR so the final `mv` is atomic (same filesystem).
        tmp=$(mktemp "$MODS_DIR/.$zip.XXXXXX")
        # shellcheck disable=SC2064
        trap "rm -f '$tmp'" EXIT

        # Only the credentialed URL goes through the config file on stdin, so the
        # token never shows up in `ps` output; printf is a bash builtin, so it
        # doesn't leak it either. Everything else stays on the command line where
        # it's readable.
        #
        # --retry-all-errors is the load-bearing flag: the portal drops
        # connections mid-handshake often enough to fail a run, and plain --retry
        # doesn't cover TLS errors (curl only treats timeouts and 5xx as
        # transient). A genuinely bad token still fails, just 5 attempts later.
        printf 'url = "%s"\n' \
          "https://mods.factorio.com''${downloadPath}?username=''${FACTORIO_USER}&token=''${FACTORIO_TOKEN}" \
          | curl --config - --output "$tmp" \
              --silent --show-error --fail --location \
              --retry 5 --retry-delay 3 --retry-all-errors --retry-connrefused

        if ! sha1sum -c --status - <<<"$sha1  $tmp"; then
          echo "hash mismatch for $zip" >&2
          exit 1
        fi
        chmod 0644 "$tmp"
        mv "$tmp" "$target"
        trap - EXIT
      done < <(jq -c '.[]' ${manifest})

      # Prune zips that are no longer in the manifest. Factorio tolerates the stale
      # mod-list.json entries this leaves behind.
      shopt -s nullglob
      for f in "$MODS_DIR"/*.zip; do
        base=$(basename "$f")
        if ! jq -e --arg z "$base" 'any(.[]; "\(.name)_\(.version).zip" == $z)' ${manifest} >/dev/null; then
          echo "pruning $base"
          rm -f "$f"
        fi
      done
    '';
  };

  # ==============================================================================
  # Manifest tooling
  # ==============================================================================
  #
  # `factorio-mod` resolves mods (and their required dependencies) against the
  # portal API and rewrites mods.json. The wrapper supplies the game
  # version so it tracks the pinned server rather than being restated in the
  # script; FACTORIO_MODS_FILE can be overridden to point at another checkout.
  modTool =
    let
      unwrapped = pkgs.writers.writePython3Bin "factorio-mod" {
        # The portal API and dependency-syntax comments run past 79 columns.
        flakeIgnore = [ "E501" ];
      } (builtins.readFile ./mod-tool.py);
    in
    pkgs.runCommandLocal "factorio-mod" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
      makeWrapper ${unwrapped}/bin/factorio-mod $out/bin/factorio-mod \
        --set-default FACTORIO_GAME_VERSION ${gameVersion}
    '';
in
{
  # Contents:
  #   FACTORIO_USER=...
  #   FACTORIO_TOKEN=...      # from https://factorio.com/profile
  age.secrets.factorio-portal-creds.file = "${inputs.secrets}/secrets/factorio-portal-creds.age";

  services.factorio = {
    package = pkgs.factorio-headless-experimental.overrideAttrs (old: rec {
      src = pkgs.fetchurl {
        name = "factorio-headless_linux_${version}.tar.xz";
        url = "https://factorio.com/get-download/${version}/headless/linux64";
        sha256 = "sha256-iF/wKaQLDt2BXP4fwThF8jJyPaHqj+moPq4RTR7M0/4"; #lib.fakeHash;
      };
    });
    enable = true;
    openFirewall = true;
    port = 7654;
    public = false;
    game-password = "fartbois";
    admins = [ "fatattack" ];
    saveName = "ffff";
    # Must stay empty. A non-empty list makes the module emit its own
    # --mod-directory=<store path>, and since extraArgs is appended after it we'd
    # be passing the flag twice and relying on which one factorio honors.
    mods = [ ];
    extraArgs = [ "--mod-directory=${modDir}" ];
  };

  # Pick up mod changes on switch rather than waiting for the next restart.
  systemd.services.factorio.restartTriggers = [ manifest ];

  systemd.services.factorio-mods-sync = {
    description = "Sync Factorio mods from the pinned manifest";
    requiredBy = [ "factorio.service" ];
    before = [ "factorio.service" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe syncScript;

      # factorio.service uses DynamicUser with no explicit User=, so its transient
      # user is named after the unit. Naming the user "factorio" here gets us the
      # *same* allocated uid and therefore the same /var/lib/private/factorio, so
      # the mods land in the state dir already owned by the server.
      DynamicUser = true;
      User = "factorio";
      StateDirectory = "factorio";
      UMask = "0007";

      # Read by PID 1 before privileges are dropped, which is what makes a
      # root-only agenix secret usable from a DynamicUser service.
      EnvironmentFile = config.age.secrets.factorio-portal-creds.path;
    };
  };

  environment.systemPackages = [ modTool ];
}
