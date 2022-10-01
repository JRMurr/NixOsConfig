{ pkgs, lib, ... }: {

  programs.fish = {
    enable = true;
    # allow home manager to manage the root config file so other programs can be setup by it
    shellInit = (builtins.readFile ../../../dotFiles/fish/config.base.fish);

    plugins = [{
      name = "bass";
      src = pkgs.fetchFromGitHub {
        owner = "edc";
        repo = "bass";
        rev = "2fd3d2157d5271ca3575b13daec975ca4c10577a";
        # sha256 = lib.fakeSha256;
        sha256 = "fl4/Pgtkojk5AE52wpGDnuLajQxHoVqyphE90IIPYFU=";
      };
    }];
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  home.packages = with pkgs; [ bat killall exa jq ];
  xdg.configFile.fish = {
    recursive = true;
    source = ../../../dotFiles/fish;
  };
  xdg.configFile."fish_plugins" = {
    source = ../../../dotFiles/fish/fish_plugins;
    target = "./fish_plugins";
  };
}
