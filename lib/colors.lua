-- lib/colors.lua
-- Palette-aware terminal colors. Palette choice is read from config at
-- startup (set via `baka init`). Falls back to "ice" if unset.

local config = require("lib.config")

local M = {}

M.palettes = {
	none = {
		red = "", green = "", yellow = "",
		blue = "", mauve = "", grey = "", ice = "", neon = "",
		bold = "", dim = "", reset = "",
	},
	-- classic Cirno: cool, mature blues. red kept warm for failures.
	-- `neon` is the bright accent reserved for headers and root-privilege
	-- banners -- deliberately more saturated than the rest of the palette.
	ice = {
		red    = "\27[38;2;235;111;131m",
		green  = "\27[38;2;140;220;200m",
		yellow = "\27[38;2;190;225;235m",
		blue   = "\27[38;2;90;170;235m",
		mauve  = "\27[38;2;140;200;235m",
		grey   = "\27[38;2;108;130;150m",
		ice    = "\27[38;2;210;240;250m",
		neon   = "\27[38;2;0;200;255m",
		bold   = "\27[1m",
		dim    = "\27[2m",
		reset  = "\27[0m",
	},
	-- bubblier, a bit of neon. still red-for-failure.
	soda = {
		red    = "\27[38;2;255;90;120m",
		green  = "\27[38;2;100;255;200m",
		yellow = "\27[38;2;255;240;120m",
		blue   = "\27[38;2;80;190;255m",
		mauve  = "\27[38;2;190;120;255m",
		grey   = "\27[38;2;130;140;170m",
		ice    = "\27[38;2;170;255;245m",
		neon   = "\27[38;2;0;255;255m",
		bold   = "\27[1m",
		dim    = "\27[2m",
		reset  = "\27[0m",
	},
}

local cfg = config.load()
local palette_name = cfg.palette or "ice"
local palette = M.palettes[palette_name] or M.palettes.ice

for k, v in pairs(palette) do
	M[k] = v
end

local function wrap(color, text)
	if color == "" then
		return text
	end
	return color .. text .. M.reset
end

function M.info(msg)    print(wrap(M.blue,   "[baka] ") .. msg) end
function M.success(msg) print(wrap(M.green,  "[baka] ") .. msg) end
function M.warn(msg)    print(wrap(M.yellow, "[baka] ") .. msg) end
function M.error(msg)   print(wrap(M.red,    "[baka] ") .. msg) end
function M.step(msg)    print(wrap(M.mauve,  " -> ") .. msg) end

--- Bright/neon variant of the [baka] tag, reserved for root-privilege
--- banners so it stays visually consistent with headings.
function M.neon_tag(msg)
	print(wrap(M.neon .. M.bold, "[baka] ") .. msg)
end

return M
