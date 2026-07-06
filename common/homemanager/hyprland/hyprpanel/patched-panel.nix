{ pkgs }:
let
  wrapTs = builtins.readFile ./patch_files/astal-file-write-wrap.ts;

  wrapImportPath = "src/lib/debug/astal_file_write_wrap";
  wrapDst = "src/lib/debug/astal_file_write_wrap.ts";

  configManagerPath = "src/lib/options/configManager/index.ts";

  # Hyprland 0.55's Lua config changes how `dispatch` is interpreted over the IPC
  # socket: the daemon wraps whatever follows `dispatch ` into `hl.dispatch(...)`
  # and evaluates it as Lua. HyprPanel (via AstalHyprland.dispatch) still sends the
  # legacy string `dispatch workspace N`, which becomes `hl.dispatch(workspace N)` —
  # a Lua syntax error — so clicking / scrolling workspaces on the bar silently
  # does nothing. There is no compat flag upstream (hyprwm/Hyprland discussion
  # #14255, "expected behavior"), so we rewrite the two workspace-switch call sites
  # to emit the typed dispatcher `hl.dsp.focus({ workspace = N })`. AstalHyprland
  # joins the two args as `dispatch <arg0> <arg1>`; we pass a single space as the
  # second arg (an empty '' would collide with Nix's '' string escaping here) and
  # the resulting trailing whitespace in the Lua expression is harmless.
  workspaceClickPath = "src/components/bar/modules/workspaces/workspaces.tsx";
  workspaceScrollPath = "src/services/workspace/index.ts";

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

        # Lua-mode workspace dispatch fix (see comment above). --replace-fail makes
        # a HyprPanel bump that renames these lines fail the build loudly rather
        # than silently reintroducing the broken bar clicks.
        substituteInPlace "${workspaceClickPath}" \
          --replace-fail \
            "hyprlandService.dispatch('workspace', wsId.toString());" \
            "hyprlandService.dispatch('hl.dsp.focus({ workspace = ' + wsId + ' })', ' ');"

        substituteInPlace "${workspaceScrollPath}" \
          --replace-fail \
            "hyprlandService.dispatch('workspace', targetWorkspaceNumber.toString());" \
            "hyprlandService.dispatch('hl.dsp.focus({ workspace = ' + targetWorkspaceNumber + ' })', ' ');"
      )
    '';

  });
in
patchedHyprpanel
