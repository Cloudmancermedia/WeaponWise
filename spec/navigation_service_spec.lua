local env = require("spec.helpers.wow_env")

describe("NavigationService", function()
  local ns, nav, calls
  local trainer = { name = "Archibald", city = "Undercity", district = "War Quarter", x = 57.3, y = 32.8 }

  before_each(function()
    env.reset()
    ns = env.load({ "Core.lua", "Data/WeaponTypes.lua", "Data/Cities.lua", "Services/NavigationService.lua" })
    ns.config = { preferTomTom = false }
    nav = ns.NavigationService
    calls = {}
    _G.C_Map = {
      CanSetUserWaypointOnMap = function() return true end,
      SetUserWaypoint = function(point) calls.native = point end,
    }
    _G.UiMapPoint = { CreateFromCoordinates = function(m, x, y) return { mapID = m, x = x, y = y } end }
    _G.C_SuperTrack = { SetSuperTrackedUserWaypoint = function(v) calls.supertrack = v end }
  end)

  after_each(function()
    _G.C_Map, _G.UiMapPoint, _G.C_SuperTrack, _G.TomTom = nil, nil, nil, nil
  end)

  local function tomtom()
    _G.TomTom = { AddWaypoint = function(_, m, x, y, opts) calls.tomtom = { m, x, y, opts.title } end }
  end

  it("labels the waypoint with trainer and weapon skill", function()
    assert.equals("Archibald - Two-Handed Swords", nav.Label(trainer, "SWORD_2H"))
  end)

  it("uses a native waypoint when the client supports one", function()
    assert.equals("native", nav.Track(trainer, "SWORD_2H"))
    assert.equals(1458, calls.native.mapID)
    assert.near(0.573, calls.native.x, 1e-9)
    assert.near(0.328, calls.native.y, 1e-9)
    assert.is_true(calls.supertrack)
    assert.truthy(env.output():find("Archibald %- Two%-Handed Swords"))
  end)

  it("uses TomTom first when the player prefers it", function()
    tomtom()
    ns.config.preferTomTom = true
    assert.equals("tomtom", nav.Track(trainer, "SWORD_2H"))
    assert.equals(1458, calls.tomtom[1])
    assert.near(0.573, calls.tomtom[2], 1e-9)
    assert.near(0.328, calls.tomtom[3], 1e-9)
    assert.equals("Archibald - Two-Handed Swords", calls.tomtom[4])
    assert.is_nil(calls.native)
  end)

  it("falls back to TomTom when native waypoints are unavailable", function()
    tomtom()
    _G.C_Map.CanSetUserWaypointOnMap = function() return false end
    assert.equals("tomtom", nav.Track(trainer, "SWORD_2H"))
  end)

  it("prints coordinates when no waypoint provider exists", function()
    _G.C_Map = nil
    assert.equals("coords", nav.Track(trainer, "SWORD_2H"))
    assert.truthy(env.output():find("57.3, 32.8"))
  end)

  it("reports when the trainer has no coordinates", function()
    assert.equals("none", nav.Track({ name = "Ansekhwa", city = "Thunder Bluff" }, "STAFF"))
    assert.truthy(env.output():find("no coordinates"))
  end)
end)
