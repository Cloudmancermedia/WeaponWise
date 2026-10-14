local env = require("spec.helpers.wow_env")

describe("Tooltip.BuildLines", function()
  local ns, build, cfg

  local archibald = {
    name = "Archibald", city = "Undercity", district = "War Quarter", x = 57.3, y = 32.8,
    services = { SWORD_2H = { cost = 1000, levelReq = 20 }, DAGGER = { cost = 5 } }, verified = true,
  }
  local hanashi = { name = "Hanashi", city = "Orgrimmar", district = "Valley of Honor", x = 81.5, y = 19.6,
    services = { SWORD_2H = { cost = 1000 } }, verified = true }

  before_each(function()
    env.reset()
    ns = env.load({ "Core.lua", "Data/WeaponTypes.lua", "Config.lua", "UI/Tooltip.lua" })
    cfg = {}
    for k, v in pairs(ns.Config.defaults) do cfg[k] = v end
    ns.config = cfg
    build = ns.Tooltip.BuildLines
    -- Layout tests read costs as plain text; FormatMoney has its own tests.
    _G.GetMoneyString = function(c)
      return c >= 100 and (math.floor(c / 100) .. "s") or (c .. "c")
    end
  end)

  local function texts(lines)
    local out = {}
    for _, l in ipairs(lines) do out[#out + 1] = l.text end
    return out
  end

  local function trainable(extra)
    local ctx = { result = { state = "TRAINABLE", weapon = "SWORD_2H" }, recommended = archibald,
      alternatives = { hanashi }, playerLevel = 30, canTrack = true }
    for k, v in pairs(extra or {}) do ctx[k] = v end
    return ctx
  end

  it("shows known skill as one green line", function()
    local lines = build({ result = { state = "KNOWN", weapon = "AXE_2H", rank = 245, max = 300 } })
    assert.same({ "You know this weapon skill (245/300)" }, texts(lines))
    assert.same({ 0.1, 1, 0.1 }, lines[1].color)
  end)

  it("adds a New in Forever line", function()
    local lines = build({ result = { state = "KNOWN", weapon = "AXE_1H", rank = 1, max = 5, newInForever = true } })
    assert.equals("New in Forever", lines[2].text)
  end)

  it("shows unavailable weapons in red", function()
    local lines = build({ result = { state = "UNAVAILABLE", weapon = "WAND" } })
    assert.same({ "Your class cannot use this weapon type" }, texts(lines))
    assert.same({ 1, 0.13, 0.13 }, lines[1].color)
  end)

  it("shows the trainer in two lines, then the hints", function()
    local t = texts(build(trainable()))
    assert.same({
      "Can be trained by |cffffffffArchibald|r (Undercity)",
      "War Quarter (57.3, 32.8) · Cost: 10s",
      " ",
      "Hold Shift for other trainers",
      "Ctrl + Right-Click to track trainer",
    }, t)
  end)

  it("skips the Shift hint when there are no other trainers", function()
    local t = texts(build(trainable({ alternatives = {} })))
    assert.equals("Ctrl + Right-Click to track trainer", t[4])
    assert.equals(4, #t)
  end)

  it("adds the training level in orange when the player is too low", function()
    local lines = build(trainable({ playerLevel = 10, alternatives = {} }))
    assert.equals("Requires Level 20 to train", lines[3].text)
    assert.same({ 1, 0.5, 0.25 }, lines[3].color)
  end)

  it("omits cost and coordinates it does not have, and marks unverified data", function()
    local t = texts(build(trainable({ recommended = { name = "Ansekhwa", city = "Thunder Bluff",
      district = "Lower Rise", verified = false } })))
    assert.equals("Lower Rise · unverified", t[2])
  end)

  it("reads cost and level for the weapon being looked at", function()
    local t = texts(build(trainable({ result = { state = "TRAINABLE", weapon = "DAGGER" }, playerLevel = 1,
      alternatives = {} })))
    assert.equals("War Quarter (57.3, 32.8) · Cost: 5c", t[2])
    assert.equals(" ", t[3])
  end)

  it("hides the hint when tracking is not possible", function()
    local t = texts(build(trainable({ canTrack = false, alternatives = {} })))
    assert.equals(2, #t)
  end)

  it("lists alternatives while Shift is held, formatted like the main trainer", function()
    local lines = build(trainable({ shiftDown = true }))
    assert.same({
      "Can be trained by |cffffffffArchibald|r (Undercity)",
      "War Quarter (57.3, 32.8) · Cost: 10s",
      " ",
      "Other Trainers:",
      "Can be trained by |cffffffffHanashi|r (Orgrimmar)",
      "Valley of Honor (81.5, 19.6) · Cost: 10s",
      " ",
      "Ctrl + Right-Click to track trainer",
    }, texts(lines))
    assert.same(lines[1].color, lines[5].color)
    assert.same(lines[2].color, lines[6].color)
    assert.same({ 1, 1, 1 }, lines[2].color)
    assert.same({ 0.5, 0.5, 0.5 }, lines[8].color)
  end)

  it("says the class can learn it when no trainer is known", function()
    local t = texts(build({ result = { state = "TRAINABLE", weapon = "WAND" } }))
    assert.same({ "Your class can learn this weapon type" }, t)
  end)

  it("honours the config switches", function()
    cfg.showKnown = false
    assert.same({}, build({ result = { state = "KNOWN", weapon = "AXE_2H", rank = 1, max = 5 } }))
    cfg.showCost, cfg.showCoordinates, cfg.showHint = false, false, false
    assert.same({ "Can be trained by |cffffffffArchibald|r (Undercity)", "War Quarter" }, texts(build(trainable())))
    cfg.enabled = false
    assert.same({}, build(trainable()))
  end)

  describe("FormatMoney", function()
    after_each(function()
      _G.C_CurrencyInfo, _G.GetMoneyString, _G.GetCoinTextureString = nil, nil, nil
    end)

    it("prefers the client's C_CurrencyInfo coin formatter", function()
      _G.C_CurrencyInfo = { GetCoinTextureString = function(c) return "api:" .. c end }
      assert.equals("api:1000", ns.Tooltip.FormatMoney(1000))
    end)

    it("falls back to GetMoneyString, then the global formatter", function()
      _G.GetMoneyString = function(c) return "money:" .. c end
      assert.equals("money:1000", ns.Tooltip.FormatMoney(1000))
      _G.GetMoneyString = nil
      _G.GetCoinTextureString = function(c) return "global:" .. c end
      assert.equals("global:1000", ns.Tooltip.FormatMoney(1000))
    end)

    it("draws coin icons itself when the client has no formatter", function()
      _G.GetMoneyString = nil
      local gold = "|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t"
      local silver = "|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t"
      local copper = "|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"
      assert.equals("1" .. gold .. " 2" .. silver .. " 3" .. copper, ns.Tooltip.FormatMoney(10203))
      assert.equals("10" .. silver, ns.Tooltip.FormatMoney(1000))
      assert.equals("0" .. copper, ns.Tooltip.FormatMoney(0))
    end)
  end)
end)

describe("Tooltip hooks", function()
  local ns, tooltip, added

  before_each(function()
    env.reset()
    ns = env.load({ "Core.lua", "Data/WeaponTypes.lua", "Config.lua", "UI/Tooltip.lua" })
    added = {}
    tooltip = {
      hooks = {},
      HasScript = function(_, name) return name == "OnTooltipSetItem" end,
      HookScript = function(self, name, fn) self.hooks[name] = fn end,
      GetItem = function() return "Arcanite Reaper", "axe" end,
      GetOwner = function() return nil end,
      AddLine = function(_, text) added[#added + 1] = text end,
      Show = function() end,
    }
    _G.GameTooltip = tooltip
    _G.UnitLevel = function() return 60 end
    _G.IsShiftKeyDown = function() return false end
    ns.Lookup = { ForLink = function(link)
      if link == "axe" then return { result = { state = "UNAVAILABLE", weapon = "AXE_2H" } } end
    end }
  end)

  after_each(function()
    _G.GameTooltip, _G.TooltipDataProcessor = nil, nil
  end)

  it("hooks OnTooltipSetItem when the client has no TooltipDataProcessor", function()
    assert.equals("OnTooltipSetItem", ns.Tooltip.Install())
    tooltip.hooks.OnTooltipSetItem(tooltip)
    assert.same({ " ", "Your class cannot use this weapon type" }, added)
  end)

  it("prefers TooltipDataProcessor when present", function()
    local registered
    _G.TooltipDataProcessor = { AddTooltipPostCall = function(kind, fn) registered = { kind, fn } end }
    _G.Enum = { TooltipDataType = { Item = 0 } }
    assert.equals("TooltipDataProcessor", ns.Tooltip.Install())
    registered[2](tooltip)
    assert.equals(2, #added)
    _G.Enum = nil
  end)

  it("reads the item from the post-call data on tooltips without GetItem or GetOwner", function()
    local registered
    _G.TooltipDataProcessor = { AddTooltipPostCall = function(_, fn) registered = fn end }
    _G.Enum = { TooltipDataType = { Item = 0 } }
    ns.Tooltip.Install()
    tooltip.GetItem, tooltip.GetOwner = nil, nil
    registered(tooltip, { id = 12345, hyperlink = "axe" })
    assert.equals(2, #added)
    added = {}
    ns.Lookup.ForLink = function(item) return item == 12345 and { result = { state = "UNAVAILABLE",
      weapon = "AXE_2H" } } or nil end
    registered(tooltip, { id = 12345 })
    assert.equals(2, #added)
    _G.Enum = nil
  end)

  it("refreshes with RefreshData when the client has it", function()
    local refreshed, entered = 0, 0
    tooltip.IsShown = function() return true end
    tooltip.RefreshData = function() refreshed = refreshed + 1 end
    tooltip.GetOwner = function()
      return { GetScript = function() return function() entered = entered + 1 end end }
    end
    ns.devDB = {}
    ns.Tooltip.Refresh()
    assert.same({ 1, 0 }, { refreshed, entered })
    assert.equals("RefreshData", ns.devDB.refreshLog[1].path)
  end)

  it("logs why a refresh did nothing", function()
    ns.devDB = {}
    tooltip.IsShown = function() return false end
    ns.Tooltip.Refresh()
    assert.equals("hidden", ns.devDB.refreshLog[1].path)
  end)

  it("refreshes by re-running the owner's OnEnter, even without GetItem", function()
    local entered = 0
    local owner = { GetScript = function() return function() entered = entered + 1 end end }
    tooltip.GetItem = nil
    tooltip.IsShown = function() return true end
    tooltip.GetOwner = function() return owner end
    ns.Tooltip.Refresh()
    assert.equals(1, entered)
  end)

  it("does nothing when it cannot tell which item the tooltip shows", function()
    tooltip.GetItem = nil
    ns.Tooltip.Install()
    tooltip.hooks.OnTooltipSetItem(tooltip)
    assert.same({}, added)
  end)

  it("leaves non-weapon tooltips untouched", function()
    tooltip.GetItem = function() return "Linen Shirt", "shirt" end
    ns.Tooltip.Install()
    tooltip.hooks.OnTooltipSetItem(tooltip)
    assert.same({}, added)
  end)
end)
