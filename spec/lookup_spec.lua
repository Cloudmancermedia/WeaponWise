local env = require("spec.helpers.wow_env")

describe("Lookup", function()
  local ns, skillReads

  before_each(function()
    env.reset()
    ns = env.load({
      "Core.lua", "Config.lua", "Data/WeaponTypes.lua", "Data/ClassWeapons.lua", "Data/Cities.lua",
      "Data/WeaponTrainers.lua",
      "Services/WeaponSkillService.lua", "Services/TrainerService.lua", "Services/Location.lua", "Services/Lookup.lua",
    })
    local items = { axe = { 2, 1 }, daggerItem = { 2, 15 }, shirt = { 4, 0 } }
    _G.GetItemInfoInstant = function(link)
      local i = items[link]
      return 1, nil, nil, nil, nil, i[1], i[2]
    end
    _G.UnitClass = function() return "Warrior", "WARRIOR" end
    _G.UnitFactionGroup = function() return "Horde" end
    _G.GetZoneText = function() return "Undercity" end
    skillReads = 0
    ns.WeaponSkillService.ReadSkills = function()
      skillReads = skillReads + 1
      return { Daggers = { rank = 10, max = 50 } }
    end
  end)

  after_each(function()
    _G.GetItemInfoInstant, _G.GetZoneText = nil, nil
  end)

  it("ignores items that are not weapons", function()
    assert.is_nil(ns.Lookup.ForLink("shirt"))
    assert.is_nil(ns.Lookup.ForLink(nil))
  end)

  it("returns the skill state for a known weapon with no trainer lookup", function()
    local info = ns.Lookup.ForLink("daggerItem")
    assert.equals("KNOWN", info.result.state)
    assert.is_nil(info.recommended)
  end)

  it("adds a recommended trainer and alternatives for a trainable weapon", function()
    local info = ns.Lookup.ForLink("axe")
    assert.equals("TRAINABLE", info.result.state)
    assert.is_table(info.recommended)
    assert.is_table(info.alternatives)
  end)

  it("does not re-read skills on every hover when the skill API is missing", function()
    ns.WeaponSkillService.ReadSkills = function() skillReads = skillReads + 1; return nil end
    assert.is_nil(ns.Lookup.ForLink("axe"))
    ns.Lookup.ForLink("axe")
    assert.equals(1, skillReads)
  end)

  it("caches skills until the skill list changes", function()
    ns.Lookup.ForLink("axe")
    ns.Lookup.ForLink("daggerItem")
    assert.equals(1, skillReads)
    ns.frame.scripts.OnEvent(ns.frame, "SKILL_LINES_CHANGED")
    ns.Lookup.ForLink("axe")
    assert.equals(2, skillReads)
  end)
end)
