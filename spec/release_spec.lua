local Release = dofile("tools/release.lua")

describe("Release.Toc", function()
  local toc = table.concat({
    "## Interface: 16001",
    "## Version: 0.1.0-dev",
    "## SavedVariables: WeaponWiseDB, WeaponWiseDevDB",
    "",
    "Core.lua",
    "Data\\WeaponTypes.lua",
    "Dev\\Probe.lua",
    "Dev\\Capture.lua",
    "",
  }, "\n")

  it("sets the version and drops dev files and dev saved variables", function()
    local out, files = Release.Toc(toc, "0.1.0")
    assert.equals(table.concat({
      "## Interface: 16001",
      "## Version: 0.1.0",
      "## SavedVariables: WeaponWiseDB",
      "",
      "Core.lua",
      "Data\\WeaponTypes.lua",
      "",
    }, "\n"), out)
    assert.same({ "Core.lua", "Data/WeaponTypes.lua" }, files)
  end)

  it("refuses a dev or missing version", function()
    assert.has_error(function() Release.Toc(toc, "0.1.0-dev") end)
    assert.has_error(function() Release.Toc(toc, "") end)
  end)
end)

describe("release build", function()
  it("loads and survives login without the dev files", function()
    local env = require("spec.helpers.wow_env")
    local f = assert(io.open("WeaponWise.toc"))
    local _, files = Release.Toc(f:read("a"), "9.9.9")
    f:close()
    env.reset()
    _G.WeaponWiseDB, _G.WeaponWiseDevDB = nil, nil
    _G.GameTooltip = { HasScript = function() return true end, HookScript = function() end }
    local ns = env.load(files)
    ns.frame.scripts.OnEvent(ns.frame, "ADDON_LOADED", "WeaponWise")
    ns.frame.scripts.OnEvent(ns.frame, "PLAYER_LOGIN")
    assert.equals(_G.WeaponWiseDB, ns.config)
    assert.is_nil(ns.commands.probe)
    assert.is_nil(_G.WeaponWiseDevDB)
    assert.is_table(ns.commands.set)
    _G.GameTooltip = nil
  end)
end)
