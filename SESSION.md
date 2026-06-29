# Session notes

## Hyprland hyprlang -> Lua migration (branch: hyprland-lua-config)

Done and verified live: ported `common/homemanager/hyprland/default.nix` to
`configType = "lua"` (Hyprland 0.55.4). Workspace switching etc. confirmed.

Catppuccin follow-up done (pending live check): enabled
`catppuccin.hyprland.enable = true` and switched borders/groupbar to reference
the `colors` lua local (`require('themes.catppuccin')`) instead of hardcoded hex.
This also fixed a latent bug — the old active-border gradient was hardcoded
*Frappé* mauve/rosewater while the configured flavor is *mocha*.

### Live check still needed for catppuccin
- [ ] `hyprctl configerrors` clean after switch — specifically that
      `require('themes.catppuccin')` resolves. The generated hyprland.lua has no
      `package.path` setup, so it relies on Hyprland having ~/.config/hypr on the
      Lua path by default. If it errors, add the path (e.g. a small autoLoad
      `extraLuaFiles` entry makes the module emit the package.path prelude).
- [ ] Active border is mocha mauve->rosewater; inactive is surface0.
