{ pkgs, ... }:
{
  # https://github.com/nix-community/home-manager/blob/master/modules/programs/helix.nix#blob-path
  programs.helix = {
    enable = true;
    # settings = { theme = "dracula"; };
  };
}
