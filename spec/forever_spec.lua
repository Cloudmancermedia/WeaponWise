local env = require("spec.helpers.wow_env")

-- End to end, item link to tooltip lines, with the real data files. Every
-- Forever addition goes through the path the owner verified in game for
-- Shaman and Rogue (2026-10-13), so Druid polearms get the same check.
describe("Forever additions in the tooltip", function()
  local ns, class, faction, skills

  before_each(function()
    env.reset()
    ns = env.load({
      "Core.lua", "Config.lua", "Data/WeaponTypes.lua", "Data/ClassWeapons.lua", "Data/Cities.lua",
      "Data/WeaponTrainers.lua", "Services/WeaponSkillService.lua", "Services/TrainerService.lua",
      "Services/Location.lua", "Services/Lookup.lua", "UI/Tooltip.lua",
    })
    ns.config = {}
    for k, v in pairs(ns.Config.defaults) do ns.config[k] = v end
    ns.config.recommendNearest = false
    _G.GetItemInfoInstant = function(subclassID) return 1, nil, nil, nil, nil, 2, subclassID end
    _G.UnitClass = function() return class, class end
    _G.UnitFactionGroup = function() return faction end
    _G.GetMoneyString = function(c) return c .. "c" end
    ns.WeaponSkillService.ReadSkills = function() return skills end
  end)

  after_each(function()
    _G.GetItemInfoInstant, _G.GetMoneyString = nil, nil
  end)

  local function hover(cls, fac, weaponKey, known, level)
    class, faction, skills = cls, fac, known or {}
    ns.frame.scripts.OnEvent(ns.frame, "SKILL_LINES_CHANGED")
    local info = ns.Lookup.ForLink(ns.WeaponTypes[weaponKey].subclassID)
    info.playerLevel = level or 60
    local out = {}
    for _, line in ipairs(ns.Tooltip.BuildLines(info)) do out[#out + 1] = line.text end
    return out, info
  end

  local function has(lines, text)
    for _, l in ipairs(lines) do
      if l == text then return true end
    end
    return false
  end

  for cls, additions in pairs({ SHAMAN = { "AXE_2H", "MACE_2H" }, ROGUE = { "AXE_1H" }, DRUID = { "POLEARM" } }) do
    for _, key in ipairs(additions) do
      it(cls .. " " .. key .. " is in the Forever list", function()
        assert.is_true(ns.ForeverAdditions[cls][key])
      end)

      for _, fac in ipairs({ "Horde", "Alliance" }) do
        it(("%s %s, %s, untrained: trainer line then New in Forever"):format(cls, key, fac), function()
          local lines, info = hover(cls, fac, key)
          assert.equals("TRAINABLE", info.result.state)
          assert.equals(fac, info.recommended.faction)
          assert.truthy(lines[1]:find("^Can be trained by "), lines[1])
          assert.is_true(has(lines, "New in Forever"))
        end)
      end

      it(("%s %s, trained: known line then New in Forever"):format(cls, key), function()
        local id = ns.WeaponTypes[key].skillID
        local lines = hover(cls, "Horde", key, { [id] = { rank = 1, max = 300 } })
        assert.same({ "You know this weapon skill (1/300)", "New in Forever" }, lines)
      end)
    end
  end

  it("warns a level 10 Druid that polearms need level 20, at 1g", function()
    local lines = hover("DRUID", "Horde", "POLEARM", nil, 10)
    assert.equals("Can be trained by |cffffffffArchibald|r (Undercity)", lines[1])
    assert.equals("War Quarter (57.0, 32.0) · Cost: 10000c", lines[2])
    assert.equals("Requires Level 20 to train", lines[3])
    assert.equals("New in Forever", lines[4])
  end)

  it("does not tag weapons a class already had in Classic", function()
    local lines = hover("DRUID", "Horde", "FIST")
    assert.is_false(has(lines, "New in Forever"))
    lines = hover("SHAMAN", "Horde", "MACE_1H")
    assert.is_false(has(lines, "New in Forever"))
  end)
end)
