{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
    home-manager.url = "github:nix-community/home-manager/release-21.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    passwords = {
      url = "path:/etc/nixos/secrets/passwords.nix";
      flake = false;
    };
  };
  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations.nixos-john = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
        }
      ];
      specialArgs = { inherit inputs; };
    };
  };
}
