-- Settings, stored per account in WeaponWiseDB and changed with
-- /ww set <key> <value>. No options panel or minimap button.
local addonName, ns = ...

local Config = {}
ns.Config = Config

Config.defaults = {
  enabled = true,
  showKnown = true,
  showTrainable = true,
  showUnavailable = true,
  showCost = true,
  showCoordinates = true,
  recommendNearest = true,
  showAlternatives = true,
  showHint = true,
  trackBinding = "CTRL-RightButton",
  preferTomTom = false,
}

-- Supported tracking clicks and how the tooltip hint names them.
Config.bindings = { ["CTRL-RightButton"] = "Ctrl + Right-Click", ["ALT-LeftButton"] = "Alt + Left-Click" }

function Config.BindingLabel(binding)
  return Config.bindings[binding]
end

local BOOLEAN_WORDS = { on = true, ["true"] = true, off = false, ["false"] = false }

ns.config = Config.defaults

ns.On("ADDON_LOADED", function(loaded)
  if loaded ~= addonName then return end
  WeaponWiseDB = WeaponWiseDB or {}
  for key, value in pairs(Config.defaults) do
    if WeaponWiseDB[key] == nil then WeaponWiseDB[key] = value end
  end
  ns.config = WeaponWiseDB
end)

function Config.Set(key, value)
  local default = Config.defaults[key]
  if default == nil then
    ns.Print("unknown setting: " .. tostring(key))
    return
  end
  if type(default) == "boolean" then
    local parsed = BOOLEAN_WORDS[value]
    if parsed == nil then
      ns.Print(key .. " takes on or off")
      return
    end
    ns.config[key] = parsed
  elseif key == "trackBinding" then
    if not Config.bindings[value] then
      ns.Print("trackBinding takes CTRL-RightButton or ALT-LeftButton")
      return
    end
    ns.config[key] = value
  end
  ns.Print(key .. " = " .. tostring(ns.config[key]))
end

function Config.Show()
  local keys = {}
  for key in pairs(Config.defaults) do keys[#keys + 1] = key end
  table.sort(keys)
  for _, key in ipairs(keys) do ns.Print(("  %s = %s"):format(key, tostring(ns.config[key]))) end
end

ns.RegisterCommand("set", function(rest)
  local key, value = rest:match("^(%S+)%s+(%S+)$")
  Config.Set(key, value)
end, "<setting> <value> - change a setting")

ns.RegisterCommand("config", Config.Show, "list settings")
