{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    utils.url = "github:numtide/flake-utils";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "utils";
    };
    passwords = {
      url = "path:/etc/nixos/secrets/passwords.nix";
      flake = false;
    };
  };
  outputs = { self, nixpkgs, home-manager, wsl, nixos-hardware, ... }@inputs:
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
      nixosConfigurations = {
        nixos-john = mkSystem [ ./hosts/desktop ];
        wsl = mkSystem [ wsl.nixosModules.wsl ./hosts/wsl ];
        graphicalIso = mkSystem [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-plasma5.nix"
          ./common/essentials.nix
        ];
        framework =
          mkSystem [ nixos-hardware.nixosModules.framework ./hosts/framework ];
      };
    };
}
