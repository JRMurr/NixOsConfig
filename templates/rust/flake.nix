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

  outputs = { self, nixpkgs, flake-utils, gitignore, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        rustAttrs = import ./rust { inherit pkgs gitignore; };
      in {
        devShells = {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              rustAttrs.rust-shell

              # common
              watchexec
              just
              nixfmt
            ];
          };
        };
        packages = {
          default = pkgs.hello;
          rust-bin = rustAttrs.binary;
          rust-docker = rustAttrs.docker;
        };
      });
}
