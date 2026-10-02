{ pkgs }:
{
  # Shell snippets, spliced into the script as-is; extra `jr switch`/`jr build`
  # arguments are appended.
  switchCmd,
  buildCmd,
  # Files to keep under /etc, relative path -> content. Installed as real files
  # rather than store links: some are read at boot before /nix is mounted.
  etc ? { },
}:
let
  etcTree = pkgs.linkFarm "jr-etc" (
    pkgs.lib.mapAttrsToList (path: text: {
      name = path;
      path = pkgs.writeText (baseNameOf path) text;
    }) etc
  );
in
pkgs.writeShellApplication {
  name = "jr";
  runtimeInputs = with pkgs; [
    coreutils
    diffutils
    findutils
  ];
  text = ''
    # JR_ROOT points /etc somewhere else, for tests: no sudo, no systemd.
    root="''${JR_ROOT:-/}"
    etc_dir="$root/etc"
    manifest="$etc_dir/jr/manifest"
    etc_tree=${etcTree}

    usage() {
      cat <<'USAGE'
    usage: jr <command> [args]

      switch [args]  build and activate this host, then sync /etc
      build [args]   build this host without activating it
      etc [--check]  sync the declared /etc files; --check only reports drift
    USAGE
    }

    managed_files() {
      find -L "$etc_tree" -type f -printf '%P\n' | sort
    }

    stale_files() {
      [[ -f "$manifest" ]] || return 0
      comm -23 <(sort "$manifest") <(managed_files)
    }

    # A symlink counts as drift even with the right content: its target may not
    # be mounted yet when the file is needed.
    is_current() {
      local path=$1
      [[ ! -L "$etc_dir/$path" ]] && cmp -s "$etc_tree/$path" "$etc_dir/$path"
    }

    etc_check() {
      local drift=0 path

      while read -r path; do
        is_current "$path" && continue
        echo "differs: /etc/$path"
        drift=1
      done < <(managed_files)

      while read -r path; do
        echo "stale: /etc/$path"
        drift=1
      done < <(stale_files)

      return "$drift"
    }

    etc_apply() {
      if [[ "$root" == / && $EUID -ne 0 ]]; then
        exec sudo "$(readlink -f "$0")" etc
      fi

      local changed=0 path
      local -a tmpfiles=()

      while read -r path; do
        is_current "$path" && continue

        # rm first: install would write through a symlink into the store.
        rm -f "$etc_dir/$path"
        install -D -m 0644 "$etc_tree/$path" "$etc_dir/$path"
        echo "installed /etc/$path"
        changed=1
        [[ "$path" == tmpfiles.d/* ]] && tmpfiles+=("$etc_dir/$path")
      done < <(managed_files)

      while read -r path; do
        rm -f "$etc_dir/$path"
        echo "removed /etc/$path"
        changed=1
      done < <(stale_files)

      mkdir -p "$(dirname "$manifest")"
      managed_files > "$manifest"

      if [[ "$changed" -eq 0 ]]; then
        echo "/etc up to date"
        return 0
      fi

      [[ "$root" == / ]] || return 0

      # Root the tree: the files reference store paths (GPU drivers) that must
      # outlive the home-manager generation that built them.
      ln -sfn "$etc_tree" /nix/var/nix/gcroots/jr-etc
      systemctl daemon-reload
      if [[ ''${#tmpfiles[@]} -gt 0 ]]; then
        systemd-tmpfiles --create "''${tmpfiles[@]}"
      fi
    }

    cmd_etc() {
      case "''${1:-}" in
        --check) etc_check ;;
        "") etc_apply ;;
        *) usage >&2; exit 2 ;;
      esac
    }

    cmd_switch() {
      ${switchCmd} "$@"

      # The just-activated jr, which carries the new /etc tree.
      local next
      next=$(command -v jr)
      "$next" etc --check >/dev/null || "$next" etc
    }

    cmd_build() {
      ${buildCmd} "$@"
    }

    command="''${1:-}"
    shift || true

    case "$command" in
      switch) cmd_switch "$@" ;;
      build) cmd_build "$@" ;;
      etc) cmd_etc "$@" ;;
      -h | --help | help) usage ;;
      *) usage >&2; exit 2 ;;
    esac
  '';
}
