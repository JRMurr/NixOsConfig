{
  lib,
  python3Packages,
  rex,
  librsvg,
  pandoc,
  typst,
  mermaid-cli,
}:

let
  # On PATH for the CLI and, via it, the viewer.
  converters = [
    rex
    librsvg
    pandoc
    typst
    mermaid-cli
  ];
in
python3Packages.buildPythonApplication {
  pname = "rex-show";
  version = "0.1.0";
  pyproject = true;

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./pyproject.toml
      ./src
      ./tests
      ./SKILL.md
    ];
  };

  build-system = [ python3Packages.setuptools ];

  makeWrapperArgs = [
    "--prefix"
    "PATH"
    ":"
    (lib.makeBinPath converters)
  ];

  # Render tests use these; Mermaid needs a browser, so it's left out.
  nativeCheckInputs = [
    python3Packages.pytestCheckHook
    python3Packages.hypothesis
    librsvg
    pandoc
    typst
  ];
  preCheck = ''
    export HOME=$TMPDIR
  '';

  postInstall = ''
    install -Dm644 SKILL.md $out/share/rex-show/skill/SKILL.md
  '';

  meta = {
    description = "Show PNG, SVG and Markdown in a Rex split pane via the kitty graphics protocol";
    mainProgram = "rex-show";
    platforms = lib.platforms.linux;
  };
}
