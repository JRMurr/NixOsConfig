{ pkgs, lib, inputs, ... }:
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
    "ms-vscode.cpptools"
    "pkief.material-icon-theme"
    "skellock.just"
    "skyapps.fish-vscode"
    "streetsidesoftware.code-spell-checker"
    "tamasfe.even-better-toml"
    "valentjn.vscode-ltex"
    "waderyan.gitblame"
    "yycalm.linecount"
    "znck.grammarly"
  ];

  linuxExtensions = inputs.nix-vscode-extensions.extensions.x86_64-linux;
  # https://open-vsx.org/
  openVsxExtensions = with linuxExtensions.open-vsx; [
    pkief.material-icon-theme
    wayou.vscode-todo-highlight
    waderyan.gitblame
    # bungcip.better-toml
  ];
  marketPlaceExtensions = with linuxExtensions.vscode-marketplace; [
    skyapps.fish-vscode
    thenuprojectcontributors.vscode-nushell-lang
    skellock.just
    thebearingedge.vscode-sql-lit
    ms-vscode-remote.remote-ssh-edit
    ivandemchenko.roc-lang-unofficial
    tamasfe.even-better-toml

    vivaxy.vscode-conventional-commits
  ];
  extensionsFromNixPkgs = with pkgs.vscode-extensions; [
    github.vscode-github-actions
    bbenoist.nix
    dracula-theme.theme-dracula
    ms-azuretools.vscode-docker
    ms-python.python
    ms-vscode-remote.remote-ssh
    rust-lang.rust-analyzer
    yzhang.markdown-all-in-one
    editorconfig.editorconfig
    brettm12345.nixfmt-vscode
    jnoortheen.nix-ide
    b4dm4n.vscode-nixpkgs-fmt
    dbaeumer.vscode-eslint
    esbenp.prettier-vscode
    vadimcn.vscode-lldb
  ];

  vscodeExtensions = openVsxExtensions ++ marketPlaceExtensions
    ++ extensionsFromNixPkgs;

  myVscode = pkgs.vscode-with-extensions.override { inherit vscodeExtensions; };

in { inherit myVscode vscodeExtensions; }
