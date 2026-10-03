I'll explore the hypr config folder to understand how `leftscroll.lua` should be integrated and what's wrong with the kitty window rules. Launching two read-only exploration agents in parallel.

Both explorations came back with solid findings. Key facts: this is a Hyprland 0.55+ native **Lua** config (entry point `hyprland.lua` with `require()` modules), `leftscroll.lua` registers a custom layout but is **never loaded or activated**, and kitty's "full panel" state is a client-requested maximized state (no rule in this folder causes it). Now let me read the critical files myself to design the integration.

Now let me read `binds.lua` and `vars.lua` to see how the current focus/move/resize binds route through the layout-aware dispatcher.

I have the full picture of the current config. Before designing the plan, I need to verify exact Hyprland 0.55+ Lua API names (window-rule fields for `fullscreenstate`, `hl.dsp.layout`, custom layout registration/naming) against the installed LSP stubs and the wiki — read-only verification so the output code blocks are correct.

The API verification nailed down the details I needed: custom layouts must be referenced as `"lua:leftscroll"` (a bare name silently falls back to dwindle), the kitty fix in the Lua API is `fullscreen_state = "0 0"` plus `suppress_event = "maximize"` (both confirmed valid rule fields in 0.56.2), and `ws.tiled_layout` returns the prefixed name for custom layouts — which `unified-dispatch.lua` currently doesn't know about. Two design choices are genuinely yours before I finalize the plan:

The binds are settled (Super+C / Super+Shift+C); for the skipped layout-scope question I'll go with the recommended full replacement, which is also the easiest to roll back since the native scrolling config block stays in place. Here's the final plan:

Both fixes are verified and the plan is approved. Below is the complete output — six full-file code blocks you can drop in verbatim. No files were edited. (`hyprland/leftscroll.lua` itself needs **no** changes: its registered name and its `ctx.area` handling are correct for Hyprland 0.56.2.)

**What was wrong:**

1. **leftscroll was dead code.** It registers a layout named `leftscroll`, but nothing ever `require`d it, and no config referenced it. Two API subtleties mattered for the integration: custom layouts must be referenced **with the `lua:` prefix** (`"lua:leftscroll"` — a bare name silently falls back to dwindle), and `unified-dispatch.lua` validates the active layout against a hardcoded list that didn't know the new name, so the arrow-key binds would have mis-routed on leftscroll workspaces.
2. **Kitty's "full panel mode"** is not caused by any rule in this folder — live `hyprctl clients` shows every kitty window maps with `fullscreenClient: 1`, i.e. **kitty itself requests maximize** (window covers the work area with gaps/border still drawn, hence "not real fullscreen"). The trigger is on kitty's side (e.g. a start-maximized setting in `~/.config/kitty/kitty.conf` — outside this folder). The Hypr-side fix forces a clean tiled state at map time and ignores client maximize requests.

---

### 1. `hyprland.lua` — load the layout module before anything references it

```lua
-- Hyprland Lua Configuration
-- Migrated from hyprlang to Lua (Hyprland 0.55+)
-- Refer to: https://wiki.hypr.land/Configuring/Start/

-- Module loading order respects dependency graph.
-- Variables shared across modules are defined in vars.lua.
require("hyprland/vars")
require("hyprland/env")
-- Custom layouts must register before settings/workspaces reference them;
-- custom layouts are always addressed with the "lua:" prefix.
require("hyprland/leftscroll")
require("hyprland/settings")
require("hyprland/monitor")
require("hyprland/plugins")
require("hyprland/rules")
require("hyprland/workspaces")
require("hyprland/binds")
require("hyprland/autostart")

-- For Noctalia Color templates
require("noctalia").apply_theme()
```

### 2. `hyprland/settings.lua` — make leftscroll the default layout

