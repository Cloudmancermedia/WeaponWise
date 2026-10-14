-- Weapon types each class can learn, as sets of WeaponTypes keys.
-- ClassicWeapons is the Classic Era baseline, written from memory: UNVERIFIED.
-- ForeverAdditions holds what Forever adds on top; tooltips tag those as new.
local _, ns = ...

local function set(list)
  local s = {}
  for _, key in ipairs(list) do s[key] = true end
  return s
end

ns.ClassicWeapons = {
  WARRIOR = set({ "AXE_1H", "AXE_2H", "BOW", "GUN", "MACE_1H", "MACE_2H", "POLEARM", "SWORD_1H", "SWORD_2H",
    "STAFF", "FIST", "DAGGER", "THROWN", "CROSSBOW" }),
  PALADIN = set({ "AXE_1H", "AXE_2H", "MACE_1H", "MACE_2H", "POLEARM", "SWORD_1H", "SWORD_2H" }),
  HUNTER = set({ "AXE_1H", "AXE_2H", "BOW", "GUN", "POLEARM", "SWORD_1H", "SWORD_2H", "STAFF", "FIST", "DAGGER",
    "THROWN", "CROSSBOW" }),
  ROGUE = set({ "BOW", "GUN", "MACE_1H", "SWORD_1H", "FIST", "DAGGER", "THROWN", "CROSSBOW" }),
  PRIEST = set({ "MACE_1H", "STAFF", "DAGGER", "WAND" }),
  -- Two-handed axes and maces needed an Enhancement talent in Classic Era.
  SHAMAN = set({ "AXE_1H", "MACE_1H", "STAFF", "FIST", "DAGGER" }),
  MAGE = set({ "SWORD_1H", "STAFF", "DAGGER", "WAND" }),
  WARLOCK = set({ "SWORD_1H", "STAFF", "DAGGER", "WAND" }),
  DRUID = set({ "MACE_1H", "MACE_2H", "STAFF", "FIST", "DAGGER" }),
}

-- Source: the project owner (2026-10-13), who knows of no other Forever weapon
-- changes. Shaman 2H axes and maces no longer need the Enhancement talent;
-- Druids can train polearms with no talent.
ns.ForeverAdditions = {
  SHAMAN = set({ "AXE_2H", "MACE_2H" }),
  ROGUE = set({ "AXE_1H" }),
  DRUID = set({ "POLEARM" }),
}

ns.ClassWeapons = {}
for class, weapons in pairs(ns.ClassicWeapons) do
  local merged = {}
  for key in pairs(weapons) do merged[key] = true end
  for key in pairs(ns.ForeverAdditions[class] or {}) do merged[key] = true end
  ns.ClassWeapons[class] = merged
end
