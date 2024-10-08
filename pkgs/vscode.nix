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
    bradlc.vscode-tailwindcss
    eamodio.gitlens
    ianic.zig-language-extras
    ivandemchenko.roc-lang-unofficial
    ms-vscode-remote.remote-ssh-edit
    rreverser.llvm
    skellock.just
    skyapps.fish-vscode
    streetsidesoftware.code-spell-checker
    tamasfe.even-better-toml
    thebearingedge.vscode-sql-lit
    thenuprojectcontributors.vscode-nushell-lang
    unifiedjs.vscode-mdx
    vivaxy.vscode-conventional-commits
    webfreak.debug
    ziglang.vscode-zig
    # znck.grammarly
  ];
  extensionsFromNixPkgs = with pkgs.vscode-extensions; [
    b4dm4n.vscode-nixpkgs-fmt
    bbenoist.nix
    brettm12345.nixfmt-vscode
    dbaeumer.vscode-eslint
    dracula-theme.theme-dracula
    editorconfig.editorconfig
    esbenp.prettier-vscode
    github.vscode-github-actions
    jnoortheen.nix-ide
    ms-azuretools.vscode-docker
    ms-python.python
    ms-vscode-remote.remote-ssh
    ms-vscode.cpptools
    rust-lang.rust-analyzer
    vadimcn.vscode-lldb
    yzhang.markdown-all-in-one
  ];

  catppucin = pkgs.catppuccin-vsc.override {
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

  vscodeExtensions =
    openVsxExtensions ++ marketPlaceExtensions ++ extensionsFromNixPkgs ++ [ catppucin ];

  myVscode = pkgs.vscode-with-extensions.override { inherit vscodeExtensions; };

in
{
  inherit myVscode vscodeExtensions;
}
