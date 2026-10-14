-- Merges /ww capture data into Data/WeaponTrainers.lua.
-- Usage, from the repo root:
--   lua tools/import_captures.lua "<WoW>/WTF/Account/<ACCOUNT>/SavedVariables/WeaponWise.lua"
package.path = "./?.lua;" .. package.path
local Captures = require("tools.captures")

local savedVariablesPath = assert(arg[1], "pass the path to SavedVariables/WeaponWise.lua")

local ns = {}
for _, path in ipairs({ "Data/WeaponTypes.lua", "Data/Cities.lua", "Data/WeaponTrainers.lua" }) do
  assert(loadfile(path))("WeaponWise", ns)
end

-- SavedVariables files are plain assignments. Run it as text only, with an
-- empty environment, so it cannot reach any function.
local file = assert(io.open(savedVariablesPath, "r"))
local text = file:read("a")
file:close()
local saved = {}
assert(load(text, "SavedVariables", "t", saved))()

local captured, warnings = Captures.ToTrainers(saved.WeaponWiseDevDB or {}, ns.WeaponTypes, ns.Cities)
for _, w in ipairs(warnings) do io.stderr:write("warning: ", w, "\n") end

local merged = Captures.Merge(ns.WeaponTrainers, captured)
local out = assert(io.open("Data/WeaponTrainers.lua", "w"))
out:write(Captures.Serialize(merged))
out:close()
for _, gap in ipairs(Captures.CoverageGaps(merged, ns.WeaponTypes)) do
  io.stderr:write("no trainer: ", gap, " (capture this weapon master with another class)\n")
end
print(("%d captured trainers merged into Data/WeaponTrainers.lua (%d total)"):format(#captured, #merged))
