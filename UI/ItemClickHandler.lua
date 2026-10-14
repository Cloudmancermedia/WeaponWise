-- Modifier-click on a weapon tracks its trainer. The hook runs after
-- Blizzard's click code and never touches the item, so this addon cannot
-- equip, use, or sell anything. On Forever neither Ctrl+Right-Click nor
-- Alt+Left-Click does anything else to a weapon (owner-tested 2026-10-13).
local _, ns = ...

local ItemClickHandler = {}
ns.ItemClickHandler = ItemClickHandler

function ItemClickHandler.BindingLabel(binding)
  return ns.Config.BindingLabel(binding)
end

-- Binding format: "<MOD>-<Button>", e.g. "CTRL-RightButton". Modifiers must
-- match exactly so Ctrl+Shift+Right-Click never counts as Ctrl+Right-Click.
function ItemClickHandler.Matches(binding, button, mods)
  local mod, want = binding:match("^(%u+)%-(%a+)$")
  if want ~= button then return false end
  return (mods.ctrl or false) == (mod == "CTRL")
    and (mods.alt or false) == (mod == "ALT")
    and (mods.shift or false) == (mod == "SHIFT")
end

function ItemClickHandler.HandleClick(link, button, mods)
  if not ns.config.enabled then return false end
  if not ItemClickHandler.Matches(ns.config.trackBinding, button, mods) then return false end
  local info = ns.Lookup.ForLink(link)
  if not info then return false end
  if not info.recommended then
    ns.Print("no trainer to track for this weapon")
    return false
  end
  ns.NavigationService.Track(info.recommended, info.result.weapon)
  return true
end

function ItemClickHandler.BagLink(bag, slot)
  if C_Container and C_Container.GetContainerItemLink then
    return C_Container.GetContainerItemLink(bag, slot)
  end
  return GetContainerItemLink and GetContainerItemLink(bag, slot)
end

local function currentMods()
  return { ctrl = IsControlKeyDown(), alt = IsAltKeyDown(), shift = IsShiftKeyDown() }
end

-- Bags and weapon slots both route modified clicks through
-- HandleModifiedItemClick on Forever (verified with /ww clicktest), so one
-- post-hook covers every frame and needs no frame names.
function ItemClickHandler.Install()
  if not HandleModifiedItemClick then return false end
  hooksecurefunc("HandleModifiedItemClick", function(link)
    local button = GetMouseButtonClicked and GetMouseButtonClicked()
    ItemClickHandler.HandleClick(link, button, currentMods())
  end)
  return true
end

ns.On("PLAYER_LOGIN", ItemClickHandler.Install)
