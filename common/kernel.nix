{ ... }:
{
  boot = {
    # https://make-linux-fast-again.com/
    # https://transformingembedded.sigmatechnology.se/insight-post/make-linux-fast-again-for-mortals/
    # TLDR: turns off nerd security stuff for MORE POWER
    kernelParams = [
      "noibrs"
      "noibpb"
      "nopti"
      "nospectre_v2"
      "nospectre_v1"
      "l1tf=off"
      "nospec_store_bypass_disable"
      "no_stf_barrier"
      "mds=off"
      "mitigations=off"
    ];
  };
}
