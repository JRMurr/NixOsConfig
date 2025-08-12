{
  pkgs,
  lib,
  player ? "spotify",
}:
let
  # nurl https://github.com/PrayagS/polybar-spotify/tree/master
  deps = with pkgs; [
    zscroll
    playerctl

    # these usally are available but polybar will run with a limited path set
    coreutils
    gnugrep
    procps # pgrep
  ];
in
pkgs.stdenv.mkDerivation {
  pname = "polybar-spotify";
  version = "1.0.0";
  src = ./scripts;
  # src = pkgs.fetchFromGitHub {
  #   owner = "PrayagS";
  #   repo = pname;
  #   rev = "d20a8ad2fef05fe79c5b38fa7e17be0724e1e821";
  #   hash = "sha256-+rVH8dd3ylM514wJKScu7klujykwZy87AFZRDjyI28s=";
  # };
  buildInputs = deps;
  nativeBuildInputs = [ pkgs.makeWrapper ];

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin

    cp -a get_spotify_status.sh $out/bin/get_spotify_status

    wrapProgram $out/bin/get_spotify_status \
        --prefix PATH : ${lib.makeBinPath deps} \
        --set PLAYER ${player}

    cp -a scroll_spotify_status.sh $out/bin/scroll_spotify_status

    wrapProgram $out/bin/scroll_spotify_status \
        --prefix PATH : ${lib.makeBinPath deps + ":$out/bin"}
  '';

  passthru = { inherit player; };
}
