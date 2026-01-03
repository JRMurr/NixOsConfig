{ inputs, ... }:
let
  catppuccin = inputs.catppuccin.homeModules.catppuccin;
  spicetify = inputs.spicetify-nix.homeManagerModules.default;
  agenix = inputs.agenix.homeManagerModules.default;
in
{
  imports = [
    catppuccin
    spicetify
    agenix
    ../../homemanager
  ];

  catppuccin = {
    mako.enable = false;
  };

  # Everything in this file will be under home-manager.users.<name>
  # https://rycee.gitlab.io/home-manager/options.html

  xdg.enable = true;

  # https://nix-community.github.io/home-manager/release-notes.html#sec-release-22.11-highlights
  home.stateVersion = "18.09";

  _module.args.inputs = inputs;

}
