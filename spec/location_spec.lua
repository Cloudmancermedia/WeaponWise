local env = require("spec.helpers.wow_env")

describe("Location", function()
  local ns

  before_each(function()
    env.reset()
    ns = env.load({ "Core.lua", "Data/Cities.lua", "Services/Location.lua" })
    local maps = {
      [1458] = { mapType = 3, parentMapID = 1415 },
      [1415] = { mapType = 2, parentMapID = 947 },
      [947] = { mapType = 1, parentMapID = 0 },
    }
    _G.C_Map = {
      GetMapInfo = function(id) return maps[id] end,
      GetBestMapForUnit = function() return 1458 end,
      GetPlayerMapPosition = function() return { GetXY = function() return 0.5, 0.25 end } end,
      GetWorldPosFromMapPos = function(mapID, v) return 0, { x = mapID + v.x, y = v.y } end,
    }
    _G.CreateVector2D = function(x, y) return { x = x, y = y } end
    _G.GetZoneText = function() return "Undercity" end
  end)

  after_each(function()
    _G.C_Map, _G.CreateVector2D, _G.GetZoneText = nil, nil, nil
  end)

  it("walks parent maps up to the continent", function()
    assert.equals(1415, ns.Location.Continent(1458))
    assert.is_nil(ns.Location.Continent(947))
  end)

  it("describes the player's zone, map, position, continent, and world position", function()
    local p = ns.Location.Player()
    assert.equals("Undercity", p.zone)
    assert.equals(1458, p.mapID)
    assert.equals(50, p.x)
    assert.equals(25, p.y)
    assert.equals(1415, p.continent)
    assert.same({ x = 1458.5, y = 0.25 }, p.world)
  end)

  it("finds a trainer's world position from its city map", function()
    local w = ns.Location.TrainerWorld({ city = "Undercity", x = 50, y = 50 })
    assert.same({ x = 1458.5, y = 0.5 }, w)
    assert.is_nil(ns.Location.TrainerWorld({ city = "Undercity" }))
  end)

  it("degrades to the zone name when map APIs are missing", function()
    _G.C_Map = nil
    assert.same({ zone = "Undercity" }, ns.Location.Player())
  end)
end)
