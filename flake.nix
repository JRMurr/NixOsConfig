{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
    unstable.url = "nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-21.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    passwords = {
      url = "path:/etc/nixos/secrets/passwords.nix";
      flake = false;
    };
  };
  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      mkSystem = extraModules:
        nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
          modules = [
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
            }
          ] ++ extraModules;
          specialArgs = { inherit inputs; };
        };
    in {
      nixosConfigurations = { nixos-john = mkSystem [ ./hosts/desktop ]; };
    };
}
