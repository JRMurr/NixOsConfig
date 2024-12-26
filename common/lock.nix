{
  config,
  pkgs,
  lib,
  ...
}:
let
  lcfg = config.myOptions.lock;
in
{
  config = lib.mkIf lcfg.enable {
    security.loginDefs.settings.FAIL_DELAY = 0;

    services.xserver.xautolock = {
      enable = true;
      locker = "${pkgs.xlockmore}/bin/xlock -mode blank";
    };
  };
}
