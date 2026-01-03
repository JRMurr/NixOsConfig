{ pkgs }:
let
  wrapTs = builtins.readFile ./patch_files/astal-file-write-wrap.ts;

  wrapImportPath = "src/lib/debug/astal_file_write_wrap";
  wrapDst = "src/lib/debug/astal_file_write_wrap.ts";

  configManagerPath = "src/lib/options/configManager/index.ts";

  withCuda = pkgs.hyprpanel.override ({ enableCuda = true; });

  patchedHyprpanel = withCuda.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      (
        set -euo pipefail

        mkdir -p src/lib/debug
        cp ${pkgs.writeText "astal_file_write_wrap.ts" wrapTs} ${wrapDst}

        target="${configManagerPath}"
        if [ -f "$target" ]; then
          substituteInPlace "$target" \
            --replace-fail "from 'astal/file';" "from '${wrapImportPath}';"
        else
          echo "Expected file not found: $target" >&2
          exit 1
        fi

        test -f ${wrapDst}
        grep -q "from '${wrapImportPath}';" "$target"
      )
    '';

  });
in
patchedHyprpanel
