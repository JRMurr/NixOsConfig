{ pkgs, ... }: {
  home.packages = [ pkgs.git ];
  xdg.configFile.gitconfig = {
    source = ../../dotFiles/gitconfig;
    target = "../.gitconfig";
  };
}
