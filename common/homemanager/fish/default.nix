{ pkgs, lib, ... }:
let
  customPlugins = [{
    name = "fish-completion-sync";
    src = pkgs.fetchFromGitHub {
      owner = "pfgray";
      repo = "fish-completion-sync";
      rev = "ba70b6457228af520751eab48430b1b995e3e0e2";
      hash = "sha256-JdOLsZZ1VFRv7zA2i/QEZ1eovOym/Wccn0SJyhiP9hI=";
    };
  }];
  preBuiltPlugins = with pkgs.fishPlugins; [ bass done ];
in {

  programs.fish = {
    enable = true;
    # allow home manager to manage the root config file so other programs can be setup by it
    shellInit = (builtins.readFile ./files/config.base.fish);

    plugins = customPlugins;
  };

  home.packages = with pkgs; [ killall jq libnotify ] ++ preBuiltPlugins;
  xdg.configFile.fish = {
    recursive = true;
    source = ./files;
  };
  xdg.configFile."fish_plugins" = {
    source = ./files/fish_plugins;
    target = "./fish_plugins";
  };
}
