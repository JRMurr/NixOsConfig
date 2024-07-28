{ inputs, ... }:
let
  catppuccin = inputs.catppuccin.homeManagerModules.catppuccin;
  spicetify = inputs.spicetify-nix.homeManagerModules.default;
in
{
  imports = [
    catppuccin
    spicetify
    ../../homemanager
  ];
  # Everything in this file will be under home-manager.users.<name>
  # https://rycee.gitlab.io/home-manager/options.html

  xdg.enable = true;

  # https://nix-community.github.io/home-manager/release-notes.html#sec-release-22.11-highlights
  home.stateVersion = "18.09";

  _module.args.inputs = inputs;

}
