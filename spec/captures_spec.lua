local env = require("spec.helpers.wow_env")
local Captures = require("tools.captures")

describe("tools/captures", function()
  local ns

  before_each(function()
    env.reset()
    ns = env.load({ "Core.lua", "Data/WeaponTypes.lua", "Data/Cities.lua" })
  end)

  local function archibaldCapture(services)
    return {
      npcID = 4556, name = "Archibald", faction = "Horde",
      location = { zone = "Undercity", subZone = "War Quarter", mapID = 1458, x = 57.345, y = 32.81 },
      servicesByClass = services,
    }
  end

  it("turns a weapon master capture into a verified trainer record", function()
    local db = { trainers = { [4556] = archibaldCapture({
      ROGUE = { { name = "Daggers", kind = "used", cost = 1000, levelReq = 1 } },
      WARRIOR = { { name = "Two-Handed Swords", kind = "available", cost = 1000, levelReq = 20 },
        { name = "Daggers", kind = "available", cost = 900, levelReq = 1 } },
    }) } }
    local trainers, warnings = Captures.ToTrainers(db, ns.WeaponTypes, ns.Cities)
    assert.same({}, warnings)
    assert.same({
      name = "Archibald", npcID = 4556, faction = "Horde", city = "Undercity", district = "War Quarter",
      mapID = 1458, x = 57.3, y = 32.8, teaches = { "DAGGER", "SWORD_2H" },
      services = { DAGGER = { cost = 1000, levelReq = 1 }, SWORD_2H = { cost = 1000, levelReq = 20 } },
      source = "capture", verified = true,
    }, trainers[1])
  end)

  it("skips trainers with no weapon skills and warns about unknown service names", function()
    local classTrainer = archibaldCapture({ MAGE = { { name = "Frostbolt", kind = "available", cost = 100 } } })
    classTrainer.name = "Mage Trainer"
    local odd = archibaldCapture({ WARRIOR = { { name = "Daggers", cost = 1 }, { name = "Spears", cost = 1 } } })
    local trainers, warnings = Captures.ToTrainers({ trainers = { [1] = classTrainer, [2] = odd } },
      ns.WeaponTypes, ns.Cities)
    assert.equals(1, #trainers)
    assert.same({ "DAGGER" }, trainers[1].teaches)
    table.sort(warnings)
    assert.truthy(warnings[1]:find("Archibald: unknown service \"Spears\""))
    assert.truthy(warnings[2]:find("skipped Mage Trainer"))
  end)

  it("warns when a capture's zone is not a known city", function()
    local c = archibaldCapture({ WARRIOR = { { name = "Daggers", cost = 1 } } })
    c.location.zone = "Brill"
    local trainers, warnings = Captures.ToTrainers({ trainers = { c } }, ns.WeaponTypes, ns.Cities)
    assert.equals("Brill", trainers[1].city)
    assert.truthy(warnings[1]:find("not a known city"))
  end)

  it("replaces wiki records by name and faction, keeping the rest in order", function()
    local existing = {
      { name = "Hanashi", faction = "Horde", source = "wiki" },
      { name = "Archibald", faction = "Horde", source = "wiki" },
    }
    local merged = Captures.Merge(existing, {
      { name = "Archibald", faction = "Horde", source = "capture" },
      { name = "Ilyenia Moonfire", faction = "Alliance", source = "capture" },
    })
    assert.same({ "wiki", "capture", "capture" }, { merged[1].source, merged[2].source, merged[3].source })
    assert.equals("Ilyenia Moonfire", merged[3].name)
  end)

  it("lists weapons a faction has no trainer for, skipping wands", function()
    local gaps = Captures.CoverageGaps({
      { faction = "Horde", teaches = { "DAGGER" } },
      { faction = "Alliance", teaches = { "DAGGER", "BOW" } },
    }, { DAGGER = {}, BOW = {}, WAND = {} })
    assert.same({ "Horde: BOW" }, gaps)
  end)

  it("serializes to a data file the addon can load back", function()
    local trainers = { { name = "Archibald", faction = "Horde", city = "Undercity", teaches = { "DAGGER" },
      services = { DAGGER = { cost = 1000 } }, source = "capture", verified = true } }
    local text = Captures.Serialize(trainers)
    local loaded = {}
    assert(load(text, "WeaponTrainers", "t"))("WeaponWise", loaded)
    assert.same(trainers, loaded.WeaponTrainers)
    assert.equals(text, Captures.Serialize(loaded.WeaponTrainers))
  end)
end)