```lua
-- General, Decoration, Animations, Input, Gestures, Layouts, Misc, XWayland, Debug
-- Verified against: wiki.hypr.land/Configuring/Basics/Variables/ (July 24, 2026)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- GENERAL
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
hl.config({
  general = {
    gaps_in = 4,
    gaps_out = 7,
    border_size = 3,
    col = {
      active_border = { colors = { "rgba(b8bb26ff)", "rgba(fabd2fff)" }, angle = 45 },
      inactive_border = { colors = { "rgba(3c3836cc)", "rgba(504945cc)" }, angle = 45 },
    },
    layout = "lua:leftscroll",
    resize_on_border = true,
    snap = {
      enabled = true,
    },
  },
})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- DECORATION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
hl.config({
  decoration = {
    rounding = 8,
    rounding_power = 3,
    active_opacity = 1.0,
    inactive_opacity = 1.0,
    fullscreen_opacity = 1,
    dim_inactive = false,
    shadow = {
      enabled = true,
      range = 2,
      render_power = 1,
      color = "rgba(1a1a1aee)",
    },
    blur = {
      enabled = true,
      size = 3,
      passes = 2,
      new_optimizations = true,
      ignore_opacity = true,
      xray = false,
      special = true,
      vibrancy = 0.1696,
      popups = true,
    },
  },
})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ANIMATIONS
-- Verified: hl.curve() for bezier definitions, hl.animation() for animation leaves
-- Legacy format: animation = NAME, ENABLED, SPEED, CURVE, STYLE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
hl.config({
  animations = {
    enabled = true,
  },
})

-- Bezier curve definitions
hl.curve("wind",   { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.curve("winIn",  { type = "bezier", points = { { 0.1, 1.1 }, { 0.1, 1.1 } } })
hl.curve("winOut", { type = "bezier", points = { { 0.3, -0.3 }, { 0, 1 } } })
hl.curve("liner",  { type = "bezier", points = { { 1, 1 }, { 1, 1 } } })

-- Animation leaves
hl.animation({ leaf = "windows",      enabled = true, speed = 4,  bezier = "wind",  style = "popin" })
hl.animation({ leaf = "windowsIn",    enabled = true, speed = 4,  bezier = "winIn", style = "popin" })
hl.animation({ leaf = "windowsOut",   enabled = true, speed = 4,  bezier = "winOut", style = "popin" })
hl.animation({ leaf = "windowsMove",  enabled = true, speed = 4,  bezier = "wind",  style = "slide" })
hl.animation({ leaf = "border",       enabled = true, speed = 1,  bezier = "liner" })
hl.animation({ leaf = "borderangle",  enabled = true, speed = 30, bezier = "liner", style = "once" })
hl.animation({ leaf = "fade",         enabled = true, speed = 4,  bezier = "default" })
hl.animation({ leaf = "workspaces",   enabled = true, speed = 5,  bezier = "wind",  style = "slidevert" })

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- INPUT
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
hl.config({
  input = {
    kb_layout = "us",
    kb_options = "ctrl:nocaps",
    follow_mouse = 1,
    accel_profile = "flat",
    numlock_by_default = true,
    touchpad = {
      natural_scroll = true,
    },
  },
})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- GESTURES
-- Verified: hl.gesture() per wiki Variables page (gestures section)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
hl.gesture({
  fingers = 3,
  direction = "horizontal",
  action = "workspace",
})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LAYOUTS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
hl.config({
  dwindle = {
    preserve_split = true,
    smart_split = true,
    smart_resizing = true,
  },
})

hl.config({
  master = {
    new_status = "master",
  },
})

-- Built-in scrolling layout (Hyprland 0.55+) — kept as a rollback fallback;
-- currently unused (general layout and workspaces 1-3 use "lua:leftscroll").
-- Verified: wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
hl.config({
  scrolling = {
    column_width = 0.40,
    follow_min_visible = 0.33,
    fullscreen_on_one_column = false,
    focus_fit_method = 1,
    direction = "right",
  },
})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- MISC
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
hl.config({
  misc = {
    vrr = 0,
    disable_hyprland_logo = true,
    force_default_wallpaper = 0,
    middle_click_paste = false,
    focus_on_activate = true,
    session_lock_xray = true,
    enable_swallow = true,
    swallow_regex = "^(Alacritty|kitty|footclient)$",
  },
})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- XWAYLAND
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
hl.config({
  xwayland = {
    force_zero_scaling = true,
  },
})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- DEBUG
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
hl.config({
  debug = {
    disable_logs = false,
    enable_stdout_logs = true,
  },
})
```

### 3. `hyprland/workspaces.lua` — leftscroll on the workspaces that used "scrolling"

