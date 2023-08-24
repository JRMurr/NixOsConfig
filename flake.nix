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
    # deploy-rs = {
    #   url = "github:serokell/deploy-rs";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    nurl = {
      url = "github:nix-community/nurl";
      # inputs.nixpkgs.follows = "nixpkgs";
    };
    # TODO: pick one
    nixd = { url = "github:nix-community/nixd"; };
    nil = { url = "github:oxalica/nil"; };

    passwords = {
      url = "path:/etc/nixos/secrets/passwords.nix";
      flake = false;
    };
    flake-compat = {
      url = "github:inclyc/flake-compat";
      flake = false;
    };
  };
  outputs = { self, nixpkgs, home-manager, wsl, nixos-hardware, vscode-server
    , flake-utils, nixd, nil, ... }@inputs:
    let

      defaultModules = [
        { _module.args = { inherit inputs; }; }
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          # environment.systemPackages =
          #   [ deploy-rs.packages.x86_64-linux.deploy-rs ];
        }
      ];

      mkSystem = extraModules:
        nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
          modules = defaultModules ++ extraModules;
        };
      mkPkgs = system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      mkHomemanager = name: user: system:
        let
          pkgs = mkPkgs system;
          # myOptions = import ./common/myOptions {
          #   config = { };
          #   lib = pkgs.lib;
          # };
          myOptions = { graphics.enable = false; };
        in home-manager.lib.homeManagerConfiguration {
          pkgs = pkgs;
          extraSpecialArgs = { nixosConfig = { inherit myOptions; }; };
          modules = [
            {
              _module.args.nixpkgs = nixpkgs;
              _module.args.inputs = inputs;
              # _module.args.vars = { stateVersion = "22.05"; };
            }
            ({ config, pkgs, lib, ... }: {
              home = {
                # TODO: this is the macos path, if used on linux need to switch to home
                homeDirectory = "/Users/${user}";
                username = user;
                # This value determines the Home Manager release that your
                # configuration is compatible with. This helps avoid breakage
                # when a new Home Manager release introduces backwards
                # incompatible changes.
                #
                # You can update Home Manager without changing this value. See
                # the Home Manager release notes for a list of state version
                # changes in each release.
                stateVersion = "22.05";

                # # symlink apps to $HOME/Applications so they show up in finder
                # # https://github.com/nix-community/home-manager/issues/1341#issuecomment-1190875080
                # activation = lib.mkIf pkgs.stdenv.isDarwin {
                #   copyApplications = let
                #     apps = pkgs.buildEnv {
                #       name = "home-manager-applications";
                #       paths = config.home.packages;
                #       pathsToLink = "/Applications";
                #     };
                #   in home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                #     baseDir="$HOME/Applications/Home Manager Apps"
                #     if [ -d "$baseDir" ]; then
                #       rm -rf "$baseDir"
                #     fi
                #     mkdir -p "$baseDir"
                #     for appFile in ${apps}/Applications/*; do
                #       target="$baseDir/$(basename "$appFile")"
                #       $DRY_RUN_CMD cp ''${VERBOSE_ARG:+-v} -fHRL "$appFile" "$baseDir"
                #       $DRY_RUN_CMD chmod ''${VERBOSE_ARG:+-v} -R +w "$target"
                #     done
                #   '';
                # };
              };
              # Let Home Manager install and manage itself.
              programs.home-manager.enable = true;
            })
            (./common/users + "/${name}" + /home.nix)
          ];
        };
    in {
      lib = { inherit mkSystem; };
      nixosModules.default = { ... }: {
        imports = defaultModules ++ [ ./common ];
      };
      templates = import ./templates { };

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

      homeConfigurations = {
        # stolen sorta from https://github.com/mrkuz/nixos/blob/738528d405bdb5b6e729c1d8d1885664650e08dd/flake.nix#L110
        jmurray = mkHomemanager "jmurray" "jmurray" "x86_64-darwin";
      };

      # deploy = {
      #   # https://lantian.pub/en/article/modify-website/nixos-initial-config-flake-deploy.lantian/
      #   # Auto rollback on deployment failure, recommended off.
      #   #
      #   # NixOS deployment can be a bit flaky (especially on unstable)
      #   # and you may need to deploy twice to succeed, but auto rollback
      #   # works against that and make your deployments constantly fail.
      #   autoRollback = false;

      #   # Auto rollback on Internet disconnection, recommended off.
      #   #
      #   # Rollback when your new config killed the Internet connection,
      #   # so you don't have to use VNC or IPMI from your service provider.
      #   # But if you're adjusting firewall or IP settings, chances are
      #   # although the Internet is down atm, a simple reboot will make everything work.
      #   # Magic rollback works against that, so you should keep that off.
      #   magicRollback = false;

      #   nodes.thicc-server = {
      #     hostname = "192.168.1.160";
      #     sshUser = "root";
      #     fastConnection = true;
      #     profiles.system = {
      #       user = "root";
      #       path = deploy-rs.lib.x86_64-linux.activate.nixos
      #         self.nixosConfigurations.thicc-server;
      #     };
      #   };
      # };

      # checks = builtins.mapAttrs
      #   (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;

    };
}
