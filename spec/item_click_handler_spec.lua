local env = require("spec.helpers.wow_env")

describe("ItemClickHandler", function()
  local ns, handler, tracked

  before_each(function()
    env.reset()
    ns = env.load({ "Core.lua", "Data/WeaponTypes.lua", "Config.lua", "UI/ItemClickHandler.lua" })
    ns.config = { enabled = true, trackBinding = "CTRL-RightButton" }
    tracked = nil
    ns.NavigationService = { Track = function(t, w) tracked = { t.name, w }; return "native" end }
    ns.Lookup = {
      ForLink = function(link)
        if link == "axe" then
          return { result = { state = "TRAINABLE", weapon = "AXE_2H" }, recommended = { name = "Hanashi" } }
        elseif link == "dagger" then
          return { result = { state = "KNOWN", weapon = "DAGGER" } }
        end
      end,
    }
    handler = ns.ItemClickHandler
  end)

  it("matches the binding exactly, including modifiers", function()
    assert.is_true(handler.Matches("CTRL-RightButton", "RightButton", { ctrl = true }))
    assert.is_false(handler.Matches("CTRL-RightButton", "RightButton", { ctrl = true, shift = true }))
    assert.is_false(handler.Matches("CTRL-RightButton", "LeftButton", { ctrl = true }))
    assert.is_true(handler.Matches("ALT-LeftButton", "LeftButton", { alt = true }))
  end)

  it("tracks the recommended trainer on a matching click", function()
    assert.is_true(handler.HandleClick("axe", "RightButton", { ctrl = true }))
    assert.same({ "Hanashi", "AXE_2H" }, tracked)
  end)

  it("ignores non-matching clicks silently", function()
    assert.is_false(handler.HandleClick("axe", "RightButton", {}))
    assert.is_nil(tracked)
    assert.equals("", env.output())
  end)

  it("explains when there is nothing to track", function()
    assert.is_false(handler.HandleClick("dagger", "RightButton", { ctrl = true }))
    assert.is_nil(tracked)
    assert.is_false(handler.HandleClick("shirt", "RightButton", { ctrl = true }))
  end)

  it("does nothing while the addon is disabled", function()
    ns.config.enabled = false
    assert.is_false(handler.HandleClick("axe", "RightButton", { ctrl = true }))
  end)

  it("hooks the shared modified-click handler and tracks from the clicked link", function()
    local hooked
    _G.hooksecurefunc = function(name, fn) hooked = { name, fn } end
    _G.HandleModifiedItemClick = function() end
    _G.GetMouseButtonClicked = function() return "RightButton" end
    _G.IsControlKeyDown = function() return true end
    _G.IsAltKeyDown = function() return false end
    _G.IsShiftKeyDown = function() return false end
    assert.is_true(handler.Install())
    assert.equals("HandleModifiedItemClick", hooked[1])
    hooked[2]("axe")
    assert.same({ "Hanashi", "AXE_2H" }, tracked)
    _G.HandleModifiedItemClick, _G.GetMouseButtonClicked = nil, nil
  end)

  it("installs nothing when the client lacks the shared handler", function()
    _G.HandleModifiedItemClick = nil
    assert.is_false(handler.Install())
  end)

  it("describes the binding for the tooltip hint", function()
    assert.equals("Ctrl + Right-Click", handler.BindingLabel("CTRL-RightButton"))
    assert.equals("Alt + Left-Click", handler.BindingLabel("ALT-LeftButton"))
  end)
end)
