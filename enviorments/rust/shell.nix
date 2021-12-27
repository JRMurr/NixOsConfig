{ pkgs ? import <nixpkgs> {
  overlays = [
    (import (builtins.fetchTarball
      "https://github.com/oxalica/rust-overlay/archive/master.tar.gz"))
  ];
} }:
with pkgs;
pkgs.mkShell {
  buildInputs = with pkgs;
    [ (rust-bin.fromRustupToolchainFile ./rust-toolchain) ];
}
