{ pkgs, ... }: {
  home.packages = with pkgs; [ bat killall exa zoxide jq fzf ];
  xdg.configFile.fish = {
    recursive = true;
    source = ../../dotFiles/fish;
  };
  xdg.configFile."fish_plugins" = {
    source = ../../dotFiles/fish/fish_plugins;
    target = "./fish_plugins";
  };
}