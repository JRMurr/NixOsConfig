{ pkgs, config, ... }: {
  # services.lorri.enable = true;

  # https://github.com/nix-community/nix-direnv
  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
  '';

  environment.systemPackages = with pkgs; [
    docker-compose
    python3
    rustup
    nixfmt
    rnix-lsp # nix lang server
  ];

  programs.java.enable = true;
}
