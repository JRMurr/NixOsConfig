{ ... }:
{
  # Everything here must evaluate without a NixOS config behind it: this is the
  # only entry point hosts/frame (standalone home-manager on SteamOS) imports.
  imports = [
    ./myOptions.nix

    ./cargo.nix
    ./direnv.nix
    ./fish
    ./git
    ./gitui.nix
    ./jr.nix
    ./jj.nix
    ./llms
    ./nushell
    ./programs.nix
    ./starship.nix
  ];

  programs.bash.enable = true;

  systemd.user.startServices = true;

  services.ssh-agent.enable = true;

  xdg.userDirs.createDirectories = true;
  xdg.userDirs.enable = true;
  # legacy default for home.stateVersion < 26.05; exports XDG_*_DIR
  xdg.userDirs.setSessionVariables = true;

  programs.tmux = {
    enable = true;
    # Taps select panes and a finger scrolls the scrollback, which is the
    # difference between usable and not on a phone. Costs shift-drag for
    # terminal-native selection on the desktops.
    mouse = true;
  };
}
