-- Turns /ww capture data (WeaponWiseDevDB.trainers) into WeaponTrainers
-- records and writes the data file. Runs outside the game; see
-- tools/import_captures.lua for the command.
local Captures = {}

local function round1(n)
  return math.floor(n * 10 + 0.5) / 10
end

local function sortedKeys(t)
  local keys = {}
  for k in pairs(t) do keys[#keys + 1] = k end
  table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
  return keys
end

local function weaponIndex(weaponTypes)
  local index = {}
  for key, wt in pairs(weaponTypes) do
    index[wt.label:lower()] = key
    index[wt.skillName:lower()] = key
  end
  return index
end

-- Each class sees its own view of a weapon master, so merge every view. When
-- views disagree on cost, keep the highest: reputation discounts only lower it.
local function collectServices(entry, index)
  local services, unknown = {}, {}
  for _, class in ipairs(sortedKeys(entry.servicesByClass or {})) do
    for _, s in ipairs(entry.servicesByClass[class]) do
      local key = s.name and index[s.name:lower()]
      if key then
        local cur = services[key] or {}
        cur.cost = math.max(cur.cost or 0, s.cost or 0)
        cur.levelReq = s.levelReq or cur.levelReq
        services[key] = cur
      elseif s.name then
        unknown[s.name] = true
      end
    end
  end
  return services, unknown
end

function Captures.ToTrainers(devDB, weaponTypes, cities)
  local index = weaponIndex(weaponTypes)
  local trainers, warnings = {}, {}
  for _, entry in pairs(devDB.trainers or {}) do
    local services, unknown = collectServices(entry, index)
    local teaches = sortedKeys(services)
    if #teaches == 0 then
      warnings[#warnings + 1] = ("skipped %s: no weapon skills (not a weapon master?)"):format(tostring(entry.name))
    else
      for _, name in ipairs(sortedKeys(unknown)) do
        warnings[#warnings + 1] = ("%s: unknown service %q"):format(entry.name, name)
      end
      local loc = entry.location or {}
      if not cities[loc.zone] then
        warnings[#warnings + 1] = ("%s: zone %q is not a known city"):format(entry.name, tostring(loc.zone))
      end
      local district = loc.subZone
      if district == "" or district == loc.zone then district = nil end
      trainers[#trainers + 1] = {
        name = entry.name, npcID = entry.npcID, faction = entry.faction, city = loc.zone, district = district,
        mapID = loc.mapID, x = loc.x and round1(loc.x), y = loc.y and round1(loc.y),
        teaches = teaches, services = services, source = "capture", verified = true,
      }
    end
  end
  table.sort(trainers, function(a, b) return a.name < b.name end)
  return trainers, warnings
end

function Captures.Merge(existing, captured)
  local byKey = {}
  for _, t in ipairs(captured) do byKey[t.faction .. "/" .. t.name] = t end
  local merged, used = {}, {}
  for _, t in ipairs(existing) do
    local key = t.faction .. "/" .. t.name
    merged[#merged + 1] = byKey[key] or t
    used[key] = true
  end
  for _, t in ipairs(captured) do
    if not used[t.faction .. "/" .. t.name] then merged[#merged + 1] = t end
  end
  return merged
end

-- Weapons with no trainer for a faction, e.g. "Horde: CROSSBOW". A capture
-- from one class only shows that class's weapons, so gaps after an import
-- usually mean another class needs to visit that trainer.
function Captures.CoverageGaps(trainers, weaponTypes)
  local taught = { Horde = {}, Alliance = {} }
  for _, t in ipairs(trainers) do
    for _, key in ipairs(t.teaches) do taught[t.faction][key] = true end
  end
  local gaps = {}
  for _, faction in ipairs({ "Alliance", "Horde" }) do
    for _, key in ipairs(sortedKeys(weaponTypes)) do
      if key ~= "WAND" and not taught[faction][key] then gaps[#gaps + 1] = faction .. ": " .. key end
    end
  end
  return gaps
end

local FIELD_ORDER = { "name", "npcID", "faction", "city", "district", "mapID", "x", "y", "teaches", "services",
  "source", "verified" }

local function literal(v)
  if type(v) == "string" then return ("%q"):format(v) end
  if type(v) == "number" then return ("%.14g"):format(v) end
  return tostring(v)
end

local function listLiteral(list)
  local parts = {}
  for _, v in ipairs(list) do parts[#parts + 1] = literal(v) end
  return "{ " .. table.concat(parts, ", ") .. " }"
end

local function servicesLiteral(services)
  local parts = {}
  for _, key in ipairs(sortedKeys(services)) do
    local s, fields = services[key], {}
    if s.cost then fields[#fields + 1] = "cost = " .. literal(s.cost) end
    if s.levelReq then fields[#fields + 1] = "levelReq = " .. literal(s.levelReq) end
    parts[#parts + 1] = ("      %s = { %s },"):format(key, table.concat(fields, ", "))
  end
  return "{\n" .. table.concat(parts, "\n") .. "\n    }"
end

local HEADER = [[
-- Weapon masters. source = "owner" records come from wiki lists the project
-- owner confirmed for Forever (2026-10-13), with Classic prices: 10s per
-- weapon, polearms 1g at level 20. The tooltip tags verified = false records
-- "unverified" and the release gate spec blocks shipping them.
-- services = { [weaponKey] = { cost = copper, levelReq = n } }. Captured
-- records also carry npcID and mapID; tools/import_captures.lua writes them.
local _, ns = ...

ns.WeaponTrainers = {
]]

function Captures.Serialize(trainers)
  local out = { HEADER }
  for _, t in ipairs(trainers) do
    out[#out + 1] = "  {\n"
    for _, field in ipairs(FIELD_ORDER) do
      local v = t[field]
      if v ~= nil then
        local text
        if field == "teaches" then
          text = listLiteral(v)
        elseif field == "services" then
          text = servicesLiteral(v)
        else
          text = literal(v)
        end
        out[#out + 1] = ("    %s = %s,\n"):format(field, text)
      end
    end
    out[#out + 1] = "  },\n"
  end
  out[#out + 1] = "}\n"
  return table.concat(out)
end

return Captures