```lua
-- Workspace rules and workspace-switching keybindings
-- Verified: wiki.hypr.land/Configuring/Basics/Workspace-Rules/ (July 24, 2026)

local vars = require("hyprland/vars")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- WORKSPACE RULES (layout assignments)
-- "lua:leftscroll" = custom niri-style scrolling layout from leftscroll.lua
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
hl.workspace_rule({ workspace = "1", layout = "lua:leftscroll" })
hl.workspace_rule({ workspace = "2", layout = "lua:leftscroll" })
hl.workspace_rule({ workspace = "3", layout = "lua:leftscroll" })
hl.workspace_rule({ workspace = "4", layout = "hy3" })
hl.workspace_rule({ workspace = "5", layout = "hy3" })
hl.workspace_rule({ workspace = "6", layout = "hy3" })
hl.workspace_rule({ workspace = "7", layout = "master" })
hl.workspace_rule({ workspace = "8", layout = "master" })
hl.workspace_rule({ workspace = "9", layout = "monocle" })

-- Named workspaces
hl.workspace_rule({ workspace = "name:research", layout = "lua:leftscroll" })
hl.workspace_rule({ workspace = "name:dev", layout = "hy3" })
hl.workspace_rule({ workspace = "name:comm", layout = "master" })
hl.workspace_rule({ workspace = "name:stage", layout = "lua:leftscroll" })

-- Special workspace rule
hl.workspace_rule({
  workspace = "special:exposed",
  gaps_out = 60,
  gaps_in = 30,
  border_size = 5,
  no_border = false,
  no_shadow = true,
})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- WORKSPACE KEYBINDINGS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Switch Workspaces (Super+1-9)
for i = 1, 9 do
  hl.bind(vars.mainMod .. " + " .. i, hl.dsp.focus({ workspace = tostring(i) }))
end

-- Move Window to Workspace (Super+Shift+1-9)
for i = 1, 9 do
  hl.bind(vars.mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = tostring(i) }))
end

-- Relative switching
hl.bind("CTRL + ALT + down", hl.dsp.focus({ workspace = "+1" }), { repeating = true })
hl.bind("CTRL + ALT + up",   hl.dsp.focus({ workspace = "-1" }), { repeating = true })
hl.bind(vars.mainMod .. " + bracketleft",  hl.dsp.focus({ workspace = "e-1" }))
hl.bind(vars.mainMod .. " + bracketright", hl.dsp.focus({ workspace = "e+1" }))

-- Move window relative
hl.bind("CTRL + SUPER + ALT + up",   hl.dsp.window.move({ workspace = "-1" }))
hl.bind("CTRL + SUPER + ALT + down", hl.dsp.window.move({ workspace = "+1" }))
```

### 4. `hyprland/unified-dispatch.lua` — teach the dispatcher the new layout

Arrow-key focus/move/resize binds keep working unchanged; on leftscroll workspaces they now send the layout's own commands (`movecol`/`movewin`/`resize` instead of the native scrolling layout's `swapcol`/`colresize`, which leftscroll would reject as unknown commands).

```lua
-- ~/.config/hypr/hyprland/unified-dispatch.lua
-- Native Lua replacement for unified-dispatch.py
-- Leverages Hyprland 0.55+ Lua API for zero-overhead layout-aware dispatching.

local M = {}

-- Fallback layout table matching your workspaces.lua definitions
-- (custom layouts keep the "lua:" prefix, exactly as ws.tiled_layout reports them)
local WS_LAYOUT = {
	[1] = "lua:leftscroll",
	[2] = "lua:leftscroll",
	[3] = "lua:leftscroll",
	[4] = "hy3",
	[5] = "hy3",
	[6] = "hy3",
	[7] = "master",
	[8] = "master",
	[9] = "monocle",
}

local function get_active_layout()
	-- Get the active special workspace if one is open, otherwise fallback to the regular active workspace [[32]]
	local ws = hl.get_active_special_workspace() or hl.get_active_workspace()
	if not ws then
		return "dwindle"
	end

	local layout = ws.tiled_layout

	-- Validate against known Hyprland layouts ("lua:leftscroll" is what a
	-- workspace running the custom leftscroll layout reports)
	if layout == "scrolling" or layout == "lua:leftscroll" or layout == "dwindle" or layout == "master" or layout == "monocle" or layout == "hy3" then
		return layout
	end

	-- Fallback to static table if Hyprland returns null/empty or an unknown layout name
	return WS_LAYOUT[ws.id] or "dwindle"
end

function M.dispatch(action, direction)
	if direction ~= "l" and direction ~= "r" and direction ~= "u" and direction ~= "d" then
		print(string.format("Error: direction must be l, r, u, or d (got: %s)", tostring(direction)))
		return
	end

	local layout = get_active_layout()

	-- ACTION: FOCUS
	if action == "focus" then
		if layout == "scrolling" or layout == "lua:leftscroll" then
			hl.dispatch(hl.dsp.layout("focus " .. direction))
		elseif layout == "master" or layout == "monocle" then
			if direction == "r" or direction == "d" then
				hl.dispatch(hl.dsp.layout("cyclenext"))
			else
				hl.dispatch(hl.dsp.layout("cycleprev"))
			end
		else -- dwindle, hy3, and fallback
			hl.dispatch(hl.dsp.focus({ direction = direction }))
		end

		-- ACTION: MOVEWIN
	elseif action == "movewin" then
		if layout == "scrolling" then
			if direction == "l" then
				hl.dispatch(hl.dsp.layout("swapcol l"))
			elseif direction == "r" then
				hl.dispatch(hl.dsp.layout("swapcol r"))
			else
				hl.dispatch(hl.dsp.window.move({ direction = direction }))
			end
		elseif layout == "lua:leftscroll" then
			if direction == "l" or direction == "r" then
				hl.dispatch(hl.dsp.layout("movecol " .. direction))
			else
				hl.dispatch(hl.dsp.layout("movewin " .. direction))
			end
		elseif layout == "master" then
			if direction == "r" or direction == "d" then
				hl.dispatch(hl.dsp.layout("rollnext"))
			else
				hl.dispatch(hl.dsp.layout("rollprev"))
			end
		elseif layout == "monocle" then
			if direction == "r" or direction == "d" then
				hl.dispatch(hl.dsp.layout("cyclenext"))
			else
				hl.dispatch(hl.dsp.layout("cycleprev"))
			end
		else
			hl.dispatch(hl.dsp.window.move({ direction = direction }))
		end

		-- ACTION: RESIZE
	elseif action == "resize" then
		if layout == "scrolling" then
			if direction == "l" then
				hl.dispatch(hl.dsp.layout("colresize -0.05"))
			elseif direction == "r" then
				hl.dispatch(hl.dsp.layout("colresize +0.05"))
			elseif direction == "u" then
				hl.dispatch(hl.dsp.window.resize({ x = 0, y = -60, relative = true }))
			elseif direction == "d" then
				hl.dispatch(hl.dsp.window.resize({ x = 0, y = 60, relative = true }))
			end
		elseif layout == "lua:leftscroll" then
			if direction == "l" then
				hl.dispatch(hl.dsp.layout("resize -0.05"))
			elseif direction == "r" then
				hl.dispatch(hl.dsp.layout("resize +0.05"))
			elseif direction == "u" then
				hl.dispatch(hl.dsp.window.resize({ x = 0, y = -60, relative = true }))
			elseif direction == "d" then
				hl.dispatch(hl.dsp.window.resize({ x = 0, y = 60, relative = true }))
			end
		else
			if direction == "l" then
				hl.dispatch(hl.dsp.window.resize({ x = -60, y = 0, relative = true }))
			elseif direction == "r" then
				hl.dispatch(hl.dsp.window.resize({ x = 60, y = 0, relative = true }))
			elseif direction == "u" then
				hl.dispatch(hl.dsp.window.resize({ x = 0, y = -60, relative = true }))
			elseif direction == "d" then
				hl.dispatch(hl.dsp.window.resize({ x = 0, y = 60, relative = true }))
			end
		end
	else
		print(string.format("Error: unknown action '%s'", tostring(action)))
	end
end

return M
```

