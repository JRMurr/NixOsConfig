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
      url = "github:nix-community/lanzaboote"; # master; v1.0.0 still sets removed boot.bootspec.enable

      inputs.nixpkgs.follows = "nixpkgs";
    };

    llm-agents.url = "github:numtide/llm-agents.nix";

    # Source-only: plain markdown skills, exposed as pkgs.hegel-skill by ./pkgs/overlay.nix
    hegel-skill = {
      url = "github:hegeldev/hegel-skill";
      flake = false;
    };

    # Same deal. Upstream ships a full plugin (hooks, marketplace manifest); we
    # link only skills/i-have-adhd, so the SessionStart always-on hook is not
    # installed and `/i-have-adhd` is the way in.
    i-have-adhd-skill = {
      url = "github:ayghri/i-have-adhd";
      flake = false;
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tix = {
      url = "github:JRMurr/tix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    jj-stamp = {
      url = "github:ethanal/jj-stamp";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Steam Frame desktop (hosts/frame). follows: one Mesa for ft-screens and /run/opengl-driver.
    frametop = {
      # TODO: back to main once gaze-mode merges.
      url = "github:JRMurr/frametop-nix/gaze-mode";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    steamos-etc = {
      # TODO: back to main once files-from-store merges.
      url = "github:JRMurr/steamos-etc-nix/files-from-store";
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
      llm-agents,
      ...
    }@inputs:
    let
      overlays = [
        inputs.agenix.overlays.default
        inputs.nix-vscode-extensions.overlays.default
        llm-agents.overlays.shared-nixpkgs
        (import ./pkgs/overlay.nix { inherit inputs; })
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

          environment.systemPackages = [
            inputs.tix.packages."x86_64-linux".default
          ];

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

      # Standalone home-manager, for hosts that are not NixOS (hosts/frame).
      # Nothing from defaultModules applies, so the modules must not reach for
      # `osConfig`.
      mkHome =
        system: modules:
        home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs system;
          extraSpecialArgs = { inherit inputs; };
          inherit modules;
        };

    in
    {
      inherit overlays;
      lib = {
        inherit mkSystem mkHome;
      };
      nixosModules.default =
        { ... }:
        {
          imports = defaultModules ++ [ ./common ];
        };
      templates = import ./templates { };

      nixosConfigurations = {
        desktop = mkSystem [
          inputs.lanzaboote.nixosModules.lanzaboote
          ./hosts/desktop
        ];
        wsl = mkSystem [
          wsl.nixosModules.wsl
          ./hosts/wsl
        ];
        graphicalIso = mkSystem [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix"
          ./common/essentials.nix
          ./common/programs.nix
          ./common/myOptions
        ];
        simpleIso = mkSystem [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
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
          (
            { config, pkgs, ... }:
            {
              services.vscode-server.enable = true;
            }
          )
        ];
      };

      # home-manager switch --flake /etc/nixos#steamos@frame
      homeConfigurations = {
        "steamos@frame" = mkHome "aarch64-linux" [ ./hosts/frame/home.nix ];
      };

      packages."x86_64-linux" =
        let
          pkgs = mkPkgs "x86_64-linux";

          mine = pkgs.callPackage ./pkgs { };
        in
        mine
        // {

        };

      checks."x86_64-linux" =
        let
          pkgs = mkPkgs "x86_64-linux";
        in
        {
          harmonia = pkgs.testers.runNixOSTest ./tests/harmonia.nix;

          # Guards the standalone path: common/homemanager/cli.nix has to evaluate
          # with `osConfig = null`. The string context is discarded so this only
          # instantiates the aarch64 derivation, never builds it.
          frame-home = pkgs.runCommand "frame-home-eval" { } ''
            echo ${
              builtins.unsafeDiscardStringContext
                self.homeConfigurations."steamos@frame".activationPackage.drvPath
            } > $out
          '';
        };

    };
}
