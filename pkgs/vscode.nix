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
  # to browse in repl: pkgs.vscode-marketplace.<publisher>.<extension>

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

  # nix-vscode-extensions overlay adds these to pkgs.vscode-marketplace / pkgs.open-vsx.
  # Using the overlay (instead of inputs.nix-vscode-extensions.extensions directly)
  # ensures these evaluate with our nixpkgs config (allowUnfree, etc).

  # https://open-vsx.org/
  openVsxExtensions = with pkgs.open-vsx; [
    pkief.material-icon-theme
    # wayou.vscode-todo-highlight
  ];
  marketPlaceExtensions = with pkgs.vscode-marketplace; [

    aaron-bond.better-comments
    arktypeio.arkdark
    bradlc.vscode-tailwindcss
    eamodio.gitlens
    ianic.zig-language-extras
    ivandemchenko.roc-lang-unofficial
    ms-vscode-remote.remote-ssh
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
      hashicorp.terraform
      haskell.haskell
      jnoortheen.nix-ide
      justusadam.language-haskell
      ms-azuretools.vscode-docker
      ms-python.python
      # ms-vscode-remote.remote-ssh
      ms-vscode.cpptools
      myriad-dreamin.tinymist
      rust-lang.rust-analyzer
      svelte.svelte-vscode
      vadimcn.vscode-lldb
      yzhang.markdown-all-in-one
      ziglang.vscode-zig
    ]
  );

  catppuccinBase = inputs.catppuccin.packages.${pkgs.stdenv.hostPlatform.system}.vscode.override {
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

  # This extension is built from source (the catppuccinOptions override means no
  # cache can have it), so its 581 pnpm deps are fetched on every new version.
  # pnpm defaults to 16 parallel fetches, and against registry.npmjs.org from
  # thicc-server that reliably dies with ETIMEDOUT partway through -- TLS
  # handshakes there take 3-4s and connections drop. Fewer parallel fetches plus
  # a longer timeout gets it through.
  #
  # Safe to tune: a fixed-output derivation is addressed by name and hash, so
  # changing the build script leaves both its path and the extension's unchanged.
  catppucin = catppuccinBase.overrideAttrs (old: {
    pnpmDeps = old.pnpmDeps.override (prev: {
      prePnpmInstall = ''
        pnpm config set network-concurrency 4
        pnpm config set fetch-retries 6
        pnpm config set fetch-retry-mintimeout 20000
        pnpm config set fetch-retry-maxtimeout 120000
        pnpm config set fetch-timeout 300000
      '';
    });
  });

  pestExt = pkgs.vscode-marketplace.pest.pest-ide-tools;

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
