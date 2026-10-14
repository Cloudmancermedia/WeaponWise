-- Points the player at a trainer: native waypoint, TomTom, or plain
-- coordinates in chat, whichever the client supports.
local _, ns = ...

local NavigationService = {}
ns.NavigationService = NavigationService

-- Plain hyphen: the default game font may lack an em dash glyph.
function NavigationService.Label(trainer, weaponKey)
  return ("%s - %s"):format(trainer.name, ns.WeaponTypes[weaponKey].label)
end

local function native(mapID, x, y)
  if not (C_Map and C_Map.CanSetUserWaypointOnMap and C_Map.SetUserWaypoint and UiMapPoint) then return false end
  if not C_Map.CanSetUserWaypointOnMap(mapID) then return false end
  C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapID, x / 100, y / 100))
  if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
    C_SuperTrack.SetSuperTrackedUserWaypoint(true)
  end
  return true
end

local function tomtom(mapID, x, y, label)
  if not (TomTom and TomTom.AddWaypoint) then return false end
  TomTom:AddWaypoint(mapID, x / 100, y / 100, { title = label })
  return true
end

-- Returns the provider used: "native", "tomtom", "coords", or "none".
function NavigationService.Track(trainer, weaponKey)
  local label = NavigationService.Label(trainer, weaponKey)
  local city = ns.Cities[trainer.city]
  local where = trainer.district and (trainer.city .. " · " .. trainer.district) or trainer.city
  if not (city and trainer.x and trainer.y) then
    ns.Print(("%s, %s: no coordinates recorded for this trainer"):format(label, where))
    return "none"
  end
  local coords = ("%s, %s (%.1f, %.1f)"):format(label, where, trainer.x, trainer.y)
  local order = ns.config.preferTomTom and { tomtom, native } or { native, tomtom }
  local names = ns.config.preferTomTom and { "tomtom", "native" } or { "native", "tomtom" }
  for i, provider in ipairs(order) do
    if provider(city.mapID, trainer.x, trainer.y, label) then
      ns.Print("tracking " .. coords)
      return names[i]
    end
  end
  ns.Print("no waypoint support; head to " .. coords)
  return "coords"
end
