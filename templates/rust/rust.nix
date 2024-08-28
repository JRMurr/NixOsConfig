{ pkgs, gitignore }:

let
  rustVersion = (pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml); # rust-bin.stable.latest.default
  rustPlatform = pkgs.makeRustPlatform {
    cargo = rustVersion;
    rustc = rustVersion;
  };
  name = "TODO:FILL ME";
  version = "0.1.0";
  rustBin = rustPlatform.buildRustPackage {
    pname = name;
    version = version;
    src = gitignore.lib.gitignoreSource ./.;
    cargoLock.lockFile = ./Cargo.lock;
    nativeBuildInputs = [ ];
  };
in
{
  rust-shell = (
    rustVersion.override {
      extensions = [
        "rust-src"
        "rust-analyzer"
      ];
    }
  );
  binary = rustBin;
  docker = pkgs.dockerTools.buildImage {
    name = name;
    config = {
      Cmd = [ "${rustBin}/bin/TODO" ];
    };
  };
}
