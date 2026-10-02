{ config, pkgs, ... }:
let
  profileBin = "${config.home.profileDirectory}/bin";

  # The profile's desktop entries with Exec/TryExec naming their command by
  # absolute path: the Steam session's PATH doesn't carry the nix profile. The
  # profile link rather than a store path, so entries don't churn per generation.
  entries = pkgs.runCommand "frame-desktop-entries" { } ''
    mkdir -p $out

    for src in ${config.home.path}/share/applications/*.desktop; do
      awk -v bin=${config.home.path}/bin -v profile=${profileBin} '
        match($0, /^(TryExec|Exec)=/) {
          key = substr($0, 1, RLENGTH)
          rest = substr($0, RLENGTH + 1)
          split(rest, words, " ")
          cmd = words[1]

          if (cmd !~ /\// && system("test -e \"" bin "/" cmd "\"") == 0)
            $0 = key profile "/" cmd substr(rest, length(cmd) + 1)
        }
        { print }
      ' "$src" > "$out/$(basename "$src")"
    done
  '';
in
{
  # The VR "+" menu reads only ~/.local/share/applications, not XDG_DATA_DIRS.
  # Linked file by file, so Steam's own shortcuts there stay. Same desktop IDs
  # as the profile's, so Plasma shows each app once.
  xdg.dataFile."applications" = {
    source = entries;
    recursive = true;
  };
}
