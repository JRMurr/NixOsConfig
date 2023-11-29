{
  environment.variables.XCURSOR_SIZE = "10";
  services.xserver.videoDrivers = [ "nvidia" ];
  # services.xserver.dpi = 100;
  myOptions.graphics = {
    enable = true;
    wallPaper = { mode = "scale"; };
    monitors = [
      {
        # main 1440p 144hz monitor
        fingerprint =
          "00ffffffffffff0006b32227010101011e1d0104b53c22783b9e20a8554ca0260e5054bfef00714f81809500d1c00101010101010101565e00a0a0a029503020350055502100001c000000fd003090e6e63c010a202020202020000000fc0056473237410a20202020202020000000ff004b374c4d51533037323438340a01ab020329f14e90111213040e0f1d1e1f1405403f2309070783010000e305e001e6060701737300e2006a59e7006aa0a067501520350055502100001a6fc200a0a0a055503020350055502100001a5aa000a0a0a046503020350055502100001a000000000000000000000000000000000000000000000000000000000000000032";
        name = "DP-4";
        enable = true;
        primary = true;
        # position = "2160x0";
        position = "1440x0";
        resolution = "2560x1440";
        rate = "143.97";
        workspace = 1;
        crtc = 0; # xrandr --verbose to get
        dpi = 100;
      }
      {
        # 4k portrait on left
        fingerprint =
          "00ffffffffffff001e6d0777b21d0200061d0104b53c22789e3e31ae5047ac270c50542108007140818081c0a9c0d1c08100010101014dd000a0f0703e803020650c58542100001a286800a0f0703e800890650c58542100001a000000fd00383d1e8738000a202020202020000000fc004c472048445220344b0a20202001980203197144900403012309070783010000e305c000e3060501023a801871382d40582c450058542100001e565e00a0a0a029503020350058542100001a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000029";
        name = "DP-0";
        enable = true;
        primary = false;
        position = "0x0";
        # resolution = "3840x2160";
        resolution = "2560x1440"; # scale down so its easier to read...
        rate = "60.00";
        rotate = "left";
        workspace = 2;
        crtc = 1;
        # dpi = 150;
        # scale = {
        #   x = 1;
        #   y = 1;
        # };
      }
    ];
  };
}
