{ config, pkgs, ... }: {

  services.adguardhome = {
    enable = true;
    mutableSettings = true;
    port = 3000;
  };
}
