{ pkgs }:
{
  # Shell snippets, spliced into the script as-is; extra `jr switch`/`jr build`
  # arguments are appended.
  switchCmd,
  buildCmd,
  # Runs after a successful switch, from the just-activated profile.
  postSwitchCmd ? "",
}:
pkgs.writeShellApplication {
  name = "jr";
  text = ''
    usage() {
      cat <<'USAGE'
    usage: jr <command> [args]

      switch [args]  build and activate this host
      build [args]   build this host without activating it
    USAGE
    }

    cmd_switch() {
      ${switchCmd} "$@"
      ${postSwitchCmd}
    }

    cmd_build() {
      ${buildCmd} "$@"
    }

    command="''${1:-}"
    shift || true

    case "$command" in
      switch) cmd_switch "$@" ;;
      build) cmd_build "$@" ;;
      -h | --help | help) usage ;;
      *) usage >&2; exit 2 ;;
    esac
  '';
}
