{
  lib,
  pkgs,
  osConfig,
  inputs,
  ...
}:
let

  gcfg = osConfig.myOptions.graphics;
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  config = lib.mkIf gcfg.enable {

    programs.spicetify = {
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
