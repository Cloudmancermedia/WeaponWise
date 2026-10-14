-- Thin wrapper over the client's map APIs. Every function degrades to less
-- information, never an error, when an API is missing (spec 9).
local _, ns = ...

local Location = {}
ns.Location = Location

local CONTINENT_MAP_TYPE = 2 -- Enum.UIMapType.Continent
local MAX_DEPTH = 10

function Location.Continent(mapID)
  if not (C_Map and C_Map.GetMapInfo) then return nil end
  for _ = 1, MAX_DEPTH do
    local info = mapID and C_Map.GetMapInfo(mapID)
    if not info then return nil end
    if info.mapType == CONTINENT_MAP_TYPE then return mapID end
    mapID = info.parentMapID
  end
  return nil
end

-- x and y are map percentages (0-100), as stored in the trainer data.
function Location.World(mapID, x, y)
  if not (mapID and x and y and C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D) then return nil end
  local _, pos = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(x / 100, y / 100))
  if not pos then return nil end
  return { x = pos.x, y = pos.y }
end

function Location.Player()
  local p = { zone = GetZoneText() }
  if not (C_Map and C_Map.GetBestMapForUnit) then return p end
  p.mapID = C_Map.GetBestMapForUnit("player")
  local pos = p.mapID and C_Map.GetPlayerMapPosition(p.mapID, "player")
  if pos then
    local x, y = pos:GetXY()
    p.x, p.y = x * 100, y * 100
  end
  p.continent = Location.Continent(p.mapID)
  p.world = Location.World(p.mapID, p.x, p.y)
  return p
end

function Location.TrainerWorld(trainer)
  local city = ns.Cities[trainer.city]
  return city and Location.World(city.mapID, trainer.x, trainer.y)
end
