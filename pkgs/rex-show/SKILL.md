---
name: rex-show
description: Show the user graphics (charts, plots, diagrams, rendered Markdown, live dashboards) in a Rex split pane beside you. Use when a visual would explain data, structure, architecture, or results better than text, or to preview a README, while working in a Rex terminal.
---

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

The user can zoom and pan: +/-/0 (alt+wheel) zoom in/out/reset,
hjkl/arrows (click-drag, wheel, shift+wheel) pan, space/b page, g/G
top/bottom. SVG and Markdown re-render per zoom level, so big plots (e.g.
`systemd-analyze plot`) are explorable. To drive it yourself:
`rex send-key -b ID KEY` (`plus`, `l`, `shift+g`; `rex send -b ID -- -`
for minus). The caption shows zoom and x/y %, readable with
`rex capture -b ID`.

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
