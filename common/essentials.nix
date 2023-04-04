{ pkgs, ... }: {
  nixpkgs.config.allowUnfree = true;
  nix = {
    # enable flakes
    # package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
  #TODO: some overlap with programs.nix
  programs.fish.enable = true;
  environment.systemPackages = with pkgs; [ git vim mkpasswd htop ];
}
