{ config, pkgs, callPackage, ... }: {
  # https://nixos.wiki/wiki/Redshift
  location = {
    provider = "manual";
    # u aint stealing my exact location from this
    latitude = 38.886383;
    longitude = -77.036322;
  };
  # All values except 'enable' are optional.
  services.redshift = {
    enable = true;
    brightness = {
      day = "1";
      night = "1";
    };
    temperature = {
      day = 5500;
      night = 3700;
    };
  };
}
