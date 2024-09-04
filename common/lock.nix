{ config
, pkgs
, lib
, ...
}:
let
  gcfg = config.myOptions.graphics;
in
{
  config = lib.mkIf gcfg.enable {
    services.xserver.xautolock = {
      enable = true;
      locker = "${pkgs.xlockmore}/bin/xlock -mode blank";
    };
  };
}
