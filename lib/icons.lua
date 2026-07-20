-- lib/icons.lua
-- Nerd Font glyphs as Lua 5.1-safe decimal-escaped UTF-8 byte strings
-- (5.1 has no \u{} or \x hex escapes, only decimal \ddd).
--
-- These require a Nerd Font patched terminal font to render -- without
-- one they'll show as tofu/boxes. Used sparingly and on purpose: section
-- headings, the root-privilege banner, and a couple of one-time titles.
-- Not baked into every log line -- that would be spam, not depth.

local M = {}

M.snowflake = "\239\139\156" -- U+F2DC -- Cirno's whole thing
M.check     = "\239\128\140" -- U+F00C
M.cross     = "\239\128\141" -- U+F00D
M.warn      = "\239\129\177" -- U+F071
M.info      = "\239\129\154" -- U+F05A
M.lock      = "\239\128\163" -- U+F023 -- root privilege
M.package   = "\239\134\135" -- U+F187
M.wifi      = "\239\135\171" -- U+F1EB
M.disk      = "\239\130\160" -- U+F0A0
M.cpu       = "\239\139\155" -- U+F2DB
M.gear      = "\239\128\147" -- U+F013
M.clock     = "\239\128\151" -- U+F017
M.book      = "\239\128\173" -- U+F02D
M.bolt      = "\239\131\167" -- U+F0E7
M.link      = "\239\131\129" -- U+F0C1 -- symlink

return M
