local env = require("spec.helpers.wow_env")

describe("Probe", function()
  local ns

  before_each(function()
    env.reset()
    ns = env.load({ "Core.lua", "Dev/Probe.lua" })
    _G.C_Map = { GetBestMapForUnit = function() end }
    _G.GetBuildInfo = function() return "1.60.1", "12345", "Oct 1 2026", 16001 end
    _G.GameTooltip = { HasScript = function(_, name) return name == "OnTooltipSetItem" end }
    _G.UnitClass = function() return "Rogue", "ROGUE" end
    _G.UnitFactionGroup = function() return "Horde" end
    local skills = {
      { "Weapon Skills", true },
      { "Daggers", false, 120, 150 },
      { "Swords", false, 1, 150 },
      { "Languages", true },
      { "Orcish", false, 300, 300 },
    }
    _G.GetNumSkillLines = function() return #skills end
    _G.GetSkillLineInfo = function(i)
      local s = skills[i]
      return s[1], s[2], true, s[3], 0, 0, s[4]
    end
  end)

  after_each(function()
    _G.C_Map, _G.GetBuildInfo, _G.GameTooltip = nil, nil, nil
    _G.GetNumSkillLines, _G.GetSkillLineInfo = nil, nil
  end)

  it("resolves dotted global paths", function()
    assert.is_function(ns.Probe.Resolve("C_Map.GetBestMapForUnit"))
    assert.is_nil(ns.Probe.Resolve("C_Map.SetUserWaypoint"))
    assert.is_nil(ns.Probe.Resolve("NoSuchTable.Thing"))
  end)

  it("reports build, API presence, and tooltip script support", function()
    local report = ns.Probe.Collect()
    assert.equals("1.60.1", report.build.version)
    assert.equals(16001, report.build.interface)
    assert.is_true(report.apis["C_Map.GetBestMapForUnit"])
    assert.is_false(report.apis["C_Map.SetUserWaypoint"])
    assert.is_true(report.tooltipSetItemScript)
    assert.equals("ROGUE", report.player.class)
  end)

  it("lists skills under their headers", function()
    local report = ns.Probe.Collect()
    assert.same({ header = "Weapon Skills", name = "Daggers", rank = 120, max = 150 }, report.skills[1])
    assert.equals("Languages", report.skills[3].header)
  end)

  it("finds skill and proficiency functions anywhere in the global namespace", function()
    _G.GetProfessions = function() end
    _G.C_SkillLines = { GetSkillLineInfo = function() end, Other = 5 }
    _G.IsPlayerSpell = function() end
    local report = ns.Probe.Collect()
    local found = {}
    for _, name in ipairs(report.skillApis) do found[name] = true end
    assert.is_true(found["C_SkillLines.GetSkillLineInfo"])
    assert.is_true(found["IsPlayerSpell"])
    assert.is_nil(found["C_SkillLines.Other"])
    _G.GetProfessions, _G.C_SkillLines, _G.IsPlayerSpell = nil, nil, nil
  end)

  it("dumps raw C_SkillInfo rows, whether values or tables", function()
    _G.C_SkillInfo = {
      GetNumSkillLines = function() return 2 end,
      GetSkillLineInfo = function(i)
        if i == 1 then return "Weapon Skills", true end
        return { skillName = "Daggers", skillRank = 1 }
      end,
    }
    local rows = ns.Probe.Collect().skillLineDump
    assert.same({ "Weapon Skills", "true" }, rows[1])
    assert.same({ table = { skillName = "Daggers", skillRank = "1" } }, rows[2])
    _G.C_SkillInfo = nil
  end)

  it("saves the report to the dev DB when run", function()
    ns.devDB = {}
    ns.Probe.Run()
    assert.equals("1.60.1", ns.devDB.probe.build.version)
    assert.truthy(env.output():find("16001"))
  end)
end)
