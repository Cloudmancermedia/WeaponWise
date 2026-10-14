local env = require("spec.helpers.wow_env")

describe("WeaponSkillService", function()
  local ns, svc

  before_each(function()
    env.reset()
    ns = env.load({
      "Core.lua", "Data/WeaponTypes.lua", "Data/ClassWeapons.lua", "Services/WeaponSkillService.lua",
    })
    svc = ns.WeaponSkillService
  end)

  local AXE_2H = 1
  local DAGGER = 15
  local WAND = 19
  local FISHING_POLE = 20

  describe("Evaluate", function()
    it("returns KNOWN with rank and max when the skill is in the skill list", function()
      local skills = { ["Two-Handed Axes"] = { rank = 245, max = 300 } }
      assert.same({ state = "KNOWN", weapon = "AXE_2H", rank = 245, max = 300 },
        svc.Evaluate(AXE_2H, "WARRIOR", skills))
    end)

    it("matches the skill by ID, so non-English clients work", function()
      local skills = { [172] = { rank = 3, max = 300 }, ["Haches à deux mains"] = { rank = 3, max = 300 } }
      assert.same({ state = "KNOWN", weapon = "AXE_2H", rank = 3, max = 300 },
        svc.Evaluate(AXE_2H, "WARRIOR", skills))
    end)

    it("returns TRAINABLE when the class can learn it but has not", function()
      assert.same({ state = "TRAINABLE", weapon = "AXE_2H" }, svc.Evaluate(AXE_2H, "WARRIOR", {}))
    end)

    it("returns UNAVAILABLE when the class cannot learn it", function()
      assert.same({ state = "UNAVAILABLE", weapon = "AXE_2H" }, svc.Evaluate(AXE_2H, "MAGE", {}))
    end)

    it("prefers KNOWN over class rules, so data gaps never hide a real skill", function()
      local skills = { Daggers = { rank = 1, max = 5 } }
      assert.equals("KNOWN", svc.Evaluate(DAGGER, "PALADIN", skills).state)
    end)

    it("returns nil for subclasses it does not track", function()
      assert.is_nil(svc.Evaluate(FISHING_POLE, "WARRIOR", {}))
      assert.is_nil(svc.Evaluate(nil, "WARRIOR", {}))
    end)

    it("returns nil for an unknown class rather than guessing", function()
      assert.is_nil(svc.Evaluate(AXE_2H, "DEATHKNIGHT", {}))
    end)

    it("treats a learnable weapon with no trainer as TRAINABLE without trainer data", function()
      assert.same({ state = "TRAINABLE", weapon = "WAND" }, svc.Evaluate(WAND, "PRIEST", {}))
    end)
  end)

  describe("Forever additions", function()
    local AXE_1H = 0
    local MACE_2H = 5

    it("marks a weapon added to the class by Forever as TRAINABLE and new", function()
      assert.same({ state = "TRAINABLE", weapon = "AXE_1H", newInForever = true },
        svc.Evaluate(AXE_1H, "ROGUE", {}))
      assert.same({ state = "TRAINABLE", weapon = "MACE_2H", newInForever = true },
        svc.Evaluate(MACE_2H, "SHAMAN", {}))
      assert.same({ state = "TRAINABLE", weapon = "POLEARM", newInForever = true },
        svc.Evaluate(6, "DRUID", {}))
    end)

    it("keeps the new flag once the skill is known", function()
      local skills = { Axes = { rank = 40, max = 100 } }
      assert.is_true(svc.Evaluate(AXE_1H, "ROGUE", skills).newInForever)
    end)

    it("does not flag Classic Era weapons", function()
      assert.is_nil(svc.Evaluate(DAGGER, "ROGUE", {}).newInForever)
      assert.is_nil(svc.Evaluate(AXE_1H, "WARRIOR", {}).newInForever)
    end)
  end)

  describe("when skills cannot be read", function()
    it("still reports weapons the class can never use", function()
      assert.equals("UNAVAILABLE", svc.Evaluate(AXE_2H, "MAGE", nil).state)
    end)

    it("returns nil rather than guessing KNOWN or TRAINABLE", function()
      assert.is_nil(svc.Evaluate(AXE_2H, "WARRIOR", nil))
    end)

    it("ReadSkills returns nil when the skill API is missing", function()
      _G.GetNumSkillLines, _G.GetSkillLineInfo = nil, nil
      assert.is_nil(svc.ReadSkills())
    end)
  end)

  describe("ReadSkills with C_SkillInfo", function()
    after_each(function() _G.C_SkillInfo = nil end)

    it("reads classic-style returns from C_SkillInfo", function()
      local lines = { { "Weapon Skills", true }, { "Daggers", false, 120, 150 } }
      _G.C_SkillInfo = {
        GetNumSkillLines = function() return #lines end,
        GetSkillLineInfo = function(i) local l = lines[i]; return l[1], l[2], true, l[3], 0, 0, l[4] end,
      }
      assert.same({ Daggers = { rank = 120, max = 150 } }, svc.ReadSkills())
    end)

    it("reads the table rows Forever 1.60.1 returns", function()
      -- Field names from a real /ww probe skillLineDump, 2026-10-13.
      local rows = {
        { name = "Weapon Skills", isHeader = true, rank = 0, maxRank = 0, skillID = 0 },
        { name = "Axes", isHeader = false, rank = 1, maxRank = 55, skillID = 44 },
        { name = "Daggers", isHeader = false, rank = 54, maxRank = 55, skillID = 173 },
      }
      _G.C_SkillInfo = {
        GetNumSkillLines = function() return #rows end,
        GetSkillLineInfo = function(i) return rows[i] end,
      }
      local skills = svc.ReadSkills()
      assert.same({ rank = 1, max = 55 }, skills.Axes)
      assert.same({ rank = 54, max = 55 }, skills.Daggers)
      assert.equals(skills.Axes, skills[44])
      assert.equals(skills.Daggers, skills[173])
      assert.is_nil(skills[0])
    end)

    it("indexes by skill ID even when the client returns it as a string", function()
      local rows = { { name = "Dagues", isHeader = false, rank = 5, maxRank = 55, skillID = "173" } }
      _G.C_SkillInfo = {
        GetNumSkillLines = function() return #rows end,
        GetSkillLineInfo = function(i) return rows[i] end,
      }
      assert.same({ rank = 5, max = 55 }, svc.ReadSkills()[173])
    end)

    it("returns nil for a row shape it does not recognise", function()
      _G.C_SkillInfo = {
        GetNumSkillLines = function() return 1 end,
        GetSkillLineInfo = function() return 42 end,
      }
      assert.is_nil(svc.ReadSkills())
    end)
  end)

  describe("ReadSkills", function()
    it("maps non-header skill lines by name", function()
      local lines = {
        { "Weapon Skills", true },
        { "Daggers", false, 120, 150 },
        { "Professions", true },
        { "Mining", false, 75, 150 },
      }
      _G.GetNumSkillLines = function() return #lines end
      _G.GetSkillLineInfo = function(i)
        local l = lines[i]
        return l[1], l[2], true, l[3], 0, 0, l[4]
      end
      local skills = svc.ReadSkills()
      assert.same({ rank = 120, max = 150 }, skills.Daggers)
      assert.is_nil(skills["Weapon Skills"])
      _G.GetNumSkillLines, _G.GetSkillLineInfo = nil, nil
    end)
  end)
end)
