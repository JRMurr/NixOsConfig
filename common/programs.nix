{
  pkgs,
  config,
  inputs,
  ...
}:
# let attic = inputs.attic.packages.${pkgs.system}.default;
# in 
let
  nix-inspect = inputs.nix-inspect.packages.${pkgs.system}.default;
in
with pkgs;
# TODO: move some of this to homemnager
let
  myOpts = config.myOptions;
  gcfg = myOpts.graphics;
  mcfg = myOpts.musicPrograms;

  myVscode = (pkgs.callPackage ../pkgs/vscode.nix { inherit inputs; }).myVscode;

  cliPrograms = [
    git
    gh
    htop
    vim
    wget
    mkpasswd
    lsof
    unzip
    # asciinema
    nixpkgs-review
    difftastic
    # attic-client disable for now while the server is sad
    dig
    nix-prefetch
    nix-output-monitor
    brotli # compression program

    systemctl-tui
    just

    nix-inspect
  ];
  imageStuff = [
    feh
    gimp
  ];
  messaging = [
    tdesktop # telegram
    discord
    zulip
  ];
  desktopEnviorment = [
    lxappearance
    arandr
    rofi-power-menu
  ];
  video = [
    streamlink-twitch-gui-bin
    streamlink
    vlc
  ];
  audio = [ spotify ];
  miscGraphicalPrograms = [
    piper # add mouse hotkeys
    firefox
    chromium
    kitty
    gparted
    baobab # space sniffer alternative
    pcmanfm
    # libsForQt5.dolphin
    # libsForQt5.dolphin-plugins
    myVscode
    # vscode
    # dbeaver
    deluge

    insomnia # rest client

    # note stuff
    notion-app-enhanced
    obsidian

    # show fonts
    pkgs.gucharmap

    # ebooks
    calibre

    zed-editor # :pog:
  ];

  musicPrograms = lib.optional mcfg.enable bespokesynth-with-vst2;

  allGraphicalPrograms =
    if gcfg.enable then
      miscGraphicalPrograms
      ++ video
      ++ desktopEnviorment
      ++ messaging
      ++ imageStuff
      ++ audio
      ++ musicPrograms
    else
      [ ];
in
{
  # these two are for vscode to stop yelling at me
  programs.dconf.enable = true;
  services.gnome.gnome-keyring.enable = true;

  environment.systemPackages = cliPrograms ++ allGraphicalPrograms;
}
