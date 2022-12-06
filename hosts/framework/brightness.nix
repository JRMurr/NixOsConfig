{ config, pkgs, lib, ... }: {
  services.clight = {
    enable = true;
    settings = { };
  };
  location = { provider = "geoclue2"; };

  myOptions.redShift.disable = true;
}

