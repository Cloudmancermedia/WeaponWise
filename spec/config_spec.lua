local env = require("spec.helpers.wow_env")

describe("Config", function()
  local ns

  before_each(function()
    env.reset()
    _G.WeaponWiseDB = nil
    ns = env.load({ "Core.lua", "Config.lua" })
  end)

  local function load()
    ns.frame.scripts.OnEvent(ns.frame, "ADDON_LOADED", "WeaponWise")
  end

  it("fills defaults on first load", function()
    load()
    assert.is_true(ns.config.enabled)
    assert.equals("CTRL-RightButton", ns.config.trackBinding)
    assert.is_false(ns.config.preferTomTom)
    assert.equals(_G.WeaponWiseDB, ns.config)
  end)

  it("keeps saved choices and adds new defaults", function()
    _G.WeaponWiseDB = { showCost = false }
    load()
    assert.is_false(ns.config.showCost)
    assert.is_true(ns.config.showHint)
  end)

  it("sets booleans and bindings through /ww set", function()
    load()
    _G.SlashCmdList.WEAPONWISE("set showCost off")
    assert.is_false(ns.config.showCost)
    _G.SlashCmdList.WEAPONWISE("set trackBinding ALT-LeftButton")
    assert.equals("ALT-LeftButton", ns.config.trackBinding)
  end)

  it("rejects unknown settings and bad values", function()
    load()
    _G.SlashCmdList.WEAPONWISE("set nope on")
    _G.SlashCmdList.WEAPONWISE("set trackBinding SHIFT-MiddleButton")
    _G.SlashCmdList.WEAPONWISE("set showCost maybe")
    assert.equals("CTRL-RightButton", ns.config.trackBinding)
    assert.is_true(ns.config.showCost)
    assert.truthy(env.output():find("unknown setting"))
  end)
end)
