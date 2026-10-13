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

  # Chrome with WebXR: https://github.com/phit/chromium-webxr-steam-frame
  # Repeated XDG_DATA_DIRS entries make the OpenXR loader stack Valve's
  # fdm_injection layer once per copy, which hangs WebXR. Drop repeats.
  chrome-xr = pkgs.writeShellApplication {
    name = "chrome-xr";
    runtimeInputs = [ pkgs.gawk pkgs.gnused ];
    text = ''
      XDG_DATA_DIRS=$(printf '%s' "''${XDG_DATA_DIRS:-}" | awk -v RS=: -v ORS=: 'NF && !seen[$0]++' | sed 's/:$//')
      export XDG_DATA_DIRS
      exec "$HOME/.local/bin/chrome-xr" "$@"
    '';
  };
in
{
  home.packages = [ chrome-xr ];

  # The VR "+" menu reads only ~/.local/share/applications, not XDG_DATA_DIRS.
  # Linked file by file, so Steam's own shortcuts there stay. Same desktop IDs
  # as the profile's, so Plasma shows each app once.
  xdg.dataFile."applications" = {
    source = entries;
    recursive = true;
  };

  # Replaces the entry chrome-xr's install.sh writes, to start the wrapper.
  # TODO: the icon path assumes the canary channel.
  xdg.dataFile."applications/chrome-xr.desktop" = {
    force = true;
    text = ''
      [Desktop Entry]
      Type=Application
      Name=Chrome XR
      Comment=Web browser with WebXR (immersive VR) through SteamVR
      Exec=${profileBin}/chrome-xr %U
      Icon=${config.home.homeDirectory}/chrome-xr/product_logo_256_canary.png
      Terminal=false
      Categories=Network;WebBrowser;
      MimeType=text/html;x-scheme-handler/http;x-scheme-handler/https;
    '';
  };
}
