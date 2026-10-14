-- Decides, for a weapon subclass, whether the player knows the skill, can
-- train it, or can never use it. No UI code; the tooltip only renders results.
local _, ns = ...

local WeaponSkillService = {}
ns.WeaponSkillService = WeaponSkillService

local function isNewInForever(classToken, key)
  local additions = ns.ForeverAdditions[classToken]
  return additions and additions[key] or nil
end

-- Returns { state = "KNOWN"|"TRAINABLE"|"UNAVAILABLE", weapon, rank?, max?,
-- newInForever? }, or nil when the subclass or class is not something we can
-- judge. skills is nil when the client cannot report them.
function WeaponSkillService.Evaluate(subclassID, classToken, skills)
  local key = subclassID and ns.WeaponTypeBySubclass[subclassID]
  if not key then return nil end

  -- The skill list is ground truth; check it before class rules so a gap in
  -- our class data can never hide a skill the player has.
  local wt = ns.WeaponTypes[key]
  local known = skills and (skills[wt.skillID] or skills[wt.skillName])
  if known then
    return { state = "KNOWN", weapon = key, rank = known.rank, max = known.max,
      newInForever = isNewInForever(classToken, key) }
  end

  local rules = ns.ClassWeapons[classToken]
  if not rules then return nil end
  -- Without a skill list we cannot tell KNOWN from TRAINABLE; say nothing.
  if rules[key] and not skills then return nil end
  if rules[key] then
    return { state = "TRAINABLE", weapon = key, newInForever = isNewInForever(classToken, key) }
  end
  return { state = "UNAVAILABLE", weapon = key }
end

-- Forever 1.60.1 moved the skill-line API into C_SkillInfo; older clients
-- have the globals.
local function skillApi()
  if C_SkillInfo and C_SkillInfo.GetNumSkillLines and C_SkillInfo.GetSkillLineInfo then
    return C_SkillInfo.GetNumSkillLines, C_SkillInfo.GetSkillLineInfo
  end
  if GetNumSkillLines and GetSkillLineInfo then return GetNumSkillLines, GetSkillLineInfo end
end

-- Forever returns one table per row (fields confirmed from a real probe
-- dump); older clients return separate values.
local function readRow(info, i)
  local first, isHeader, _, rank, _, _, max = info(i)
  if type(first) == "table" then
    return first.name, first.isHeader, first.rank, first.maxRank, tonumber(first.skillID)
  end
  if type(first) == "string" then return first, isHeader, rank, max end
end

-- Returns { [name] = { rank, max } }, with each entry also under its skill
-- ID when the client gives one. nil when skills cannot be read: no API, or an
-- unrecognised row shape.
function WeaponSkillService.ReadSkills()
  local count, info = skillApi()
  if not count then return nil end
  local skills = {}
  for i = 1, count() do
    local name, isHeader, rank, max, id = readRow(info, i)
    if type(name) ~= "string" then return nil end
    if not isHeader then
      local entry = { rank = rank, max = max }
      skills[name] = entry
      if id and id > 0 then skills[id] = entry end
    end
  end
  return skills
end
