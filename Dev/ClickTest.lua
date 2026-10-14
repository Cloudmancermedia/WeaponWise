-- Phase 0 diagnostic for spec 3.2: logs which hooks fire on modified clicks
-- over bag and equipment slots. It observes only and never acts on the item.
local _, ns = ...
ns.devTools = true

local ClickTest = {}
ns.ClickTest = ClickTest

local MAX_LOG = 50
local enabled = false
local hooked = false

local EQUIP_SLOTS = { "CharacterMainHandSlot", "CharacterSecondaryHandSlot", "CharacterRangedSlot" }

local function modifiers()
  local mods = {}
  if IsControlKeyDown() then mods[#mods + 1] = "ctrl" end
  if IsAltKeyDown() then mods[#mods + 1] = "alt" end
  if IsShiftKeyDown() then mods[#mods + 1] = "shift" end
  return table.concat(mods, "+")
end

function ClickTest.SetEnabled(value)
  enabled = value
end

function ClickTest.Record(source, button, item)
  if not enabled or not ns.devDB then return end
  local log = ns.devDB.clickLog or {}
  if not button and GetMouseButtonClicked then button = GetMouseButtonClicked() end
  local entry = { source = source, button = button, mods = modifiers(), item = item }
  log[#log + 1] = entry
  while #log > MAX_LOG do table.remove(log, 1) end
  ns.devDB.clickLog = log
  ns.Print(("click: %s %s [%s] %s"):format(source, tostring(button), entry.mods, tostring(item)))
end

local function bagLink(bag, slot)
  return ns.ItemClickHandler.BagLink(bag, slot)
end

local function installHooks()
  local frames = NUM_CONTAINER_FRAMES or 13
  local slots = MAX_CONTAINER_ITEMS or 36
  for f = 1, frames do
    for s = 1, slots do
      local btn = _G[("ContainerFrame%dItem%d"):format(f, s)]
      if btn then
        btn:HookScript("PreClick", function(self, button)
          ClickTest.Record("bag PreClick", button, bagLink(self:GetParent():GetID(), self:GetID()))
        end)
        btn:HookScript("OnClick", function(self, button)
          ClickTest.Record("bag OnClick", button, bagLink(self:GetParent():GetID(), self:GetID()))
        end)
      end
    end
  end
  for _, name in ipairs(EQUIP_SLOTS) do
    local btn = _G[name]
    if btn then
      btn:HookScript("OnClick", function(self, button)
        ClickTest.Record("equip OnClick", button, GetInventoryItemLink("player", self:GetID()))
      end)
    end
  end
  for _, fn in ipairs({ "HandleModifiedItemClick", "ContainerFrameItemButton_OnModifiedClick",
    "PaperDollItemSlotButton_OnModifiedClick" }) do
    if _G[fn] then
      hooksecurefunc(fn, function(arg1, arg2)
        local item = type(arg1) == "string" and arg1 or nil
        ClickTest.Record(fn, type(arg2) == "string" and arg2 or nil, item)
      end)
    end
  end
  hooked = true
end

ns.RegisterCommand("clicktest", function()
  if not hooked then installHooks() end
  enabled = not enabled
  ns.Print("click test " .. (enabled and "ON - use a soulbound or junk weapon" or "off"))
end, "toggle logging of modified clicks on weapons")
