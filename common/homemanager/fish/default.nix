{ pkgs, lib, ... }: {

  programs.fish = {
    enable = true;
    # allow home manager to manage the root config file so other programs can be setup by it
    shellInit = (builtins.readFile ./files/config.base.fish);

    plugins = [
      {
        name = "bass";
        src = pkgs.fetchFromGitHub {
          owner = "edc";
          repo = "bass";
          rev = "2fd3d2157d5271ca3575b13daec975ca4c10577a";
          # sha256 = lib.fakeSha256;
          sha256 = "fl4/Pgtkojk5AE52wpGDnuLajQxHoVqyphE90IIPYFU=";
        };
      }
      {
        name = "fish-completion-sync";
        src = pkgs.fetchFromGitHub {
          owner = "pfgray";
          repo = "fish-completion-sync";
          rev = "ba70b6457228af520751eab48430b1b995e3e0e2";
          hash = "sha256-JdOLsZZ1VFRv7zA2i/QEZ1eovOym/Wccn0SJyhiP9hI=";
        };
      }
    ];
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.exa = {
    enable = true;
    enableAliases = true;
  };

  programs.bat = { enable = true; };

  home.packages = with pkgs; [ killall jq ];
  xdg.configFile.fish = {
    recursive = true;
    source = ./files;
  };
  xdg.configFile."fish_plugins" = {
    source = ./files/fish_plugins;
    target = "./fish_plugins";
  };
}
