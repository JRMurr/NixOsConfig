{ pkgs, ... }: {
  home.packages = [ pkgs.git ];
  # TODO: move to nix conf
  home.file.gitconfig = {
    source = ./gitconfig;
    target = ".gitconfig";
  };

  # programs.gpg = {
  #   enable = true;
  #   mutableTrust = false;
  #   mutableKeys = false;
  # };

  # services.gpg-agent = { enable = true; };
}
