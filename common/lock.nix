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
    security.loginDefs.settings.FAIL_DELAY = 0;

    services.xserver.xautolock = {
      enable = true;
      locker = "${pkgs.xlockmore}/bin/xlock -mode blank";
    };
  };
}
