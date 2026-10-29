-- Workspace rules and workspace-switching keybindings
-- Verified: wiki.hypr.land/Configuring/Basics/Workspace-Rules/ (July 24, 2026)

local vars = require("hyprland/vars")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- WORKSPACE RULES (layout assignments)
-- "lua:leftscroll" = custom niri-style scrolling layout from leftscroll.lua
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Dynamic, GNOME-style workspaces: no per-workspace layout rules (every
-- workspace uses the global layout) and nothing is persistent, so Hyprland
-- removes a workspace as soon as it is empty and unfocused.

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

-- Relative switching (vertical, trailing empty workspace)
-- Past the last workspace that has windows, go to a fresh empty one.
local function target(dir)
	if dir < 0 then
		return "e-1"
	end
	local active = hl.get_active_workspace()
	if not active then
		return "e+1"
	end
	local last = active.id
	if not last then
		return "e+1"
	end
	for _, ws in ipairs(hl.get_workspaces()) do
		-- id is nil for some workspaces; special ones are not in the sequence
		if ws.id and not ws.special and ws.id > last then
			last = ws.id
		end
	end
	if last == active.id and active.windows > 0 then
		return "empty"
	end
	return "e+1"
end

local function go(dir)
	return function()
		hl.dispatch(hl.dsp.focus({ workspace = target(dir) }))
	end
end

local function send(dir)
	return function()
		hl.dispatch(hl.dsp.window.move({ workspace = target(dir) }))
	end
end

local mainMod = vars.mainMod
hl.bind("CTRL + ALT + up", go(-1))
hl.bind("CTRL + ALT + down", go(1))
hl.bind(mainMod .. " + Prior", go(-1))
hl.bind(mainMod .. " + Next", go(1))
hl.bind(mainMod .. " + bracketleft", go(-1))
hl.bind(mainMod .. " + bracketright", go(1))

-- Move window relative
hl.bind("CTRL + ALT + SHIFT + up", send(-1))
hl.bind("CTRL + ALT + SHIFT + down", send(1))
hl.bind(mainMod .. " + SHIFT + Prior", send(-1))
hl.bind(mainMod .. " + SHIFT + Next", send(1))
