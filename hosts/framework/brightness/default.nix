{
  config,
  pkgs,
  lib,
  ...
}:
{
  services.clight = {
    enable = true; # kept for gamma (night light); replaces redshift below
    settings = {
      # clightd 5.9 has no Wayland idle protocol; it measures idleness on
      # Xwayland (:1) and never sees input to native Wayland apps. Left on,
      # dimmer dims at 20s and dpms turns the panel off at 300s on battery and
      # nothing wakes it (2026-09-21). hypridle owns idle handling instead.
      dimmer.disabled = true;
      dpms.disabled = true;
    };
  };
  location = {
    provider = "geoclue2";
  };

  myOptions.redShift.disable = true;
}
