{ lib, pkgs, nixosConfig, inputs, ... }:
let

  gcfg = nixosConfig.myOptions.graphics;
  spicePkgs = inputs.spicetify-nix.packages.${pkgs.system}.default;
in
{
  # imports = [
  #   inputs.spicetify-nix.homeManagerModule
  # ];

  config = lib.mkIf gcfg.enable
    {

      programs.spicetify =
        {
          enable = true;
          theme = spicePkgs.themes.catppuccin;
          colorScheme = "mocha";

          enabledExtensions = with spicePkgs.extensions; [
            fullAppDisplay
            shuffle # shuffle+ (special characters are sanitized out of ext names)
          ];
        };
    };
}
 