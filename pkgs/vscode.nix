{
  pkgs,
  lib,
  inputs,
  ...
}:
# TODO: should move this to use the HM module...
# TODO: steal from https://gist.github.com/JRMurr/069efda89957a221cf717a8caa988819
let
  # https://github.com/nix-community/nix-vscode-extensions
  # to browse
  # `nix repl`
  # :lf .
  # inputs.nix-vscode-extensions.extensions.x86_64-linux.open-vsx.<thing>

  # TODO: go through and use nix pkgs version for these if they exist
  exportedExtensions = [
    "aaronduino.nix-lsp"
    "andrsdc.base16-themes"
    "bceskavich.theme-dracula-at-night"
    "bradlc.vscode-tailwindcss"
    "brettm12345.nixfmt-vscode"
    "bungcip.better-toml"
    "dbaeumer.vscode-eslint"
    "dioxuslabs.dioxus"
    "dlasagno.rasi"
    "donjayamanne.githistory"
    # "dracula-theme.theme-dracula"
    "editorconfig.editorconfig"
    "esbenp.prettier-vscode"
    "golang.go"
    "haskell.haskell"
    "hyesun.py-paste-indent"
    "ivandemchenko.roc-lang-unofficial"
    "jnoortheen.nix-ide"
    "jock.svg"
    "jryans.base16-themes"
    "justusadam.language-haskell"
    "lextudio.restructuredtext"
    "mechatroner.rainbow-csv"
    "mikestead.dotenv"
    "mkhl.direnv"
    "ms-dotnettools.csharp"
    "ms-dotnettools.vscode-dotnet-runtime"
    "ms-python.python"
    "ms-vscode-remote.remote-ssh"
    # "ms-vscode-remote.remote-ssh-edit"
    # "ms-vscode.cpptools"
    "pkief.material-icon-theme"
    "skellock.just"
    "skyapps.fish-vscode"
    "streetsidesoftware.code-spell-checker"
    "tamasfe.even-better-toml"
    "valentjn.vscode-ltex"
    "waderyan.gitblame"
    "yycalm.linecount"
    # "znck.grammarly"
  ];

  linuxExtensions = inputs.nix-vscode-extensions.extensions.x86_64-linux;
  # https://open-vsx.org/
  openVsxExtensions = with linuxExtensions.open-vsx; [
    pkief.material-icon-theme
    # wayou.vscode-todo-highlight
  ];
  marketPlaceExtensions = with linuxExtensions.vscode-marketplace; [

    aaron-bond.better-comments
    arktypeio.arkdark
    bradlc.vscode-tailwindcss
    eamodio.gitlens
    ianic.zig-language-extras
    ivandemchenko.roc-lang-unofficial
    redhat.vscode-yaml
    rreverser.llvm
    skellock.just
    skyapps.fish-vscode
    streetsidesoftware.code-spell-checker
    tamasfe.even-better-toml
    thebearingedge.vscode-sql-lit
    thenuprojectcontributors.vscode-nushell-lang
    unifiedjs.vscode-mdx
    vitest.explorer
    vivaxy.vscode-conventional-commits
    webfreak.debug

    # znck.grammarly
  ];

  extensionsFromNixPkgs = (
    with pkgs.vscode-extensions;
    [
      b4dm4n.vscode-nixpkgs-fmt
      bbenoist.nix
      brettm12345.nixfmt-vscode
      dbaeumer.vscode-eslint
      dracula-theme.theme-dracula
      editorconfig.editorconfig
      esbenp.prettier-vscode
      github.vscode-github-actions
      haskell.haskell
      jnoortheen.nix-ide
      justusadam.language-haskell
      ms-azuretools.vscode-docker
      ms-python.python
      ms-vscode-remote.remote-ssh
      ms-vscode.cpptools
      myriad-dreamin.tinymist
      rust-lang.rust-analyzer
      svelte.svelte-vscode
      vadimcn.vscode-lldb
      yzhang.markdown-all-in-one
      ziglang.vscode-zig
    ]
  );

  catppucin = inputs.catppuccin.packages.${pkgs.stdenv.hostPlatform.system}.vscode.override {
    catppuccinOptions = {
      accent = "mauve";
      boldKeywords = true;
      italicComments = true;
      italicKeywords = true;
      extraBordersEnabled = false;
      workbenchMode = "default";
      bracketMode = "rainbow";
      colorOverrides = { };
      customUIColors = { };
    };
  };

  pestExt = linuxExtensions.vscode-marketplace.pest.pest-ide-tools;

  # copying override logic from rust analyzer
  # https://github.com/NixOS/nixpkgs/blob/107d5ef05c0b1119749e381451389eded30fb0d5/pkgs/applications/editors/vscode/extensions/rust-lang.rust-analyzer/default.nix#L87
  customPest = pestExt.overrideAttrs (
    let
      # pestIdeTools.serverPath": "/path/to/binary",
      ide = "${pkgs.pest-ide-tools}/bin/pest-language-server";
      jq = "${pkgs.jq}/bin/jq";
      sponge = "${pkgs.moreutils}/bin/sponge";
    in
    {
      preInstall = ''
        ${jq} '(.contributes.configuration[] | select(.title == "Pest IDE Tools") | .properties."pestIdeTools.serverPath".default) = $s' \
          --arg s "${ide}" \
          package.json | ${sponge} package.json
      '';
    }
  );

  vscodeExtensions =
    openVsxExtensions
    ++ marketPlaceExtensions
    ++ extensionsFromNixPkgs
    ++ [
      catppucin
      customPest
    ];

  myVscode = pkgs.vscode-with-extensions.override { inherit vscodeExtensions; };

in
{
  inherit myVscode vscodeExtensions;
}
