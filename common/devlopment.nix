{ pkgs, config, ... }: {
  # services.lorri.enable = true;

  # https://github.com/nix-community/nix-direnv
  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
  '';

  environment.systemPackages = with pkgs; [
    niv
    docker-compose
    python3
    rustup
    vscode
    dbeaver
  ];

  programs.java.enable = true;
}
