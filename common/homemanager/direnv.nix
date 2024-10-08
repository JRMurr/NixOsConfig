{
  programs.direnv = {
    enable = true;
    nix-direnv = {
      enable = true;
    };

    stdlib = ''
      # https://github.com/direnv/direnv/wiki/Customizing-cache-location
      declare -A direnv_layout_dirs
      direnv_layout_dir() {
          local hash path
          echo "''${direnv_layout_dirs[$PWD]:=$(
              hash="$(sha1sum - <<< "$PWD" | head -c40)"
              path="''${PWD//[^a-zA-Z0-9]/-}"
              echo "''${XDG_RUNTIME_DIR}/direnv/layouts/''${hash}''${path}"
          )}"
      }
    '';
  };
}