### 5. `hyprland/binds.lua` — keybinds for leftscroll's column commands

```lua
-- Keybindings and Submaps
-- Verified: wiki.hypr.land/Configuring/Basics/Binds/ (July 24, 2026)
-- Verified: wiki.hypr.land/Configuring/Basics/Dispatchers/ (July 24, 2026)

local vars = require("hyprland/vars")
local mainMod = vars.mainMod
local unified_dispatch = require("hyprland/unified-dispatch")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ESSENTIALS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(vars.ipc .. "panel-toggle launcher"))
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd(vars.ipc .. " sessionMenu toggle"))
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(vars.terminal))
hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd(vars.pypr .. " toggle term"))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + Space", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + Space", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special(""))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"))

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SCREENSHOT
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
hl.bind("ALT + Print", hl.dsp.exec_cmd(vars.screenshot .. " --region"))
hl.bind("CTRL + Print", hl.dsp.exec_cmd(vars.screenshot .. " --fullscreen"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(vars.screenshot .. " --region"))

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SCRATCHPADS SUBMAP (Super+P → leader)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
hl.bind(mainMod .. " + P", hl.dsp.submap("scratchpads"))

hl.define_submap("scratchpads", function()
	hl.bind("escape", hl.dsp.submap("reset"))
	hl.bind("C", hl.dsp.exec_cmd(vars.pypr .. " toggle calculator"))
	hl.bind("M", hl.dsp.exec_cmd(vars.pypr .. " toggle spotify"))
	hl.bind("Y", hl.dsp.exec_cmd(vars.pypr .. " toggle tuifm"))
	hl.bind("L", hl.dsp.exec_cmd(vars.pypr .. " toggle lazygit"))
	hl.bind("F", hl.dsp.exec_cmd(vars.pypr .. " toggle files"))
	hl.bind("catchall", hl.dsp.submap("reset"), { release = true })
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- GUI APPLICATIONS SUBMAP (Super+G → leader)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
hl.bind(mainMod .. " + G", hl.dsp.submap("guiapps"))

hl.define_submap("guiapps", function()
	hl.bind("escape", hl.dsp.submap("reset"))
	hl.bind("B", hl.dsp.exec_cmd(vars.browser))
	hl.bind("F", hl.dsp.exec_cmd(vars.guifm))
	hl.bind("E", hl.dsp.exec_cmd(vars.editor))
	hl.bind("catchall", hl.dsp.submap("reset"), { release = true })
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TUI APPLICATIONS SUBMAP (Super+T → leader)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
hl.bind(mainMod .. " + T", hl.dsp.submap("tuiapps"))

hl.define_submap("tuiapps", function()
	hl.bind("escape", hl.dsp.submap("reset"))
	hl.bind("Y", hl.dsp.exec_cmd("kitty -e yazi"))
	hl.bind("B", hl.dsp.exec_cmd("kitty -e btop"))
	hl.bind("E", hl.dsp.exec_cmd("kitty -e nvim"))
	hl.bind("catchall", hl.dsp.submap("reset"), { release = true })
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- NOCTALIA LAUNCHERS SUBMAP (Super+Shift+L → leader)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.submap("noctalia_launchers"))

hl.define_submap("noctalia_launchers", function()
	hl.bind("escape", hl.dsp.submap("reset"))
	hl.bind("V", hl.dsp.exec_cmd(vars.ipc .. " launcher clipboard"))
	hl.bind("W", hl.dsp.exec_cmd(vars.ipc .. " launcher windows"))
	hl.bind("period", hl.dsp.exec_cmd(vars.ipc .. " launcher command"))
	hl.bind("SHIFT + period", hl.dsp.exec_cmd(vars.ipc .. " launcher emoji"))
	hl.bind("catchall", hl.dsp.submap("reset"), { release = true })
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- NOCTALIA CORE INTERFACE SUBMAP (Super+N → leader)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
hl.bind(mainMod .. " + N", hl.dsp.submap("noctalia_core"))

hl.define_submap("noctalia_core", function()
	hl.bind("escape", hl.dsp.submap("reset"))
	hl.bind("C", hl.dsp.exec_cmd(vars.ipc .. " controlCenter toggle"))
	hl.bind("comma", hl.dsp.exec_cmd(vars.ipc .. "settings-toggle"))
	hl.bind("A", hl.dsp.exec_cmd(vars.ipc .. " calendar toggle"))
	hl.bind("I", hl.dsp.exec_cmd(vars.ipc .. " systemMonitor toggle"))
	hl.bind("P", hl.dsp.exec_cmd(vars.ipc .. " plugin togglePanel notes-scratchpad"))
	hl.bind("catchall", hl.dsp.submap("reset"), { release = true })
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- NOCTALIA MISC SUBMAP (Super+M → leader)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
hl.bind(mainMod .. " + M", hl.dsp.submap("noctalia_misc"))

hl.define_submap("noctalia_misc", function()
	hl.bind("escape", hl.dsp.submap("reset"))
	-- Persistent toggles
	hl.bind("I", hl.dsp.exec_cmd(vars.ipc .. " idleInhibitor toggle"))
	hl.bind("W", hl.dsp.exec_cmd(vars.ipc .. " wifi toggle"))
	hl.bind("B", hl.dsp.exec_cmd(vars.ipc .. " bluetooth toggle"))
	hl.bind("N", hl.dsp.exec_cmd(vars.ipc .. " nightLight toggle"))
	hl.bind("P", hl.dsp.exec_cmd(vars.ipc .. " powerProfile cycle"))
	-- One-shot actions (auto-reset)
	hl.bind("K", function()
		hl.dispatch(hl.dsp.exec_cmd(vars.ipc .. " lockScreen lock"))
		hl.dispatch(hl.dsp.submap("reset"))
	end)
	hl.bind("X", function()
		hl.dispatch(hl.dsp.exec_cmd(vars.ipc .. " sessionMenu lockAndSuspend"))
		hl.dispatch(hl.dsp.submap("reset"))
	end)
	hl.bind("catchall", hl.dsp.submap("reset"), { release = true })
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- PYPRLAND (Hyprland-specific extras)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
hl.bind(mainMod .. " + CTRL + B", hl.dsp.exec_cmd(vars.pypr .. " expose"))
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd(vars.pypr .. " zoom ++0.5"))
hl.bind(mainMod .. " + SHIFT + Z", hl.dsp.exec_cmd(vars.pypr .. " zoom"))

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- HYPRLAND CORE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
hl.bind(mainMod .. " + BackSpace", hl.dsp.window.pseudo({ action = "toggle" }))
hl.bind(mainMod .. " + slash", hl.dsp.layout("togglesplit"))

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LEFTSCROLL LAYOUT (hyprland/leftscroll.lua — workspaces 1-3, research, stage)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Consume into previous column / expel into a new column (niri-style stacking)
hl.bind(mainMod .. " + C", hl.dsp.layout("consume_or_expel"))
-- One-off centering of the focused column
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.layout("center"))

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- FOCUS & MOVEMENT (Routed natively through unified-dispatch.lua)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
hl.bind(mainMod .. " + left", function()
	unified_dispatch.dispatch("focus", "l")
end)
hl.bind(mainMod .. " + right", function()
	unified_dispatch.dispatch("focus", "r")
end)
hl.bind(mainMod .. " + up", function()
	unified_dispatch.dispatch("focus", "u")
end)
hl.bind(mainMod .. " + down", function()
	unified_dispatch.dispatch("focus", "d")
end)

-- Move Window
hl.bind(mainMod .. " + SHIFT + left", function()
	unified_dispatch.dispatch("movewin", "l")
end)
hl.bind(mainMod .. " + SHIFT + right", function()
	unified_dispatch.dispatch("movewin", "r")
end)
hl.bind(mainMod .. " + SHIFT + up", function()
	unified_dispatch.dispatch("movewin", "u")
end)
hl.bind(mainMod .. " + SHIFT + down", function()
	unified_dispatch.dispatch("movewin", "d")
end)

-- Resize Window
hl.bind(mainMod .. " + CTRL + left", function()
	unified_dispatch.dispatch("resize", "l")
end, { repeating = true })
hl.bind(mainMod .. " + CTRL + right", function()
	unified_dispatch.dispatch("resize", "r")
end, { repeating = true })
hl.bind(mainMod .. " + CTRL + up", function()
	unified_dispatch.dispatch("resize", "u")
end, { repeating = true })
hl.bind(mainMod .. " + CTRL + down", function()
	unified_dispatch.dispatch("resize", "d")
end, { repeating = true })

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- MOUSE SCROLLING
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
hl.bind("CTRL + SUPER + mouse_down", hl.dsp.focus({ workspace = "-10" }))
hl.bind("CTRL + SUPER + mouse_up", hl.dsp.focus({ workspace = "+10" }))
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SPECIAL WORKSPACE & MINIMIZE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
hl.bind(mainMod .. " + minus", hl.dsp.window.move({ workspace = "special:minimized" }))
hl.bind(mainMod .. " + equal", hl.dsp.workspace.toggle_special("minimized"))
hl.bind("CTRL + SUPER + ALT + up", hl.dsp.window.move({ workspace = "special:special" }))
hl.bind("CTRL + SUPER + ALT + down", hl.dsp.window.move({ workspace = "e+0" }))
hl.bind(mainMod .. " + ALT + S", hl.dsp.window.move({ workspace = "special:special" }))

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- AUDIO & BRIGHTNESS
-- bindel = repeating + locked
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(vars.ipc .. "volume-up"), { repeating = true, locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(vars.ipc .. "volume-down"), { repeating = true, locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(vars.ipc .. "volume-mute"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(vars.ipc .. " volume muteInput"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(vars.ipc .. " brightness increase"), { repeating = true, locked = true })
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd(vars.ipc .. " brightness decrease"),
	{ repeating = true, locked = true }
)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LAPTOP LID
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd('hyprctl keyword monitor "eDP-1, disable"'), { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd('hyprctl keyword monitor "eDP-1, disable"'), { locked = true })
```

