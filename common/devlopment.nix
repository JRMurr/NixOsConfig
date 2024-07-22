{ pkgs, config, ... }: {
  # TODO: move this into homemanger
  # https://github.com/nix-community/nix-direnv
  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
  '';
  environment.systemPackages = with pkgs; [
    dive
    flyctl
    docker-compose
    python3
    rustup
    # nix stuff
    nixfmt-rfc-style
    # rnix-lsp # nix lang server
    statix # linter

    (sqlite.override { interactive = true; })
  ];
  programs.java.enable = true;
}
