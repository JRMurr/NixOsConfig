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
    vscode-server = {
      url = "github:msteen/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    passwords = {
      url = "path:/etc/nixos/secrets/passwords.nix";
      flake = false;
    };
  };
  outputs = { self, nixpkgs, home-manager, wsl, nixos-hardware, vscode-server
    , deploy-rs, ... }@inputs:
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
        thicc-server = mkSystem [
          ./hosts/thicc-server
          vscode-server.nixosModule
          ({ config, pkgs, ... }: { services.vscode-server.enable = true; })
        ];
      };

      deploy = {
        # https://lantian.pub/en/article/modify-website/nixos-initial-config-flake-deploy.lantian/
        # Auto rollback on deployment failure, recommended off.
        #
        # NixOS deployment can be a bit flaky (especially on unstable)
        # and you may need to deploy twice to succeed, but auto rollback
        # works against that and make your deployments constantly fail.
        # autoRollback = false;

        # Auto rollback on Internet disconnection, recommended off.
        #
        # Rollback when your new config killed the Internet connection,
        # so you don't have to use VNC or IPMI from your service provider.
        # But if you're adjusting firewall or IP settings, chances are
        # although the Internet is down atm, a simple reboot will make everything work.
        # Magic rollback works against that, so you should keep that off.
        # magicRollback = false;

        nodes.thicc-server = {
          hostname = "192.168.1.160";
          sshUser = "root";
          fastConnection = true;
          profiles.system = {
            user = "root";
            path = deploy-rs.lib.x86_64-linux.activate.nixos
              self.nixosConfigurations.thicc-server;
          };
        };
      };

      checks = builtins.mapAttrs
        (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;

    };
}
