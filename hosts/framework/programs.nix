{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [ ldtk zoom-us ];
}
