{ lib, pkgs, ... }:
let
  # Renders XRService's tracking datasets into one video of all tracking cameras,
  # for showing the upper-right camera dropping out.
  occ2video = pkgs.writers.writePython3Bin "occ2video" {
    flakeIgnore = [ "E501" ];
    makeWrapperArgs = [
      "--prefix"
      "PATH"
      ":"
      (lib.makeBinPath [ pkgs.ffmpeg-headless ])
    ];
  } (builtins.readFile ./occ2video.py);
in
{
  home.packages = [ occ2video ];
}
