{ pkgs, ... }: {
  home.packages = [ pkgs.git ];
  home.file.gitconfig = {
    source = ./gitconfig;
    target = ".gitconfig";
  };
}
