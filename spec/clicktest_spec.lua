local env = require("spec.helpers.wow_env")

describe("ClickTest", function()
  local ns

  before_each(function()
    env.reset()
    _G.IsControlKeyDown = function() return true end
    _G.IsAltKeyDown = function() return false end
    _G.IsShiftKeyDown = function() return false end
    ns = env.load({ "Core.lua", "Dev/ClickTest.lua" })
    ns.devDB = {}
  end)

  it("ignores clicks while disabled", function()
    ns.ClickTest.Record("bag OnClick", "RightButton", "[Axe]")
    assert.is_nil(ns.devDB.clickLog)
  end)

  it("records source, button, modifiers, and item while enabled", function()
    ns.ClickTest.SetEnabled(true)
    ns.ClickTest.Record("bag OnClick", "RightButton", "[Axe]")
    assert.same({ source = "bag OnClick", button = "RightButton", mods = "ctrl", item = "[Axe]" }, ns.devDB.clickLog[1])
  end)

  it("records which mouse button fired a hooked function when the client says", function()
    _G.GetMouseButtonClicked = function() return "RightButton" end
    ns.ClickTest.SetEnabled(true)
    ns.ClickTest.Record("HandleModifiedItemClick", nil, "[Axe]")
    assert.equals("RightButton", ns.devDB.clickLog[1].button)
    _G.GetMouseButtonClicked = nil
  end)

  it("keeps only the newest 50 entries", function()
    ns.ClickTest.SetEnabled(true)
    for i = 1, 55 do ns.ClickTest.Record("s" .. i, "LeftButton") end
    assert.equals(50, #ns.devDB.clickLog)
    assert.equals("s6", ns.devDB.clickLog[1].source)
  end)
end)