### 6. `hyprland/rules.lua` — force kitty out of its client-requested maximize

```lua
-- Window Rules, Layer Rules
-- Verified: wiki.hypr.land/Configuring/Basics/Window-Rules/ (July 24, 2026)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- WINDOW RULES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Ghostty transparency
hl.window_rule({
	name = "ghostty_opacity",
	match = { class = "^(com\\.mitchellh\\.ghostty)$" },
	opacity = "0.95 0.95",
})

-- Kitty requests maximize on its own at map time (window covers the whole
-- screen without being real fullscreen). Force a clean tiled state and ignore
-- later client maximize requests. kitty-dropterm is included so its 70%
-- floating size below wins over the maximize request too.
hl.window_rule({
	name = "kitty_no_maximize",
	match = { class = "^(kitty|kitty-dropterm)$" },
	fullscreen_state = "0 0",
	suppress_event = "maximize",
})

-- Kitty drop-terminal
hl.window_rule({
	name = "kitty_floating",
	match = { class = "^(kitty-dropterm)$" },
	size = "70% 70%",
	float = true,
	animation = "slidein",
})

-- Yazi file manager
hl.window_rule({
	name = "yazi_floating",
	match = { class = "^(explorer)$" },
	size = "90% 90%",
	float = true,
	animation = "slidein",
})

-- Nautilus
hl.window_rule({
	name = "nautilus_floating",
	match = { class = "^(org\\.gnome\\.Nautilus)$" },
	float = true,
	animation = "popin",
	size = "1000 800",
})

hl.window_rule({
	name = "shelly_floating",
	match = { class = "^(com\\.shellyorg\\.shelly)$" },
	float = true,
	animation = "popin",
	size = "500 400",
})

hl.window_rule({
	name = "noctalia_settings_floating",
	match = { class = "^(dev\\.noctalia\\.Noctalia)$", title = "^(Noctalia Settings)$" },
	float = true,
	center = true,
	animation = "popin",
	size = "600 600",
})

hl.window_rule({
	name = "lutris floating",
	match = { class = "^(net\\.lutris\\.Lutris)$" },
	float = true,
	center = true,
	animation = "popin",
	size = "1000 800",
})

hl.window_rule({
	name = "bitwarden_floating",
	match = { class = "Bitwarden" },
	float = true,
	center = true,
	animation = "popin",
	size = "800 400",
})

-- BleachBit
hl.window_rule({
	name = "bleachbit_floating",
	match = { class = "^(org\\.bleachbit\\.BleachBit)$" },
	float = true,
	animation = "popin",
	size = "600 600",
	no_blur = true,
	no_anim = true,
})

-- Thunar
hl.window_rule({
	name = "thunar_floating",
	match = { class = "^(thunar)$" },
	float = true,
	animation = "popin",
	size = "800 600",
})

-- Thunar progress bar
hl.window_rule({
	name = "Thunar-Progress-bar",
	match = { class = "^(thunar)$", title = "^(File Operation Progress)$" },
	float = true,
	center = true,
	move = "(cursor_x-(window_w*0.05)) (cursor_y-(window_h*0.6))",
	size = "(monitor_w*0.26) (monitor_h*0.18)",
})

-- qt5ct / qt6ct
hl.window_rule({
	name = "qt5ct_floating",
	match = { class = "^(qt5ct)$" },
	float = true,
	center = true,
	size = "800 600",
})

hl.window_rule({
	name = "qt6ct_floating",
	match = { class = "^(qt6ct)$" },
	float = true,
	center = true,
	size = "800 600",
})

-- nwg-look
hl.window_rule({
	name = "nwg_look",
	match = { class = "^(nwg-look)$" },
	float = true,
	center = true,
	size = "600 400",
})

-- Brave Google sign-in popup
-- hl.window_rule({
-- 	name = "google_signin_popup",
-- 	match = { class = "^(brave-browser)$", title = "^(Untitled - Brave)$" },
-- 	float = true,
-- 	size = "450 600",
-- 	move = "(cursor_x-(window_w*0.5)) (cursor_y-(window_h*0.5))",
-- 	no_blur = true,
-- 	no_anim = true,
-- })

-- Bitwarden popup
hl.window_rule({
	name = "bitwarden_popup",
	match = {
		class = "^(brave-nngceckbapebfimnlniiiahkandclblb-Default)$",
		title = "^(_crx_nngceckbapebfimnlniiiahkandclblb)$",
	},
	float = true,
	size = "450 600",
	move = "(cursor_x-(window_w*0.5)) (cursor_y-(window_h*0.5))",
	no_blur = true,
	no_anim = true,
})

-- xdg-desktop-portal-gtk
hl.window_rule({
	name = "xdg_desktop_portal_gtk",
	match = { class = "^(xdg-desktop-portal-gtk)$" },
	size = "600 600",
	float = true,
	move = "(cursor_x-(window_w*0.05)) (cursor_y-(window_h*0.6))",
	no_blur = true,
})

-- Center all floating windows (not xwayland popups)
hl.window_rule({
	name = "center-floating",
	match = { float = true, xwayland = false },
	center = true,
})

-- Float rules for various apps
hl.window_rule({ match = { class = "org\\.gnome\\.FileRoller" }, float = true })
hl.window_rule({ match = { class = "file-roller" }, float = true })
hl.window_rule({ match = { class = "imv" }, float = true })
hl.window_rule({ match = { class = "system-config-printer" }, float = true })
hl.window_rule({ match = { class = "CachyOSHello" }, float = true })

-- Float, resize and center
hl.window_rule({
	match = { class = "org\\.pulseaudio\\.pavucontrol|yad-icon-browser" },
	float = true,
	size = "60% 70%",
	center = true,
})

-- Dialog rules (match by title)
hl.window_rule({ match = { title = "(Select|Open)( a)? (File|Folder)(s)?" }, float = true })
hl.window_rule({ match = { title = "File (Operation|Upload)( Progress)?" }, float = true })
hl.window_rule({ match = { title = ".* Properties" }, float = true })
hl.window_rule({ match = { title = "Export Image as PNG" }, float = true })
hl.window_rule({ match = { title = "GIMP Crash Debug" }, float = true })
hl.window_rule({ match = { title = "Save As" }, float = true })
hl.window_rule({ match = { title = "Library" }, float = true })

-- Picture-in-Picture
hl.window_rule({
	name = "Picture-in-Picture",
	match = { title = "^(Picture-in-Picture)$" },
	float = true,
	move = "72% 7%",
	opacity = "0.95 0.75",
	pin = true,
	keep_aspect_ratio = true,
	size = "(monitor_w*0.3) (monitor_h*0.3)",
})

-- XWayland popup cosmetics
hl.window_rule({
	match = { xwayland = true, title = "win[0-9]+" },
	no_dim = true,
	no_shadow = true,
	rounding = 10,
})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LAYER RULES
-- Verified: wiki.hypr.land/Configuring/Basics/Window-Rules/ (Layer Rules section)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Noctalia Shell blur
hl.layer_rule({
	name = "noctalia",
	match = { namespace = "noctalia-background-.*$" },
	ignore_alpha = 0.5,
	blur = true,
	blur_popups = true,
})

-- Other blur layers (rofi, notifications, quickshell)
hl.layer_rule({
	name = "blur_layers",
	match = { namespace = "^(rofi|notifications|quickshell:.*)$" },
	blur = true,
	ignore_alpha = 1,
})

-- Disable animation for gtk4-layer-shell
hl.layer_rule({
	match = { namespace = "gtk4-layer-shell" },
	no_anim = true,
})
```

