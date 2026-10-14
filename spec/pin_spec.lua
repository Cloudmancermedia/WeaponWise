local env = require("spec.helpers.wow_env")

describe("Pin", function()
  local ns, printed, tracked

  before_each(function()
    env.reset()
    ns = env.load({ "Core.lua", "Data/WeaponTypes.lua", "Data/WeaponTrainers.lua", "Dev/Pin.lua" })
    printed, tracked = {}, {}
    ns.Print = function(...) printed[#printed + 1] = table.concat({ ... }, " ") end
    ns.NavigationService = { Track = function(t, key) tracked[#tracked + 1] = { t.name, key } end }
  end)

  it("pins the trainer whose name starts with the argument, any case", function()
    ns.commands.pin.handler("arch")
    assert.same({ { "Archibald", "CROSSBOW" } }, tracked)
  end)

  it("matches names with spaces", function()
    ns.commands.pin.handler("Woo Ping")
    assert.same({ { "Woo Ping", "CROSSBOW" } }, tracked)
  end)

  it("lists every trainer when given no name", function()
    ns.commands.pin.handler("")
    assert.same({}, tracked)
    assert.equals(#ns.WeaponTrainers + 1, #printed)
    assert.truthy(printed[2]:find("Hanashi", 1, true))
  end)

  it("says so when nothing matches", function()
    ns.commands.pin.handler("nobody")
    assert.same({}, tracked)
    assert.truthy(printed[1]:find("no trainer", 1, true))
  end)
end)
