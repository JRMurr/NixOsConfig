# Binary caches shared by the NixOS hosts (../common/default.nix) and the
# standalone Frame (../hosts/frame/home.nix). Only the way they reach
# thicc-server's harmonia differs.
{
  harmonia = {
    tailnet = "https://cache.jrnet.win?priority=1";
    # Same harmonia at its LAN address, for hosts off the tailnet; see blocky's
    # customDNS.
    lan = "https://cache-lan.jrnet.win?priority=1";
  };

  public = [
    "https://cache.nixos.org/?priority=20"
    "https://nix-community.cachix.org?priority=25"
    # numtide advertises no Priority in its nix-cache-info, so without an
    # explicit one it lands at 0 and outranks harmonia. Last resort: every other
    # substituter here should be tried before it.
    "https://cache.numtide.com?priority=50"
  ];

  keys = [
    "cache.jrnet.win-1:FVkbrXPDdxta7+tgKfTAZJCoT0ptqfl3TUSE1M9TrBU="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
  ];

  # NixOS trusts this by default. A trusted-public-keys list written by
  # home-manager replaces nix's default instead, so it has to carry it.
  nixosKey = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
}
