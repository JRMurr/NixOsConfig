{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    zig.url = "github:mitchellh/zig-overlay";
    zls.url = "github:zigtools/zls/0.13.0";
    zon2nix.url = "github:MidstallSoftware/zon2nix";
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ inputs.zig.overlays.default ];
        pkgs = import nixpkgs { inherit system overlays; };

        zigPkg = pkgs.zigpkgs."0.13.0"; # keep in sync with zls
        zlsPkg = inputs.zls.packages.${system}.default;
        zon2nix = inputs.zon2nix.packages.${system}.default;

      in
      {
        formatter = pkgs.nixfmt-rfc-style;
        devShells = {
          default = pkgs.mkShell {
            buildInputs =
              [
                # NOTE: these need to be roughly in sync
                zigPkg
                zlsPkg
                zon2nix

                pkgs.just
              ];
          };
        };

        # packages = { default = pkgs.hello; };
      });
}
