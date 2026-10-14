-- Capital cities with weapon masters, keyed by the zone name the client
-- reports. mapID is the uiMapID used for waypoints; continent is the
-- continent's uiMapID (Kalimdor 1414, Eastern Kingdoms 1415).
-- UNVERIFIED: Classic Era uiMapIDs. Confirm with /ww capture (it records mapID).
local _, ns = ...

ns.Cities = {
  ["Orgrimmar"] = { mapID = 1454, continent = 1414 },
  ["Thunder Bluff"] = { mapID = 1456, continent = 1414 },
  ["Darnassus"] = { mapID = 1457, continent = 1414 },
  ["Undercity"] = { mapID = 1458, continent = 1415 },
  ["Stormwind City"] = { mapID = 1453, continent = 1415 },
  ["Ironforge"] = { mapID = 1455, continent = 1415 },
}
