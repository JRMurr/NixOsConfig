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
  # the mods declaratively here (all public metadata) and let a systemd oneshot
  # do the authenticated fetch at runtime, verifying against the pinned sha1.
  #
  # `downloadPath` and `sha1` both come from the portal API. Generate a line with
  # the `factorio-mod-entry` helper installed below:
  #
  #   factorio-mod-entry flib
  #
  # NOTE: dependency resolution is not automatic. The helper prints each mod's
  # declared dependencies alongside the entry; any non-`base` dependency has to be
  # added to this list by hand.
  factorioMods = [
    # { name = "flib"; version = "0.17.2"; downloadPath = "/download/flib/6a3d4af12b2a85ea00e307a6"; sha1 = "6c7cedeefbdce89348d1e979a24e5706fd5a4311"; }
  ];

  manifest = pkgs.writeText "factorio-mods.json" (builtins.toJSON factorioMods);

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

        # The credentialed URL is fed to curl through a config file on stdin
        # rather than as an argument, so the token never shows up in `ps` output.
        # printf is a bash builtin, so it doesn't leak it either.
        printf 'silent\nshow-error\nfail\nlocation\nurl = "%s"\n' \
          "https://mods.factorio.com''${downloadPath}?username=''${FACTORIO_USER}&token=''${FACTORIO_TOKEN}" \
          | curl --config - --output "$tmp"

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

  # Prints a ready-to-paste `factorioMods` entry for the newest release of a mod
  # compatible with the given game version (default 2.1).
  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "factorio-mod-entry";
      runtimeInputs = with pkgs; [
        curl
        jq
      ];
      text = ''
        mod="$1"
        gameVersion="''${2:-2.1}"

        curl -sf "https://mods.factorio.com/api/mods/$mod/full" \
          | jq -r --arg m "$mod" --arg gv "$gameVersion" '
              def vnum: split(".") | map(tonumber);
              [.releases[] | select((.info_json.factorio_version | vnum) <= ($gv | vnum))] | last
              | if . == null then error("no release for factorio \($gv)") else . end
              | "{ name = \"\($m)\"; version = \"\(.version)\"; downloadPath = \"\(.download_url)\"; sha1 = \"\(.sha1)\"; }",
                "# dependencies: \(.info_json.dependencies // [] | join(", "))"
            '
      '';
    })
  ];
}
