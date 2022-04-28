{ pkgs, ... }: {
  home.packages = with pkgs; [ bat killall exa zoxide jq fzf ];
  xdg.configFile.fish = {
    recursive = true;
    source = ../../dotFiles/fish;
  };
}