---

## Applying and verifying

Copy each block over its file, then run `hyprctl reload` (or Super+Shift+R). Verify with:

1. `hyprctl getoption general:layout` → should print `string: lua:leftscroll` (if it shows `dwindle`, the `lua:` prefix got lost — a bare `leftscroll` silently falls back to dwindle).
2. Open kitty on workspace 1: it should now tile as a normal column flush against the left edge (leftscroll behavior), and `hyprctl clients` should show `fullscreen: 0, fullscreenClient: 0` for it. The drop-terminal (Super+Shift+Return) keeps its 70% floating size.
3. Try the layout keys: arrows to focus/move (routed through the updated dispatcher), Super+Ctrl+arrows to resize columns, Super+C to stack/unstack a window into a column, Super+Shift+C to center once.

Two notes: the kitty maximize request originates in kitty's own configuration (likely a start-as-maximized setting or wrapper flag in `~/.config/kitty/kitty.conf` — outside this folder, so fixing it there would address the root cause), and if you ever want native scrolling back, just flip `general.layout` and the five workspace rules back to `"scrolling"` — the `scrolling = {...}` config block was kept for exactly that rollback.

## Goal

Produce a markdown answer (in chat) with **full file contents in lua code blocks** — no files get edited, per your request. Two problems fixed:

