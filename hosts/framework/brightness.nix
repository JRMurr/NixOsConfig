{ config, pkgs, ... }: {
  services.clight.enable = true;
  location = { provider = "geoclue2"; };

}

