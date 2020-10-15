{ pkgs, config, ... }: {
  services.lorri.enable = true;

  home-manager.users.jr = { programs.direnv.enable = true; };

  environment.systemPackages = with pkgs; [
    niv
    docker-compose
    python3
    rustup
    vscode

  ];
}
