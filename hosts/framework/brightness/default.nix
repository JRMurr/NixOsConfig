{
  config,
  pkgs,
  lib,
  ...
}:
{
  services.clight = {
    # TODO: some crashing bug with clight right now 
    enable = true;
    settings = { };
  };
  location = {
    provider = "geoclue2";
  };

  myOptions.redShift.disable = true;
}
