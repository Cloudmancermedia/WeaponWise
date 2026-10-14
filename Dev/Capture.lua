-- Phase 0 data gathering: records every trainer window opened while capture
-- is on, so the trainer database comes from the Forever client itself.
local _, ns = ...
ns.devTools = true

local Capture = {}
ns.Capture = Capture

local FILTERS = { "available", "unavailable", "used" }

function Capture.ParseNpcID(guid)
  if type(guid) ~= "string" then return nil end
  local unitType, id = guid:match("^(%a+)%-%d+%-%d+%-%d+%-%d+%-(%d+)")
  if unitType ~= "Creature" then return nil end
  return tonumber(id)
end

-- The trainer list hides services by filter; open them all so a capture is
-- complete, then put the player's filters back.
function Capture.ReadServices()
  local saved = {}
  for _, kind in ipairs(FILTERS) do
    saved[kind] = GetTrainerServiceTypeFilter(kind)
    SetTrainerServiceTypeFilter(kind, 1)
  end
  local list = {}
  for i = 1, GetNumTrainerServices() do
    local name, subText, kind = GetTrainerServiceInfo(i)
    if kind ~= "header" then
      list[#list + 1] = {
        name = name,
        subText = subText,
        kind = kind,
        cost = GetTrainerServiceCost(i),
        levelReq = GetTrainerServiceLevelReq and GetTrainerServiceLevelReq(i) or nil,
      }
    end
  end
  for _, kind in ipairs(FILTERS) do
    -- The getter may return 1/0 or a boolean; 0 is truthy in Lua.
    local wasOn = saved[kind] == 1 or saved[kind] == true
    SetTrainerServiceTypeFilter(kind, wasOn and 1 or 0)
  end
  return list
end

local function readLocation()
  local loc = { zone = GetZoneText(), subZone = GetSubZoneText() }
  if C_Map and C_Map.GetBestMapForUnit then
    loc.mapID = C_Map.GetBestMapForUnit("player")
    local pos = loc.mapID and C_Map.GetPlayerMapPosition(loc.mapID, "player")
    if pos then
      local x, y = pos:GetXY()
      loc.x, loc.y = x * 100, y * 100
    end
  end
  return loc
end

function Capture.BuildRecord()
  local _, class = UnitClass("player")
  return {
    npcID = Capture.ParseNpcID(UnitGUID("npc")),
    name = UnitName("npc"),
    faction = UnitFactionGroup("npc"),
    location = readLocation(),
    capturedBy = { class = class, faction = UnitFactionGroup("player"), level = UnitLevel("player") },
    capturedAt = time(),
    build = (GetBuildInfo()),
    services = Capture.ReadServices(),
  }
end

-- Weapon masters only list skills the visiting class can learn, so each
-- class's view is kept separately and merged later.
function Capture.Merge(db, record)
  local key = record.npcID or record.name
  local entry = db[key] or { servicesByClass = {} }
  for field, value in pairs(record) do
    if field ~= "services" and field ~= "capturedBy" then entry[field] = value end
  end
  entry.servicesByClass[record.capturedBy.class] = record.services
  db[key] = entry
end

local function onTrainerShow()
  if not (ns.devDB and ns.devDB.captureEnabled) then return end
  local record = Capture.BuildRecord()
  ns.devDB.trainers = ns.devDB.trainers or {}
  Capture.Merge(ns.devDB.trainers, record)
  local loc = record.location
  ns.Print(("captured %s (%s) - %d services at %s, %s (%.1f, %.1f)"):format(
    tostring(record.name), tostring(record.npcID), #record.services,
    tostring(loc.zone), tostring(loc.subZone), loc.x or 0, loc.y or 0))
end

ns.On("TRAINER_SHOW", onTrainerShow)

ns.RegisterCommand("capture", function(arg)
  if not ns.devDB then return end
  if arg == "on" then
    ns.devDB.captureEnabled = true
  elseif arg == "off" then
    ns.devDB.captureEnabled = false
  end
  local count = 0
  for _ in pairs(ns.devDB.trainers or {}) do count = count + 1 end
  ns.Print(("capture %s, %d trainers recorded"):format(ns.devDB.captureEnabled and "ON" or "off", count))
end, "on|off - record trainer windows you open")
