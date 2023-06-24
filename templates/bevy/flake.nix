{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay, gitignore, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };
        rustAttrs = import ./rust.nix { inherit pkgs gitignore; };

        nativeDeps = rustAttrs.nativeDeps;

      in {
        formatter = pkgs.nixpkgs-fmt;
        devShells = {
          default = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [ pkg-config ];
            buildInputs = with pkgs;
              [
                rustAttrs.rust-shell

                clang
                lld # TODO: try mold instead https://bevyengine.org/learn/book/getting-started/setup/#enable-fast-compiles-optional

                # common
                just
              ] ++ nativeDeps;

            LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath nativeDeps;
          };
        };
        packages = {
          default = pkgs.hello;
          rust-bin = rustAttrs.binary;
        };
      });
}
