{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ghostty = {
      url = "github:ghostty-org/ghostty";
    };
    utils.url = "github:numtide/flake-utils";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
      # inputs.flake-utils.follows = "utils";
    };
    vscode-server = {
      url = "github:msteen/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    attic = {
      url = "github:zhaofengli/attic";
      # inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix.url = "github:Gerg-L/spicetify-nix";

    catppuccin.url = "github:catppuccin/nix";

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    # deploy-rs = {
    #   url = "github:serokell/deploy-rs";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    nurl = {
      url = "github:nix-community/nurl";
      # inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-inspect.url = "github:bluskript/nix-inspect";
    # TODO: pick one
    nixd = {
      url = "github:nix-community/nixd";
    };
    nil = {
      url = "github:oxalica/nil";
    };

    agenix.url = "github:ryantm/agenix";
    secrets = {
      url = "git+ssh://git@github.com/JRMurr/nix-secrets";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.agenix.follows = "agenix";
      inputs.flake-utils.follows = "utils";
    };
    flake-compat = {
      url = "github:inclyc/flake-compat";
      flake = false;
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";

      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      wsl,
      catppuccin,
      ...
    }@inputs:
    let
      overlays = [
        inputs.attic.overlays.default
        inputs.agenix.overlays.default
        (import ./pkgs/overlay.nix)
        # TODO: nil and nurl
      ];
      defaultModules = [
        {
          _module.args = {
            inherit inputs;
          };
        }
        inputs.agenix.nixosModules.default
        home-manager.nixosModules.home-manager
        catppuccin.nixosModules.catppuccin
        {
          nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
          nixpkgs = {
            config = {
              allowUnfree = true;
            };
            overlays = overlays;
          };

          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";
            sharedModules = [
              (
                { pkgs, ... }:
                {
                  # _module.args.pkgsPath = pkgs.path;
                  # nixpkgs = {
                  #   config = {
                  #     allowUnfree = true;
                  #   };
                  #   overlays = overlays;
                  # };
                }
              )
            ];
          };

        }
      ];
      mkPkgs =
        system:
        import nixpkgs {
          inherit system overlays;
          config.allowUnfree = true;
        };
      mkSystem =
        extraModules:
        nixpkgs.lib.nixosSystem {
          # pkgs = mkPkgs "x86_64-linux";
          system = "x86_64-linux";
          modules = defaultModules ++ extraModules;
        };

    in
    {
      inherit overlays;
      lib = {
        inherit mkSystem;
      };
      nixosModules.default =
        { ... }:
        {
          imports = defaultModules ++ [ ./common ];
        };
      templates = import ./templates { };

      nixosConfigurations = {
        desktop = mkSystem [  inputs.lanzaboote.nixosModules.lanzaboote ./hosts/desktop ];
        wsl = mkSystem [
          wsl.nixosModules.wsl
          ./hosts/wsl
        ];
        graphicalIso = mkSystem [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-plasma5.nix"
          ./common/essentials.nix
          ./common/programs.nix
          ./common/myOptions
        ];
        framework = mkSystem [
          inputs.nixos-hardware.nixosModules.framework-11th-gen-intel
          ./hosts/framework
        ];
        thicc-server = mkSystem [
          ./hosts/thicc-server
          inputs.vscode-server.nixosModule
          inputs.attic.nixosModules.atticd
          (
            { config, pkgs, ... }:
            {
              services.vscode-server.enable = true;
            }
          )
        ];
      };

      packages."x86_64-linux" =
        let
          pkgs = mkPkgs "x86_64-linux";

          mine = pkgs.callPackage ./pkgs { };
        in
        mine
        // {

        };

    };
}
