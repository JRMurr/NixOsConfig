{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
let
  gcfg = config.myOptions.graphics;

  # sysVersion = osConfig.system.nixos.release;
  # onUnStable = lib.versionAtLeast sysVersion "23.11";
  fromInput = name: inputs.${name}.packages.${pkgs.stdenv.hostPlatform.system}.default;

  pickNixTool =
    name: if config.myOptions.nixTooling == "flakeInputs" then fromInput name else pkgs.${name};

  nurl = pickNixTool "nurl";
  nixd = pickNixTool "nixd";
  nil = pickNixTool "nil";

  ghostty = fromInput "ghostty";

  # nixd does not work on mac yet :(
  # https://github.com/nix-community/nixd/issues/107
  linuxOnly = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
    nixd
    nil
  ];

  graphical = pkgs.lib.optionals gcfg.enable [
    pkgs.pear-desktop # youtube music
    pkgs.obs-studio
    pkgs.mpv
    # ghostty
  ]
  # Prebuilt x86_64 binary; the Frame is aarch64.
  ++ lib.optional (lib.meta.availableOn pkgs.stdenv.hostPlatform pkgs.losslesscut-bin) pkgs.losslesscut-bin;

  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/tools/misc/bat-extras/default.nix#L142
  batExtras =
    let
      names = [
        "batdiff"
        "batgrep"
        "batman"
        "batpipe"
        "batwatch"
        "prettybat"
      ];
    in
    lib.attrVals names pkgs.bat-extras;

in
{
  home.packages =
    linuxOnly
    ++ graphical
    ++
      # batExtras ++
      (with pkgs; [

        # lastpass-cli
        # tailspin
        bacon # rust background checker
        bottom
        cachix
        dnsutils # dig
        dive
        nix-init
        nurl
        ouch # file decompresser
        ripgrep
        xclip
      ]);

  programs = {
    zoxide = {
      enable = true;
      enableFishIntegration = true;
      enableBashIntegration = true;
      enableNushellIntegration = true;
    };

    fzf = {
      enable = true;
      enableFishIntegration = true;
      enableBashIntegration = true;
    };

    bat = {
      enable = true;
    };

    gh.enable = true;
    htop.enable = true;
    btop.enable = true;
    jq.enable = true;

    eza = {
      enable = true;
      enableFishIntegration = true;
      enableBashIntegration = true;
    };
  };

}
