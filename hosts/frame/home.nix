{
  pkgs,
  config,
  inputs,
  ...
}:
let
  repo = "$HOME/NixOsConfig";
  flakeRef = "${repo}#steamos@frame";
  caches = import ../../common/nix-caches.nix;

in
{
  # Steam Frame: aarch64 SteamOS, immutable root, so standalone home-manager
  # rather than a nixosConfiguration. Nix itself is installed out of band, see
  # ./README.md.
  imports = [
    ../../common/homemanager/cli.nix
    ../../common/homemanager/kitty.nix
    ./launchers.nix
    inputs.catppuccin.homeModules.catppuccin
    inputs.frametop.homeManagerModules.default
    inputs.steamos-etc.homeManagerModules.default
  ];

  # The NixOS hosts get these from the system through
  # ../../common/homemanager/fromOs.nix.
  catppuccin = {
    enable = true;
    autoEnable = true;
    flavor = "mocha";
    accent = "mauve";
  };

  home = {
    username = "steamos";
    homeDirectory = "/home/steamos";
    stateVersion = "26.11";
  };

  myOptions = {
    graphics.enable = true;
    llm.skills = [ "hegel" ];
    # Nothing caches the flake-input builds for aarch64, and compiling nixd under
    # qemu takes hours. These come from cache.nixos.org instead.
    nixTooling = "nixpkgs";

    jr = {
      # `nh os switch` is meaningless here. -b backup because a SteamOS update
      # puts its own dotfiles back in the way. Builds run locally: thicc-server's
      # nightly job fills cache-lan, and offloading everything through qemu was
      # slower than building the leftovers natively. ./README.md has the
      # --builders flag for one-off offloads. Desktop Mode's nested Plasma points
      # XDG_RUNTIME_DIR at .../nested_plasma, where activation can't find the
      # user bus and skips reloading systemd; the real one is /run/user/<uid>.
      switchCmd = "env XDG_RUNTIME_DIR=/run/user/1000 home-manager switch --flake \"${flakeRef}\" -b backup";
      buildCmd = "home-manager build --flake \"${flakeRef}\" --no-out-link";

      postSwitchCmd = "steamos-etc";
    };
  };

  # Wraps the session in the host's locales, ld.so cache and XDG data dirs,
  # which NixOS would otherwise provide.
  targets.genericLinux.enable = true;

  programs.frametop.enable = true;

  # SteamOS starts the user session and runs tmpfiles before nix.mount, so
  # anything there that links into the store dangles at boot. `jr switch`
  # installs these as real files.
  programs.steamos-etc = {
    enable = true;
    # Plasma's PATH (environment.d) and user-dirs.dirs are store links.
    waitForNix = true;
    gpuDrivers = true;
  };

  # Plasma takes its environment from the systemd user manager, not a login shell,
  # so without this its PATH lacks the profile and launcher entries like kitty's
  # `Exec=kitty` fail.
  systemd.user.sessionVariables.PATH = "${config.home.profileDirectory}/bin:/nix/var/nix/profiles/default/bin\${PATH:+:$PATH}";

  fonts.fontconfig.enable = true;

  # The NixOS hosts install it system-wide from common/programs.nix.
  home.packages = [
    (pkgs.callPackage ../../pkgs/vscode.nix { inherit pkgs inputs; }).myVscode
    pkgs.firefox
  ];

  # Standalone installs have to carry the CLI themselves.
  programs.home-manager.enable = true;

  # SteamOS keeps /etc/passwd on the read-only root, so fish cannot be the login
  # shell without `steamos-readonly disable`. Hand off from bash instead.
  programs.bash.initExtra = ''
    [[ $- == *i* && -z $FISH_LAUNCHED ]] && FISH_LAUNCHED=1 exec ${pkgs.fish}/bin/fish
  '';

  # common/default.nix sets these system-wide on the NixOS hosts; a standalone
  # install has to write its own ~/.config/nix/nix.conf. Only honoured if this
  # user is a trusted-user in /etc/nix/nix.conf -- see ./README.md.
  nix = {
    package = pkgs.nix;

    settings = {
      # Builds are offloaded to thicc-server with a `--builders` flag rather than
      # a buildMachines entry for now, see ./README.md. This setting only matters
      # together with that flag: it lets the builder fetch build inputs itself
      # instead of having them uploaded from here.
      builders-use-substitutes = true;

      # cache.jrnet.win resolves to thicc-server's tailscale address, unreachable
      # from here; cache-lan is the same harmonia at its LAN address. Its nightly
      # job builds this generation too.
      substituters = [ caches.harmonia.lan ] ++ caches.public;
      trusted-public-keys = [ caches.nixosKey ] ++ caches.keys;
      fallback = true;
      connect-timeout = 5;
    };
  };
}
