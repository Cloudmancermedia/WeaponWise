local env = require("spec.helpers.wow_env")

describe("Core", function()
  local ns

  before_each(function()
    env.reset()
    ns = env.load({ "Core.lua" })
  end)

  it("registers /ww and /weaponwise", function()
    assert.equals("/ww", _G.SLASH_WEAPONWISE1)
    assert.equals("/weaponwise", _G.SLASH_WEAPONWISE2)
    assert.is_function(_G.SlashCmdList.WEAPONWISE)
  end)

  it("routes a subcommand and passes the rest of the line", function()
    local got
    ns.RegisterCommand("capture", function(rest) got = rest end, "toggle capture")
    _G.SlashCmdList.WEAPONWISE("  CAPTURE on ")
    assert.equals("on", got)
  end)

  it("prints sorted help for an unknown command", function()
    ns.RegisterCommand("probe", function() end, "report client APIs")
    ns.RegisterCommand("capture", function() end, "toggle capture")
    _G.SlashCmdList.WEAPONWISE("nope")
    local out = env.output()
    assert.truthy(out:find("capture.*probe"))
  end)

  it("dispatches events to every registered handler", function()
    local calls = {}
    ns.On("ADDON_LOADED", function(name) calls[#calls + 1] = "a:" .. name end)
    ns.On("ADDON_LOADED", function(name) calls[#calls + 1] = "b:" .. name end)
    assert.is_true(ns.frame.events.ADDON_LOADED)
    ns.frame.scripts.OnEvent(ns.frame, "ADDON_LOADED", "WeaponWise")
    assert.same({ "a:WeaponWise", "b:WeaponWise" }, calls)
  end)

  it("creates the dev saved-variable table on load when dev tools are present", function()
    _G.WeaponWiseDevDB = nil
    ns.devTools = true
    ns.frame.scripts.OnEvent(ns.frame, "ADDON_LOADED", "WeaponWise")
    assert.is_table(_G.WeaponWiseDevDB)
    assert.is_table(ns.devDB)
  end)

  it("leaves the dev table alone in a release build", function()
    _G.WeaponWiseDevDB = nil
    ns.frame.scripts.OnEvent(ns.frame, "ADDON_LOADED", "WeaponWise")
    assert.is_nil(_G.WeaponWiseDevDB)
    assert.is_nil(ns.devDB)
  end)
end)