### 1. Integrate `hyprland/leftscroll.lua` (currently dead code)

`leftscroll.lua` registers layout `"leftscroll"` but nothing loads or activates it. Integration (verified against Hyprland 0.56.2 stubs/source + wiki):

- **hyprland.lua** — add `require("hyprland/leftscroll")` after `env`, before `settings` (registration must precede any layout reference).
- **settings.lua** — `general.layout = "scrolling"` → `"lua:leftscroll"`. Critical: custom layouts must be referenced **with the `lua:` prefix**; a bare name silently falls back to dwindle. The native `scrolling = {...}` config block stays as an inert rollback fallback.
- **workspaces.lua** — workspaces 1–3 plus named `research`/`stage` switch `"scrolling"` → `"lua:leftscroll"` (full replacement, per recommendation). hy3/master/monocle untouched.
- **unified-dispatch.lua** — teach the layout-aware dispatcher the new layout: accept `"lua:leftscroll"` in the validation list (that's exactly what `ws.tiled_layout` returns for custom layouts), update the `WS_LAYOUT` fallback table, and add dispatch branches: focus → `layout("focus <dir>")`; movewin → `layout("movecol <dir>")` (l/r) / `layout("movewin <dir>")` (u/d); resize → `layout("resize ∓0.05")` (l/r) with vertical `window.resize` for u/d. Existing arrow-key binds keep working unchanged.
- **binds.lua** — new section: `Super+C` → `hl.dsp.layout("consume_or_expel")`, `Super+Shift+C` → `hl.dsp.layout("center")`. (Super+X/Super+Z from the file's header suggestion are taken, as you confirmed.)

`leftscroll.lua` itself needs no changes (its `ctx.area` {x,y,w,h} assumption is confirmed correct against `HL.Box`).

### 2. Fix kitty "full panel" opening

Live session evidence: every kitty client maps with `fullscreen: 1, fullscreenClient: 1` — a **client-requested maximize** (covers the work area without being real fullscreen; gaps/border stay visible). No rule in this folder causes it; the trigger is kitty-side (e.g. a start-maximized setting in `~/.config/kitty/kitty.conf` — outside this folder's scope, worth checking later). Hypr-side fix in **rules.lua**, a static rule:

```lua
hl.window_rule({
	name = "kitty_no_maximize",
	match = { class = "^(kitty|kitty-dropterm)$" },
	fullscreen_state = "0 0",
	suppress_event = "maximize",
})
```

`fullscreen_state = "0 0"` (string "internal client", the correct Lua-API field) forces the window to map with no maximized/fullscreen state; `suppress_event = "maximize"` ignores subsequent client maximize requests. Both classes covered so the pypr drop-terminal also keeps its 70% floating size. Hyprland's own Super+Shift+Space maximize toggle (a dispatcher, not a client event) still works.

### Files to output (6 full-file code blocks)

`hyprland.lua`, `hyprland/settings.lua`, `hyprland/workspaces.lua`, `hyprland/unified-dispatch.lua`, `hyprland/binds.lua`, `hyprland/rules.lua` — each preceded by a short what/why note. Plus a short "how to apply & verify" note (copy files → `hyprctl reload`, check `hyprctl getoption general:layout`, open kitty on ws 1, watch for the leftscroll left-flush column behavior).
