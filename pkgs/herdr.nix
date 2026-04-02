{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage {
  pname = "herdr";
  version = "0.2.4";

  src = fetchFromGitHub {
    owner = "ogulcancelik";
    repo = "herdr";
    rev = "v0.2.4";
    hash = "sha256-5zci1F2QCuyoJHUTSq/2/ahayRIigqj1EIPnnxLHtcc=";
  };

  cargoHash = "sha256-KJaATRej9xP2sbWIqKXfiLdHp9eMmgMA4VnCm+4xUcc=";

  # Some tests try to spawn processes (sleep, shell) which don't exist in the sandbox
  doCheck = false;

  meta = {
    description = "Terminal-native agent multiplexer for coding agents";
    homepage = "https://github.com/ogulcancelik/herdr";
    license = lib.licenses.asl20;
    mainProgram = "herdr";
  };
}
