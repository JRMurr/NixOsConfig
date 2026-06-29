# Session notes

## Hyprland hyprlang -> Lua migration (branch: hyprland-lua-config)

Ported `common/homemanager/hyprland/default.nix` to `configType = "lua"` (Hyprland
0.55+). Builds clean for `desktop` + `framework`; generated `hyprland.lua` passes a
LuaJIT parse check. Still needs a **live-session test** — build/parse can't confirm
runtime semantics. Things to eyeball after `nh os switch`:

- [ ] Workspace switching: `hl.dsp.focus({ workspace = N })` actually changes
      workspace (wiki had a stale `hl.workspace(N)` example; the stubs only expose
      `hl.dsp.focus`). Highest-uncertainty item.
- [ ] Window-rule `size = {1100,1100}` (vec2 table) and `opacity = "0.95"` (string
      multiplier) take effect on pavucontrol / the kitty special workspace.
- [ ] Border gradient `col.active_border = { colors = {...}, angle = 45 }` renders.
- [ ] Two separate `hl.on("hyprland.start", ...)` handlers both fire (one is the
      module's systemd-activation hook, one is our autostart). If only one runs,
      fold our startup execs into the module's mechanism.
- [ ] `movewindoworgroup` replacement `hl.dsp.window.move({ direction, group_aware = true })`
      behaves like the old dispatcher.

### Follow-up (deliberately deferred, not done here)
- Re-enable `catppuccin.hyprland.enable = true` and drop the manual palette wiring
  (`col.active_border` gradient + `group.groupbar` rgb() values). Works now that
  we're on `configType = "lua"` (the module emits `local colors =
  require('themes.catppuccin')`). Do as its own tested change.
- Dropped the unused `$terminal` / `$fileManager` / `$menu` variables during the
  port (they were defined but never referenced).
