local env = require("spec.helpers.wow_env")

describe("TrainerService", function()
  local ns, svc

  before_each(function()
    env.reset()
    ns = env.load({ "Core.lua", "Data/WeaponTypes.lua", "Data/Cities.lua", "Services/TrainerService.lua" })
    ns.WeaponTrainers = {
      { name = "A", faction = "Horde", city = "Orgrimmar", teaches = { "AXE_2H" }, verified = false },
      { name = "B", faction = "Horde", city = "Undercity", teaches = { "AXE_2H", "SWORD_2H" }, verified = false },
      { name = "C", faction = "Alliance", city = "Ironforge", teaches = { "AXE_2H" }, verified = false },
      { name = "D", faction = "Horde", city = "Thunder Bluff", teaches = { "AXE_2H" }, verified = true },
    }
    svc = ns.TrainerService
  end)

  local function names(list)
    local out = {}
    for _, t in ipairs(list) do out[#out + 1] = t.name end
    return out
  end

  it("lists trainers for a weapon and faction only", function()
    assert.same({ "A", "B", "D" }, names(svc.ForWeapon("AXE_2H", "Horde")))
    assert.same({ "B" }, names(svc.ForWeapon("SWORD_2H", "Horde")))
    assert.same({ "C" }, names(svc.ForWeapon("AXE_2H", "Alliance")))
  end)

  it("recommends a trainer in the player's current city first", function()
    local rec, alts = svc.Recommend("AXE_2H", "Horde", { zone = "Undercity", continent = 1415 })
    assert.equals("B", rec.name)
    assert.same({ "D", "A" }, names(alts))
  end)

  it("picks the nearest trainer on the player's continent when world positions exist", function()
    local worlds = { A = { x = 0, y = 0 }, D = { x = 100, y = 100 } }
    local player = { zone = "The Barrens", continent = 1414, world = { x = 90, y = 90 } }
    local rec, alts = svc.Recommend("AXE_2H", "Horde", player, function(t) return worlds[t.name] end)
    assert.equals("D", rec.name)
    assert.same({ "A", "B" }, names(alts))
  end)

  it("falls back to verified-first list order on the continent without world positions", function()
    local rec = svc.Recommend("AXE_2H", "Horde", { zone = "Durotar", continent = 1414 })
    assert.equals("D", rec.name)
  end)

  it("ranks same-continent trainers above other continents", function()
    local rec, alts = svc.Recommend("AXE_2H", "Horde", { zone = "Tirisfal Glades", continent = 1415 })
    assert.equals("B", rec.name)
    assert.same({ "D", "A" }, names(alts))
  end)

  it("is deterministic when the continent is unknown, such as inside an instance", function()
    local rec = svc.Recommend("AXE_2H", "Horde", { zone = "Ragefire Chasm" })
    assert.equals("D", rec.name)
  end)

  it("returns nothing when no trainer teaches the weapon", function()
    local rec, alts = svc.Recommend("WAND", "Horde", { zone = "Orgrimmar" })
    assert.is_nil(rec)
    assert.same({}, alts)
  end)
end)
