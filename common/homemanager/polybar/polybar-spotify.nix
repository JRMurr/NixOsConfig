{ pkgs, lib, ... }:
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
in pkgs.stdenv.mkDerivation rec {
  pname = "polybar-spotify";
  version = "1.0.0";
  src = pkgs.fetchFromGitHub {
    owner = "PrayagS";
    repo = pname;
    rev = "d20a8ad2fef05fe79c5b38fa7e17be0724e1e821";
    hash = "sha256-+rVH8dd3ylM514wJKScu7klujykwZy87AFZRDjyI28s=";
  };
  buildInputs = deps;
  nativeBuildInputs = [ pkgs.makeWrapper ];

  preConfigure = ''
    patchShebangs "script"

    # need to change some variables to match my bar config, probably should path or fork the repo to make it more easily configurable
    sed -i 's/PARENT_BAR="now-playing"/PARENT_BAR="main"/g' get_spotify_status.sh

    # make srcoll reference the global script
    sed -i 's/"`dirname $0`\/get_spotify_status.sh/"get_spotify_status/g' scroll_spotify_status.sh
  '';

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin

    cp -a get_spotify_status.sh $out/bin/get_spotify_status

    wrapProgram $out/bin/get_spotify_status \
        --prefix PATH : ${lib.makeBinPath deps}


    cp -a scroll_spotify_status.sh $out/bin/scroll_spotify_status

    wrapProgram $out/bin/scroll_spotify_status \
        --prefix PATH : ${lib.makeBinPath deps + ":$out/bin"}
  '';

  # postFixup = ''
  #   wrapProgram $out/bin/get_spotify_status \
  #         --prefix PATH : "${lib.makeBinPath deps}" 

  #   wrapProgram $out/bin/scroll_spotify_status \
  #         --prefix PATH : "${lib.makeBinPath deps}" 
  # '';
}
