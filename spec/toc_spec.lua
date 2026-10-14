local env = require("spec.helpers.wow_env")

local function readToc()
  local version, files = nil, {}
  for line in io.lines("WeaponWise.toc") do
    local v = line:match("^## Version:%s*(%S+)")
    if v then version = v end
    if line ~= "" and not line:match("^#") then files[#files + 1] = (line:gsub("\\", "/")) end
  end
  return version, files
end

describe("WeaponWise.toc", function()
  it("loads every listed file in order and survives login", function()
    env.reset()
    _G.WeaponWiseDB, _G.WeaponWiseDevDB = nil, nil
    _G.GameTooltip = { HasScript = function() return true end, HookScript = function() end }
    local _, files = readToc()
    local ns = env.load(files)
    ns.frame.scripts.OnEvent(ns.frame, "ADDON_LOADED", "WeaponWise")
    ns.frame.scripts.OnEvent(ns.frame, "PLAYER_LOGIN")
    assert.equals(_G.WeaponWiseDB, ns.config)
    assert.equals(_G.WeaponWiseDevDB, ns.devDB)
    for _, cmd in ipairs({ "probe", "capture", "clicktest", "pin", "set", "config" }) do
      assert.is_table(ns.commands[cmd], cmd)
    end
    _G.GameTooltip = nil
  end)

  it("passes the release gate: verified data and no dev tools", function()
    local version, files = readToc()
    if version:find("%-dev") then
      pending("release gate applies to non-dev versions; current " .. version)
      return
    end
    for _, f in ipairs(files) do assert.is_nil(f:match("^Dev/"), f .. " ships dev tooling") end
    env.reset()
    local ns = env.load({ "Data/WeaponTrainers.lua" })
    for _, t in ipairs(ns.WeaponTrainers) do assert.is_true(t.verified, t.name .. " is unverified") end
  end)
end)
