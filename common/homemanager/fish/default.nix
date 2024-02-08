{ pkgs, lib, ... }:
let
  customPlugins = [
    {
      name = "fish-completion-sync";
      src = pkgs.fetchFromGitHub {
        owner = "pfgray";
        repo = "fish-completion-sync";
        rev = "ba70b6457228af520751eab48430b1b995e3e0e2";
        hash = "sha256-JdOLsZZ1VFRv7zA2i/QEZ1eovOym/Wccn0SJyhiP9hI=";
      };
    }
    # {
    #   name = "nix-env";
    #   src = pkgs.fetchFromGitHub {
    #     owner = "lilyball";
    #     repo = "nix-env.fish";
    #     rev = "7b65bd228429e852c8fdfa07601159130a818cfa";
    #     hash = "sha256-RG/0rfhgq6aEKNZ0XwIqOaZ6K5S4+/Y5EEMnIdtfPhk=";
    #   };
    # }
    {
      name = "fish-systemd";
      src = pkgs.fetchFromGitHub {
        owner = "wawa19933";
        repo = "fish-systemd";
        rev = "4e922a28ae183e0ddb28c35b8f1415d2c63f978d";
        hash = "sha256-km6VgvYO1b3wnmpKrnJUaZUrQiIDl8NetECa33jbLbo=";
      };
    }
  ];
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

  xdg.configFile."fish/completions/nix.fish".source =
    "${pkgs.nix}/share/fish/vendor_completions.d/nix.fish";
}
