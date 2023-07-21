{ config, pkgs, lib, ... }: {
  services.clight = {
    # TODO: some crashing bug with clight right now 
    enable = false;
    settings = { };
  };
  location = { provider = "geoclue2"; };

  myOptions.redShift.disable = true;
}

