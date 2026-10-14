-- One entry point from an item link to everything the UI shows: skill state
-- plus, when training is needed, the recommended and alternative trainers.
local _, ns = ...

local Lookup = {}
ns.Lookup = Lookup

local WEAPON_CLASS = 2 -- Enum.ItemClass.Weapon
-- false means "read, but the client has no skill API", so we read only once.
local skillCache

ns.On("SKILL_LINES_CHANGED", function() skillCache = nil end)

local function itemInfo(link)
  if C_Item and C_Item.GetItemInfoInstant then return C_Item.GetItemInfoInstant(link) end
  return GetItemInfoInstant(link)
end

function Lookup.ForLink(link)
  if not link then return nil end
  local _, _, _, _, _, classID, subclassID = itemInfo(link)
  if classID ~= WEAPON_CLASS then return nil end

  if skillCache == nil then skillCache = ns.WeaponSkillService.ReadSkills() or false end
  local _, class = UnitClass("player")
  local result = ns.WeaponSkillService.Evaluate(subclassID, class, skillCache or nil)
  if not result then return nil end

  local info = { result = result }
  if result.state == "TRAINABLE" then
    -- With recommendNearest off, an empty position gives the fixed data order.
    local player = ns.config.recommendNearest and ns.Location.Player() or {}
    info.recommended, info.alternatives = ns.TrainerService.Recommend(
      result.weapon, UnitFactionGroup("player"), player, ns.Location.TrainerWorld)
  end
  return info
end
