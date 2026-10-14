local env = require("spec.helpers.wow_env")

describe("Capture", function()
  local ns, filters

  before_each(function()
    env.reset()
    ns = env.load({ "Core.lua", "Dev/Capture.lua" })
    filters = { available = 1, unavailable = 0, used = 0 }
    local services = {
      { "Daggers", "", "used", 0, 1 },
      { "Two-Handed Axes", "", "available", 1000, 20 },
      { "Bows", "", "unavailable", 1000, 1 },
    }
    _G.GetTrainerServiceTypeFilter = function(kind) return filters[kind] end
    _G.SetTrainerServiceTypeFilter = function(kind, value) filters[kind] = value end
    _G.GetNumTrainerServices = function()
      -- Only report every service while all filters are open.
      if filters.unavailable == 1 and filters.used == 1 then return #services end
      return 1
    end
    _G.GetTrainerServiceInfo = function(i) local s = services[i]; return s[1], s[2], s[3] end
    _G.GetTrainerServiceCost = function(i) return services[i][4] end
    _G.GetTrainerServiceLevelReq = function(i) return services[i][5] end
  end)

  describe("ParseNpcID", function()
    it("reads the NPC ID from a creature GUID", function()
      assert.equals(4592, ns.Capture.ParseNpcID("Creature-0-4372-0-17-4592-000012345F"))
    end)

    it("returns nil for players and garbage", function()
      assert.is_nil(ns.Capture.ParseNpcID("Player-4372-0ABCDEF1"))
      assert.is_nil(ns.Capture.ParseNpcID(nil))
    end)
  end)

  describe("ReadServices", function()
    it("opens every filter, reads all services, then restores the filters", function()
      local list = ns.Capture.ReadServices()
      assert.equals(3, #list)
      assert.same({ name = "Two-Handed Axes", subText = "", kind = "available", cost = 1000, levelReq = 20 }, list[2])
      assert.same({ available = 1, unavailable = 0, used = 0 }, filters)
    end)
  end)

  describe("Merge", function()
    it("keeps service lists from each class that visited the trainer", function()
      local db = {}
      ns.Capture.Merge(db, { npcID = 1, name = "Archibald", capturedBy = { class = "ROGUE" }, services = { "a" } })
      ns.Capture.Merge(db, { npcID = 1, name = "Archibald", capturedBy = { class = "WARRIOR" }, services = { "b" } })
      assert.same({ "a" }, db[1].servicesByClass.ROGUE)
      assert.same({ "b" }, db[1].servicesByClass.WARRIOR)
      assert.equals("Archibald", db[1].name)
    end)
  end)
end)
