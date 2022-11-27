{ config, pkgs, ... }: {
  services.clight = {
    enable = true;
    settings = { };
  };
  location = { provider = "geoclue2"; };

}

