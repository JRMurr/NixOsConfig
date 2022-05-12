{
  environment.variables.XCURSOR_SIZE = "10";
  services.xserver.dpi = 125;
  # services.xserver.videoDrivers = [ "nvidia" ];
  myOptions.graphics = {
    enable = true;
    monitors = [{
      # main 1440p 144hz monitor
      fingerprint =
        "00ffffffffffff0009e55f0900000000171d0104a51c137803de50a3544c99260f505400000001010101010101010101010101010101115cd01881e02d50302036001dbe1000001aa749d01881e02d50302036001dbe1000001a000000fe00424f452043510a202020202020000000fe004e4531333546424d2d4e34310a00fb";
      name = "eDP-1";
      enable = true;
      primary = true;
      position = "0x0";
      resolution = "2256x1504";
      rate = "60.00";
      workspace = 1;
    }];
  };
}
