{
  pkgs,
  lib,
  inputs,
  osConfig,
  ...
}:
let
  gcfg = osConfig.myOptions.graphics;

  # Browser-based review UI, so it is useless on headless hosts.
  jj-stamp = inputs.jj-stamp.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  home.packages = lib.optionals gcfg.enable [ jj-stamp ];

  programs.jujutsu = {
    enable = true;

    # Same identity as common/homemanager/git. Commit signing is intentionally
    # not configured here, unlike git.
    settings.user = {
      name = "John Murray";
      email = "5672686+JRMurr@users.noreply.github.com";
    };
  };

  programs.jjui = {
    enable = true;
  };
}
