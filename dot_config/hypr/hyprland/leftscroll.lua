--[[
  leftscroll.lua — a niri-style scrolling layout for Hyprland 0.56+ Lua config

  Behavior (mirrors niri's scrolling layout — wiki + src/layout/scrolling.rs):
    * Windows are arranged in COLUMNS on a horizontal tape, left -> right.
      The layout owns the ordering; the order the compositor reports targets
      in is insertion order and gets churned (assign/float/DnD re-append), so
      it is never trusted.
    * A new window opens in a new column immediately RIGHT of the focused
      column; on an empty workspace the first column is index 1 and the
      camera sits at offset 0 — flush against the left edge.
    * The compositor focuses the new window; the camera scrolls the MINIMUM
      distance that makes the focused column fully visible (no move if it
      already is; columns wider than the view are left-aligned) — niri's
      compute_new_view_offset, ported.
    * Camera follows real focus even for focus changes that never trigger a
      recalculate (mouse click, alt-tab), via a window.active event hook.
    * Columns can stack windows vertically (consume/expel), per-column
      resizable widths with preset cycling.

  Verified API facts (Hyprland 0.56.2 source):
    * ctx = { area = {x,y,w,h}, targets, column/row/grid_cell/split } — there
      is NO ctx.workspace; the workspace key comes from
      target.window.workspace.id (full HL.Window, same metatable as the main
      API, so stable_id/address/workspace/active are all available).
    * window.stable_id is a per-boot monotonic counter assigned in the window
      constructor — stable for the window's lifetime.
    * recalculate fires on map/close/float/DnD/swap/resize/workspace-switch/
      monitor changes, but NOT on focus change; layout_msg is ALWAYS followed
      by a C++ recalculate — that is what the "sync" nudge relies on.
    * place() accepts boxes partially off-screen (negative x / beyond width);
      the compositor itself insets general:gaps_in on sides not flush with
      the work area, so columns are placed flush against each other.
    * Layout callbacks run on a 50 ms watchdog; recalculate must never
      dispatch (no re-entrancy guard exists). Only layout_msg and the event
      hook dispatch.

  Command surface (wired from binds.lua / unified-dispatch.lua — do not rename):
    focus l|r|u|d      move focus; camera follows
    movecol l|r        swap the focused column with its neighbor
    movewin u|d        reorder the focused window within its column
    resize [+conf|-conf|+|-|+N|-N|N]   column width (fraction of work area)
    consume            top window of the column to the RIGHT joins the bottom
                       of the focused column (niri consume-window-into-column)
    expel              bottom window of the focused column out into a new
                       column to its right (niri expel-window-from-column)
    consume_or_expel   focused window: if its column stacks, it is expelled
                       into a new column right of its column-mates; if it is
                       solo, it merges into the END of the LEFT neighbor
                       (focus follows the moved window)
    center             one-off centering of the focused column
    sync               internal no-op used by the focus hook (recalculate
                       always follows a layout_msg)
]]

-- ============================================================
-- Tunables
-- ============================================================
local CONFIG = {
	default_width = 0.4, -- fraction of work-area width for a new column
	min_width = 0.1,
	max_width = 1.0,
	width_step = 0.05, -- used by bare "resize +" / "resize -"
	width_presets = { 0.333, 0.5, 0.667, 1.0 }, -- cycled by resize +conf/-conf
	wrap_focus = false, -- niri does not wrap; looping is opt-in here
	fallback_gaps = 4, -- used if general.gaps_in cannot be read
}

-- ============================================================
-- Defensive field access (Lua-bound objects may raise on unknown fields)
-- ============================================================
local function safe_get(obj, field)
	if obj == nil then
		return nil
	end
	local ok, val = pcall(function()
		return obj[field]
	end)
	if ok then
		return val
	end
	return nil
end

-- ============================================================
-- Identity and workspace keying
--
-- Window identity: stable_id (per-boot monotonic, assigned once in the
-- constructor — source-verified), address as fallback. The compositor's
-- target list carries no workspace field, so the workspace key is derived
-- from any target's window.workspace.id. Without a key we do NOTHING rather
-- than polluting a shared "default" namespace (the old layout's fatal flaw).
-- ============================================================
local function window_id(win)
	local sid = safe_get(win, "stable_id")
	if sid ~= nil then
		return tostring(sid)
	end
	local addr = safe_get(win, "address")
	if addr ~= nil then
		return "addr:" .. tostring(addr)
	end
	return nil
end

local function resolve_ws_key(ctx)
	for _, t in ipairs(ctx.targets or {}) do
		local win = safe_get(t, "window")
		if win then
			local wsobj = safe_get(win, "workspace")
			local id = wsobj and safe_get(wsobj, "id")
			if id ~= nil then
				return tostring(id)
			end
		end
	end
	return nil
end

-- ============================================================
-- Per-workspace state
--   ws = {
--     columns    = { { ids = {win_id, ...}, width = frac, focus = idx }, ... },
--     focusedCol = index into columns,
--     offset     = camera position in tape coordinates (0 = tape left edge
--                  at the work area's left edge),
--   }
-- ============================================================
local workspaces = {}

local function get_ws(key)
	local s = workspaces[key]
	if not s then
		s = { columns = {}, focusedCol = 1, offset = 0 }
		workspaces[key] = s
	end
	return s
end

-- ============================================================
-- Sync: reconcile ws.columns against the live target set.
-- Identities are stable, so this is a pure set-diff: survivors keep their
-- order, closed windows drop (focus shifts like niri: the column that slides
-- into the vacated spot takes focus), brand-new windows become columns right
-- of the focused one. ctx.targets order is only used to sequence multiple
-- brand-new windows (cold start after a config reload — the Lua state is
-- rebuilt on reload).
-- Returns id -> target for placement and command handling.
-- ============================================================
local function sync(ctx, ws)
	local targetsById, live = {}, {}
	for _, t in ipairs(ctx.targets) do
		local win = safe_get(t, "window")
		local id = win and window_id(win)
		if id then
			targetsById[id] = t
			live[id] = true
		end
	end

	-- Drop closed windows / emptied columns. origIdx maps surviving column
	-- references to their index before the pass, for the focus-shift rule.
	local origIdx = {}
	local kept, focusedRef = {}, ws.columns[ws.focusedCol]
	for idx, col in ipairs(ws.columns) do
		local ids = {}
		for _, id in ipairs(col.ids) do
			if live[id] then
				table.insert(ids, id)
			end
		end
		if #ids > 0 then
			col.ids = ids
			if col.focus > #ids then
				col.focus = #ids
			end
			origIdx[col] = idx
			table.insert(kept, col)
		end
	end
	ws.columns = kept

	-- Focus after removals: the focused column keeps focus wherever it moved;
	-- if it was removed, focus lands on the survivor that took its place
	-- (the first one that used to sit right of it), else the last column.
	local newFocus = nil
	if focusedRef then
		for i, col in ipairs(kept) do
			if col == focusedRef then
				newFocus = i
				break
			end
		end
	end
	if not newFocus then
		local fallback = nil
		for i, col in ipairs(kept) do
			if origIdx[col] > ws.focusedCol then
				fallback = i
				break
			end
		end
		if not fallback then
			fallback = #kept
		end
		newFocus = math.max(1, fallback)
	end
	ws.focusedCol = newFocus

	-- Insert brand-new windows as their own column right of the focused one
	-- (niri: active_column_idx + 1; index 1 on an empty workspace).
	local known = {}
	for _, col in ipairs(ws.columns) do
		for _, id in ipairs(col.ids) do
			known[id] = true
		end
	end
	for _, t in ipairs(ctx.targets) do
		local win = safe_get(t, "window")
		local id = win and window_id(win)
		if id and not known[id] then
			local newCol = { ids = { id }, width = CONFIG.default_width, focus = 1 }
			local insertAt = (#ws.columns == 0) and 1 or (ws.focusedCol + 1)
			table.insert(ws.columns, insertAt, newCol)
			ws.focusedCol = insertAt
			known[id] = true
		end
	end

	return targetsById
end

-- ============================================================
-- Focus: the compositor's active window is ground truth. Level-triggered:
-- if one of our targets is active, follow it. If none is (focus on a
-- floating window or the other monitor), keep our pointer — each workspace
-- remembers its own focused column, like niri.
-- ============================================================
local function reconcile_focus(ctx, ws)
	for _, t in ipairs(ctx.targets) do
		local win = safe_get(t, "window")
		if win and safe_get(win, "active") then
			local id = window_id(win)
			if id then
				for ci, col in ipairs(ws.columns) do
					for wi, wid in ipairs(col.ids) do
						if wid == id then
							ws.focusedCol = ci
							col.focus = wi
							return
						end
					end
				end
			end
			return -- active target found (tracked or not); stop looking
		end
	end
end

-- ============================================================
-- Camera: port of niri's compute_new_view_offset (src/layout/scrolling.rs):
--   * column wider than the view -> left-align it,
--   * already fully visible     -> do not move,
--   * else left- or right-align by whichever moves the camera less,
--   * breathing room capped at `gaps`,
--   * never rest left of the tape start or past the tape end.
-- ============================================================
local function current_gaps()
	local ok, v = pcall(function()
		return hl.get_config("general.gaps_in")
	end)
	if ok and type(v) == "number" then
		return v
	end
	return CONFIG.fallback_gaps
end

local function tape_x(ws, areaW, index)
	local x = 0
	for i = 1, index - 1 do
		x = x + ws.columns[i].width * areaW
	end
	return x
end

local function tape_width(ws, areaW)
	local w = 0
	for _, col in ipairs(ws.columns) do
		w = w + col.width * areaW
	end
	return w
end

local function fit_camera(ws, areaW)
	if #ws.columns == 0 then
		ws.offset = 0
		return
	end
	if ws.focusedCol > #ws.columns then
		ws.focusedCol = #ws.columns
	end
	local col = ws.columns[ws.focusedCol]
	local colX = tape_x(ws, areaW, ws.focusedCol)
	local colW = col.width * areaW
	local cur = ws.offset
	local newOffset

	if areaW <= colW then
		newOffset = colX -- left-align an oversized column
	else
		local pad = math.min((areaW - colW) / 2, current_gaps())
		local leftX = colX - pad
		local rightX = colX + colW + pad
		if cur <= leftX and rightX <= cur + areaW then
			newOffset = cur -- already fully visible; leave the view as is
		else
			local distLeft = math.abs(cur - leftX)
			local distRight = math.abs((cur + areaW) - rightX)
			if distLeft <= distRight then
				newOffset = leftX
			else
				newOffset = rightX - areaW
			end
		end
	end

	local maxOffset = math.max(0, tape_width(ws, areaW) - areaW)
	ws.offset = math.max(0, math.min(newOffset, maxOffset))
end

-- One-off centering (escape hatch; never applied automatically).
local function center_camera(ws, areaW)
	local col = ws.columns[ws.focusedCol]
	if not col then
		return
	end
	local colX = tape_x(ws, areaW, ws.focusedCol)
	local colW = col.width * areaW
	local maxOffset = math.max(0, tape_width(ws, areaW) - areaW)
	ws.offset = math.max(0, math.min(colX + colW / 2 - areaW / 2, maxOffset))
end

-- ============================================================
-- Placement: columns share edges; the compositor insets gaps_in on sides
-- that are not flush with the work area (same convention as the native
-- scrolling layout). Columns outside the viewport are placed too — negative
-- x is allowed and is how the tape extends left of the camera.
-- ============================================================
local function place_columns(ws, targetsById, ax, ay, aw, ah)
	local x = ax - ws.offset
	for _, col in ipairs(ws.columns) do
		local w = col.width * aw
		local n = #col.ids
		if n == 1 then
			local t = targetsById[col.ids[1]]
			if t then
				t:place({ x = x, y = ay, w = w, h = ah })
			end
		else
			local slotH = ah / n
			for j, id in ipairs(col.ids) do
				local t = targetsById[id]
				if t then
					t:place({ x = x, y = ay + (j - 1) * slotH, w = w, h = slotH })
				end
			end
		end
		x = x + w
	end
end

-- ============================================================
-- Structural operations (niri semantics)
-- ============================================================
local function focus_col(ws, dir)
	local n = #ws.columns
	if n == 0 then
		return
	end
	local j = ws.focusedCol + dir
	if CONFIG.wrap_focus then
		j = ((j - 1) % n) + 1
	else
		j = math.max(1, math.min(n, j))
	end
	ws.focusedCol = j
end

local function focus_in_col(ws, dir)
	local col = ws.columns[ws.focusedCol]
	if not col then
		return
	end
	local n = #col.ids
	local j = col.focus + dir
	if CONFIG.wrap_focus then
		j = ((j - 1) % n) + 1
	else
		j = math.max(1, math.min(n, j))
	end
	col.focus = j
end

local function move_col(ws, dir)
	local i = ws.focusedCol
	local j = i + dir
	if j < 1 or j > #ws.columns then
		return
	end
	ws.columns[i], ws.columns[j] = ws.columns[j], ws.columns[i]
	ws.focusedCol = j
end

local function move_win_in_col(ws, dir)
	local col = ws.columns[ws.focusedCol]
	if not col then
		return
	end
	local i = col.focus
	local j = i + dir
	if j < 1 or j > #col.ids then
		return
	end
	col.ids[i], col.ids[j] = col.ids[j], col.ids[i]
	col.focus = j
end

local function resize_focused(ws, arg)
	local col = ws.columns[ws.focusedCol]
	if not col then
		return true
	end -- nothing focused; harmless no-op
	if not arg or arg == "" then
		return false, "leftscroll: resize expects +conf, -conf, +, -, +N, -N, or N"
	end

	if arg == "+conf" or arg == "-conf" then
		local presets = CONFIG.width_presets
		local idx = 1
		for i, v in ipairs(presets) do
			if math.abs(v - col.width) < 0.001 then
				idx = i
				break
			end
		end
		if arg == "+conf" then
			idx = (idx % #presets) + 1
		else
			idx = ((idx - 2) % #presets) + 1
		end
		col.width = presets[idx]
		return true
	end

	if arg == "+" or arg == "-" then
		col.width = col.width + (arg == "+" and CONFIG.width_step or -CONFIG.width_step)
	else
		local num = tonumber(arg)
		if not num then
			return false, "leftscroll: resize got a non-numeric argument '" .. arg .. "'"
		end
		if arg:match("^[+-]") then
			col.width = col.width + num
		else
			col.width = num
		end
	end

	col.width = math.max(CONFIG.min_width, math.min(CONFIG.max_width, col.width))
	return true
end

-- niri consume-window-into-column: the TOP window of the column to the RIGHT
-- joins the END (bottom) of the focused column. Focus stays put. No-op when
-- the focused column is the last one.
local function consume(ws)
	if ws.focusedCol >= #ws.columns then
		return
	end
	local src = ws.columns[ws.focusedCol + 1]
	local dst = ws.columns[ws.focusedCol]
	if not src or not dst then
		return
	end
	local id = table.remove(src.ids, 1)
	if src.focus > #src.ids then
		src.focus = math.max(1, #src.ids)
	end
	table.insert(dst.ids, id)
	if #src.ids == 0 then
		table.remove(ws.columns, ws.focusedCol + 1)
	end
end

-- niri expel-window-from-column: the BOTTOM window of the focused column
-- leaves into a new column immediately to the right. Focus stays on the
-- focused column. No-op on a solo column.
local function expel(ws)
	local col = ws.columns[ws.focusedCol]
	if not col or #col.ids <= 1 then
		return
	end
	local id = table.remove(col.ids)
	if col.focus > #col.ids then
		col.focus = #col.ids
	end
	local newCol = { ids = { id }, width = CONFIG.default_width, focus = 1 }
	table.insert(ws.columns, ws.focusedCol + 1, newCol)
end

-- niri consume-or-expel (focused window): if its column stacks, expel the
-- focused window into a new column right of its column-mates; if it is solo,
-- merge it into the END of the LEFT neighbor. Focus follows the moved window.
local function consume_or_expel(ws)
	local col = ws.columns[ws.focusedCol]
	if not col then
		return
	end
	if #col.ids > 1 then
		local id = table.remove(col.ids, col.focus)
		if col.focus > #col.ids then
			col.focus = #col.ids
		end
		local newCol = { ids = { id }, width = CONFIG.default_width, focus = 1 }
		table.insert(ws.columns, ws.focusedCol + 1, newCol)
		ws.focusedCol = ws.focusedCol + 1
	else
		if ws.focusedCol < 2 then
			return
		end
		local prev = ws.columns[ws.focusedCol - 1]
		local id = col.ids[1]
		table.insert(prev.ids, id)
		prev.focus = #prev.ids
		table.remove(ws.columns, ws.focusedCol)
		ws.focusedCol = ws.focusedCol - 1
	end
end

-- ============================================================
-- Focus dispatch (layout_msg only — never inside recalculate)
-- ============================================================
local function try_focus_window(win)
	if not win then
		return
	end
	pcall(function()
		local addr = safe_get(win, "address")
		if addr then
			hl.dispatch(hl.dsp.focus({ window = "address:" .. tostring(addr) }))
		end
	end)
end

local function focused_window_target(ctx, ws)
	local col = ws.columns[ws.focusedCol]
	if not col then
		return nil
	end
	local id = col.ids[col.focus]
	if not id then
		return nil
	end
	for _, t in ipairs(ctx.targets) do
		local win = safe_get(t, "window")
		if win and window_id(win) == id then
			return t
		end
	end
	return nil
end

-- ============================================================
-- layout_msg command surface
-- ============================================================
local function handle_msg(ctx, ws, msg)
	if not msg or msg == "" then
		return true
	end

	local cmd, rest = msg:match("^(%S*)%s*(.*)$")

	if cmd == "sync" then
		-- Focus-hook nudge: state is already updated; the C++ runs a
		-- recalculate right after every layout_msg, which re-fits the camera.
		return true
	elseif cmd == "focus" then
		if rest == "l" then
			focus_col(ws, -1)
		elseif rest == "r" then
			focus_col(ws, 1)
		elseif rest == "u" then
			focus_in_col(ws, -1)
		elseif rest == "d" then
			focus_in_col(ws, 1)
		else
			return "leftscroll: focus expects l, r, u, or d"
		end
		local t = focused_window_target(ctx, ws)
		if t then
			try_focus_window(safe_get(t, "window"))
		end
	elseif cmd == "movecol" then
		if rest == "l" then
			move_col(ws, -1)
		elseif rest == "r" then
			move_col(ws, 1)
		else
			return "leftscroll: movecol expects l or r"
		end
	elseif cmd == "movewin" then
		if rest == "u" then
			move_win_in_col(ws, -1)
		elseif rest == "d" then
			move_win_in_col(ws, 1)
		else
			return "leftscroll: movewin expects u or d"
		end
	elseif cmd == "resize" then
		local ok, err = resize_focused(ws, rest)
		if not ok then
			return err
		end
	elseif cmd == "consume" then
		consume(ws)
	elseif cmd == "expel" then
		expel(ws)
	elseif cmd == "consume_or_expel" then
		consume_or_expel(ws)
	elseif cmd == "center" then
		if ctx.area and ctx.area.w then
			center_camera(ws, ctx.area.w)
		end
	else
		return "leftscroll: unknown command '" .. tostring(cmd) .. "'"
	end

	return true
end

-- ============================================================
-- Focus hook: focus changes alone never trigger a recalculate (verified in
-- the v0.56.2 source), so without this the camera would only follow
-- keyboard-driven focus that goes through layout_msg. We update the state
-- here and nudge with the internal "sync" message — layout_msg is always
-- followed by an unconditional C++ recalculate, which re-fits the camera.
-- ============================================================
local function on_active_changed()
	local ok, win = pcall(hl.get_active_window)
	if not ok or not win then
		return
	end
	local sid = safe_get(win, "stable_id")
	if sid == nil then
		return
	end
	local wsobj = safe_get(win, "workspace")
	local wsid = wsobj and safe_get(wsobj, "id")
	if wsid == nil then
		return
	end
	local st = workspaces[tostring(wsid)]
	if not st then
		return
	end
	for ci, col in ipairs(st.columns) do
		for wi, wid in ipairs(col.ids) do
			if wid == tostring(sid) then
				if st.focusedCol ~= ci then
					st.focusedCol = ci
					col.focus = wi
					-- Nudge only when the window's workspace is actually shown;
					-- hidden workspaces re-fit on their next real recalculate.
					local visible = safe_get(wsobj, "visible")
					if visible then
						pcall(function()
							hl.dispatch(hl.dsp.layout("sync"))
						end)
					end
				elseif col.focus ~= wi then
					col.focus = wi
				end
				return
			end
		end
	end
end

hl.on("window.active", on_active_changed)

-- ============================================================
-- Registration
-- ============================================================

hl.layout.register("leftscroll", {
	recalculate = function(ctx)
		if not ctx.targets or #ctx.targets == 0 then
			return
		end
		local area = ctx.area
		if not area then
			return
		end
		local ax, ay = safe_get(area, "x"), safe_get(area, "y")
		local aw, ah = safe_get(area, "w"), safe_get(area, "h")
		if not (ax and ay and aw and ah) then
			return
		end

		local key = resolve_ws_key(ctx)
		if not key then
			return -- cannot identify the workspace; refuse to guess
		end

		-- Identity guard: if any target cannot be identified this pass
		-- (window or stable_id transiently nil), skip the whole pass rather
		-- than treating live windows as closed and rebuilding the tape.
		for _, t in ipairs(ctx.targets) do
			local win = safe_get(t, "window")
			if not win or not window_id(win) then
				return
			end
		end

		local ws = get_ws(key)

		local targetsById = sync(ctx, ws)
		reconcile_focus(ctx, ws)
		fit_camera(ws, aw)
		place_columns(ws, targetsById, ax, ay, aw, ah)
	end,

	layout_msg = function(ctx, msg)
		local key = resolve_ws_key(ctx)
		if not key then
			-- No targets in ctx (e.g. an empty workspace): nothing to command.
			return true
		end
		local ws = get_ws(key)
		return handle_msg(ctx, ws, msg)
	end,
})
