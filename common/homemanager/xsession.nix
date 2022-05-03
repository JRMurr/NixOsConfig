{ pkgs, lib, config, nixosConfig, ... }:
let gcfg = nixosConfig.myOptions.graphics;
in {
  config = lib.mkIf gcfg.enable {
    xsession = {
      enable = true;
      initExtra = "xset s off -dpms";
    };
  };
}
