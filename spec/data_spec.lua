local env = require("spec.helpers.wow_env")

describe("Data", function()
  local ns

  before_each(function()
    env.reset()
    ns = env.load({ "Core.lua", "Data/WeaponTypes.lua", "Data/ClassWeapons.lua", "Data/WeaponTrainers.lua" })
  end)

  it("maps every weapon type to a unique item subclass ID and a skill name", function()
    local seen, seenSkill = {}, {}
    for key, wt in pairs(ns.WeaponTypes) do
      assert.is_number(wt.subclassID, key)
      assert.is_nil(seen[wt.subclassID], "duplicate subclass " .. wt.subclassID)
      seen[wt.subclassID] = true
      assert.is_string(wt.skillName, key)
      assert.is_number(wt.skillID, key)
      assert.is_nil(seenSkill[wt.skillID], "duplicate skillID " .. tostring(wt.skillID))
      seenSkill[wt.skillID] = true
      assert.equals(key, ns.WeaponTypeBySubclass[wt.subclassID])
    end
  end)

  it("only references known weapon types in class rules", function()
    for class, rules in pairs(ns.ClassWeapons) do
      for key in pairs(rules) do
        assert.is_table(ns.WeaponTypes[key], class .. " references " .. key)
      end
    end
  end)

  it("only lists Forever additions the Classic Era baseline lacks", function()
    for class, additions in pairs(ns.ForeverAdditions) do
      assert.is_table(ns.ClassicWeapons[class], class)
      for key in pairs(additions) do
        assert.is_table(ns.WeaponTypes[key], class .. " adds unknown " .. key)
        assert.is_nil(ns.ClassicWeapons[class][key], class .. " already had " .. key .. " in Classic")
        assert.is_true(ns.ClassWeapons[class][key], class .. " merged rules miss " .. key)
      end
    end
  end)

  it("gives every trainer a faction, city, known weapon types, and a source", function()
    for _, t in ipairs(ns.WeaponTrainers) do
      assert.is_string(t.name)
      assert.truthy(t.faction == "Horde" or t.faction == "Alliance", t.name)
      assert.is_string(t.city, t.name)
      assert.is_string(t.source, t.name)
      assert.is_boolean(t.verified, t.name)
      assert.truthy(#t.teaches > 0, t.name)
      for _, key in ipairs(t.teaches) do
        assert.is_table(ns.WeaponTypes[key], t.name .. " teaches unknown " .. key)
      end
    end
  end)

  it("has a trainer in each faction for every trainable weapon except wands", function()
    local taught = { Horde = {}, Alliance = {} }
    for _, t in ipairs(ns.WeaponTrainers) do
      for _, key in ipairs(t.teaches) do taught[t.faction][key] = true end
    end
    for faction, keys in pairs(taught) do
      for key in pairs(ns.WeaponTypes) do
        if key ~= "WAND" then assert.is_true(keys[key], faction .. " has no trainer for " .. key) end
      end
    end
  end)

  it("only marks owner-confirmed or captured trainers as verified", function()
    for _, t in ipairs(ns.WeaponTrainers) do
      if t.source ~= "capture" and t.source ~= "owner" then assert.is_false(t.verified, t.name) end
    end
  end)

  it("charges 10s per weapon, except polearms at 1g and level 20", function()
    for _, t in ipairs(ns.WeaponTrainers) do
      for _, key in ipairs(t.teaches) do
        local svc = t.services and t.services[key]
        assert.is_table(svc, t.name .. " has no price for " .. key)
        if key == "POLEARM" then
          assert.same({ cost = 10000, levelReq = 20 }, svc, t.name)
        else
          assert.same({ cost = 1000 }, svc, t.name .. " " .. key)
        end
      end
    end
  end)
end)
