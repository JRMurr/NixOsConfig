{
  pkgs,
  lib,
  nixosConfig,
  ...
}:
let

  gcfg = nixosConfig.myOptions.graphics;

in
{
  config = lib.mkIf gcfg.enable {
    programs.wofi = {
      enable = true;
    };
  };
}
