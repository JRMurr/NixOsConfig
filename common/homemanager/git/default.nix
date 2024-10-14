{ pkgs, nixosConfig, ... }:
let
  gcfg = nixosConfig.myOptions.graphics;
  gitpkg = if gcfg.enable then pkgs.gitFull else pkgs.git;
in
{
  home.packages = [ gitpkg ];
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
