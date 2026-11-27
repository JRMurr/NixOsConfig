{
  pkgs,
  lib,
  config,
  ...
}:
let
  skills = config.myOptions.llm.skills;
  rexEnabled = builtins.elem "rex" skills;

  # What `rex skill setup` writes: a stub that defers to the installed CLI,
  # so the guide tracks the Rex version.
  rexSkill = pkgs.writeTextDir "SKILL.md" ''
    ---
    name: rex
    description: Use the rex CLI to manage Rex sessions, open tabs, arrange panes, run commands, inspect terminal output, and control connected Rex apps.
    metadata:
      rex-stub: "2"
    ---
    <!-- Managed by home-manager (common/homemanager/llms/claude). -->

    Run `rex __internal skill --feature-session-naming=false` and follow the guide it prints. The guide comes from
    the installed Rex CLI, so it describes the commands available in that version.

    If the command fails, the installed Rex version predates the guide. Start with
    `rex whoami --json`, then use `rex --help` and `rex COMMAND --help`.
  '';

  # Shows PNG/SVG/Markdown in a reused split pane beside the agent's Rex pane.
  # Converters ride along on PATH; the viewer inherits it.
  rexShow = pkgs.writeShellScriptBin "rex-show" ''
    export PATH=${
      lib.makeBinPath [
        pkgs.rex
        pkgs.librsvg
        pkgs.pandoc
        pkgs.typst
        pkgs.mermaid-cli
      ]
    }:$PATH
    exec ${pkgs.python3}/bin/python3 ${./rex-show.py} "$@"
  '';

  rexShowSkill = pkgs.writeTextDir "SKILL.md" ''
    ---
    name: rex-show
    description: Show the user graphics (charts, plots, diagrams, rendered Markdown, live dashboards) in a Rex split pane beside you. Use when a visual would explain data, structure, architecture, or results better than text, or to preview a README, while working in a Rex terminal.
    ---
    <!-- Managed by home-manager (common/homemanager/llms/claude). -->

    `rex-show FILE` shows FILE in a split pane labeled "Graphics" right of your
    pane (`$REX_BLOCK`), via the kitty graphics protocol. Prints the pane's
    block ID. Later calls retarget the same pane. Close with
    `rex block close ID` when done.

    FILE may be:
    - **PNG** or **SVG** (rasterized at pane width, stays sharp).
    - **Markdown** (`.md`): rendered dark, with ```` ```mermaid ```` blocks as
      diagrams. Relative image paths resolve against the file's dir. Use it to
      explain things (write a short doc with diagrams to your scratchpad) or to
      preview a README. First Mermaid render takes ~20s.

    The pane watches FILE and redraws when it changes:
    - **Live views**: rewrite the file in a loop (write a temp file, then
      `os.replace` it) from a producer started as `rex-show FILE -- CMD...`.
      CMD runs detached with your env and is killed when the pane closes;
      don't background producers yourself. Output goes to
      `$XDG_RUNTIME_DIR/rex-show/*/producer.log`.
    - Producers are display-only. Never run real work (builds, tests,
      servers) as a producer: closing a view must not kill it. Run the work
      in its own pane (`rex run`/`rex split --keep-open`) or your shell,
      writing a log; the producer only reads that log and renders.
    - **Editing docs**: the README preview updates on each save.
    - **Live docs**: a Markdown doc embedding a live image (`![cpu](/abs/cpu.png)`)
      redraws as the image changes (~0.4s per frame), so prose, diagrams and
      live charts can share one pane.

    Tall content scrolls. Keys go to the pane: `rex send-key -b ID KEY` with
    j/k, down/up, space/pagedown, b/pageup, g (top), shift+g (bottom). The
    caption line shows the scroll %, readable with `rex capture -b ID`.

    Producing content (tools not installed globally; pull per call):
    - Plots: `nix shell --impure --expr 'with import (builtins.getFlake "nixpkgs") {}; python3.withPackages (p: [p.matplotlib p.numpy])' -c python3 script.py`
    - Diagrams: D2 (`nix shell nixpkgs#d2 -c d2 --theme 200 in.d2 out.svg`),
      graphviz (`nix shell nixpkgs#graphviz -c dot -Tsvg in.dot -o out.svg`), or
      Mermaid inside Markdown. Don't feed Mermaid's own SVG to rex-show; its
      HTML labels don't rasterize.

    Guidelines:
    - Work files go in your scratchpad directory.
    - Dark backgrounds (`plt.style.use("dark_background")`, D2 theme 200).
    - Read the rendered PNG yourself before showing it; `rex capture` cannot
      see images. On a render failure, the caption says so; details are in
      `$XDG_RUNTIME_DIR/rex-show/*/viewer.log`.
  '';

  # Tells the agent which Rex session/terminal it is in. Silent outside Rex.
  rexHook = {
    hooks = [
      {
        type = "command";
        command = "${pkgs.rex}/bin/rex __internal session-start --agent claude --feature-session-naming=false 2>/dev/null || true";
        timeout = 5;
      }
    ];
  };

  skillSources = {
    agent-browser = "${pkgs.llm-agents.agent-browser.src}/skills/agent-browser";
    hegel = "${pkgs.hegel-skill}/skills/hegel";
    i-have-adhd = "${pkgs.i-have-adhd-skill}/skills/i-have-adhd";
    rex = "${rexSkill}";
    rex-show = "${rexShowSkill}";
  };

  skillFiles = lib.mapAttrs' (name: source: {
    name = ".claude/skills/${name}";
    value = {
      inherit source;
      recursive = true;
    };
  }) (lib.getAttrs skills skillSources);
in
{
  programs.claude-code = {
    enable = true;
    package = pkgs.llm-agents.claude-code;
    skills = { };

    # settings.json stays writable; declared keys are merged in on each switch
    # and win over in-app edits. Arrays are replaced, so SessionStart hooks
    # belong here, not in the file. Everything else is Claude's to manage.
    mutableSettings = true;
    settings.hooks.SessionStart = lib.optional rexEnabled rexHook;

    mcpServers = {
      # nixos = {
      #   command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
      # };
      backlog = {
        type = "stdio";
        command = "backlog";
        args = [ "mcp" "start" ];
        env = { };
      };
    };
    context = ../memory.md;
  };

  home.file = skillFiles // {
    ".config/ccstatusline/settings.json".text = builtins.toJSON {
      version = 4;
      lines = [
        [
          { id = "1"; type = "model"; color = "cyan"; }
          { id = "2"; type = "separator"; }
          { id = "3"; type = "context-length"; color = "brightBlack"; }
          { id = "4"; type = "separator"; }
          { id = "5"; type = "git-branch"; color = "magenta"; }
          { id = "6"; type = "separator"; }
          { id = "7"; type = "git-changes"; color = "yellow"; }
          { id = "a5faa01e-18da-4ddc-b105-086822e66d9d"; type = "separator"; }
          { id = "b579ea7b-54b0-438c-837f-7875f740c361"; type = "output-style"; }
        ]
        [
          { id = "4a714199-de29-4bfa-9b47-47adbde22603"; type = "tokens-cached"; color = "yellow"; }
          { id = "29af9665-ccae-44a6-80b5-c304b1fb75ec"; type = "separator"; }
          { id = "78890ee1-29a2-4654-919b-a17d9f134510"; type = "tokens-total"; }
          { id = "19271ee5-4b52-4af5-8492-78e3aa3fb8fb"; type = "separator"; }
          { id = "87cbd4ab-efcd-4fd5-9f0c-7d0ab2ab4ee5"; type = "session-cost"; }
          { id = "9b8276a3-b6c6-425d-b9de-bdebf9e7a483"; type = "flex-separator"; }
          { id = "80782c4f-f16c-4eff-82a5-e5ef3b64fd27"; type = "block-timer"; }
          { id = "5b3c093c-1495-4db4-9bcf-09a068b89b98"; type = "separator"; }
          { id = "273ee9f5-7e76-4298-a679-33c13b50bb3a"; type = "session-clock"; }
        ]
        [ ]
        [ ]
      ];
      flexMode = "full-minus-40";
      compactThreshold = 60;
      colorLevel = 3;
      inheritSeparatorColors = false;
      globalBold = false;
      powerline = {
        enabled = false;
        separators = [ "" ];
        separatorInvertBackground = [ false ];
        startCaps = [ ];
        endCaps = [ ];
        autoAlign = false;
      };
    };
  };

  home.packages = [
    pkgs.llm-agents.ccstatusline
  ] ++ lib.optional (builtins.elem "rex-show" skills) rexShow;
}
