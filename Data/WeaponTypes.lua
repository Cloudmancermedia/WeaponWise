-- Weapon types WeaponWise tracks, keyed by a stable internal name.
-- subclassID: item subclass under the Weapon item class (GetItemInfoInstant).
-- skillID: the skill line ID in the character's skill list. Same in every
-- locale, so it is matched first. Confirmed on Forever by probes on
-- 2026-10-13: Axes 44, Swords 43, Daggers 173, Thrown 176 (Rogue); Maces 54,
-- Staves 136, Two-Handed Maces 160 (Shaman). The rest are Classic Era IDs,
-- UNVERIFIED on Forever.
-- skillName: the enUS skill line name, the fallback when an ID misses.
-- label: the name shown to players in tooltips and waypoints.
local _, ns = ...

ns.WeaponTypes = {
  AXE_1H = { subclassID = 0, skillID = 44, skillName = "Axes", label = "One-Handed Axes" },
  AXE_2H = { subclassID = 1, skillID = 172, skillName = "Two-Handed Axes", label = "Two-Handed Axes" },
  BOW = { subclassID = 2, skillID = 45, skillName = "Bows", label = "Bows" },
  GUN = { subclassID = 3, skillID = 46, skillName = "Guns", label = "Guns" },
  MACE_1H = { subclassID = 4, skillID = 54, skillName = "Maces", label = "One-Handed Maces" },
  MACE_2H = { subclassID = 5, skillID = 160, skillName = "Two-Handed Maces", label = "Two-Handed Maces" },
  POLEARM = { subclassID = 6, skillID = 229, skillName = "Polearms", label = "Polearms" },
  SWORD_1H = { subclassID = 7, skillID = 43, skillName = "Swords", label = "One-Handed Swords" },
  SWORD_2H = { subclassID = 8, skillID = 55, skillName = "Two-Handed Swords", label = "Two-Handed Swords" },
  STAFF = { subclassID = 10, skillID = 136, skillName = "Staves", label = "Staves" },
  FIST = { subclassID = 13, skillID = 473, skillName = "Fist Weapons", label = "Fist Weapons" },
  DAGGER = { subclassID = 15, skillID = 173, skillName = "Daggers", label = "Daggers" },
  THROWN = { subclassID = 16, skillID = 176, skillName = "Thrown", label = "Thrown" },
  CROSSBOW = { subclassID = 18, skillID = 226, skillName = "Crossbows", label = "Crossbows" },
  WAND = { subclassID = 19, skillID = 228, skillName = "Wands", label = "Wands" },
}

ns.WeaponTypeBySubclass = {}
for key, wt in pairs(ns.WeaponTypes) do
  ns.WeaponTypeBySubclass[wt.subclassID] = key
end
