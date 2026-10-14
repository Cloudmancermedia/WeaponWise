-- Phase 0 diagnostic: reports which client APIs exist so the design can be
-- settled against the real Forever client instead of assumptions.
local _, ns = ...
ns.devTools = true

local Probe = {}
ns.Probe = Probe

-- Each entry answers a design question in the spec.
local APIS = {
  -- Location and native waypoints (spec 3.3, 4.2)
  "C_Map.GetBestMapForUnit",
  "C_Map.GetPlayerMapPosition",
  "C_Map.GetMapInfo",
  "C_Map.CanSetUserWaypointOnMap",
  "C_Map.SetUserWaypoint",
  "C_SuperTrack.SetSuperTrackedUserWaypoint",
  "UiMapPoint.CreateFromCoordinates",
  -- Tooltip hooking (spec 2)
  "TooltipDataProcessor.AddTooltipPostCall",
  "GameTooltip.RefreshData",
  -- Item identification (FR-001)
  "GetItemInfoInstant",
  "C_Item.GetItemInfoInstant",
  "C_Container.GetContainerItemLink",
  "GetContainerItemLink",
  -- Skill reading (FR-003)
  "GetNumSkillLines",
  "GetSkillLineInfo",
  "C_SkillInfo.GetNumSkillLines",
  "C_SkillInfo.GetSkillLineInfo",
  -- Coin icons in the cost line
  "C_CurrencyInfo.GetCoinTextureString",
  "GetMoneyString",
  "GetCoinTextureString",
  -- Modifier-click hooks (spec 3.2)
  "HandleModifiedItemClick",
  "ContainerFrameItemButton_OnModifiedClick",
  "PaperDollItemSlotButton_OnModifiedClick",
  -- Trainer capture
  "GetTrainerServiceLevelReq",
  "GetTrainerServiceSkillLine",
  "SetTrainerServiceTypeFilter",
  -- Optional navigation provider
  "TomTom",
}

function Probe.Resolve(path)
  local node = _G
  for key in path:gmatch("[^%.]+") do
    if type(node) ~= "table" then return nil end
    node = node[key]
  end
  return node
end

local function collectSkills()
  local skills = {}
  if not GetNumSkillLines then return skills end
  local header
  for i = 1, GetNumSkillLines() do
    local name, isHeader, _, rank, _, _, max = GetSkillLineInfo(i)
    if isHeader then
      header = name
    else
      skills[#skills + 1] = { header = header, name = name, rank = rank, max = max }
    end
  end
  return skills
end

-- Name fragments that point at a way to read weapon skills. Forever lacks
-- GetSkillLineInfo, so this lists every candidate the client does have.
local SKILL_PATTERNS = { "skill", "proficien", "isplayerspell", "isspellknown" }

local function matchesSkill(name)
  local lower = name:lower()
  for _, pattern in ipairs(SKILL_PATTERNS) do
    if lower:find(pattern, 1, true) then return true end
  end
  return false
end

local function collectSkillApis()
  local found = {}
  for name, value in pairs(_G) do
    if type(name) == "string" then
      if type(value) == "function" and matchesSkill(name) then
        found[#found + 1] = name
      elseif type(value) == "table" and name:match("^C_") then
        for member, fn in pairs(value) do
          if type(member) == "string" and type(fn) == "function" and (matchesSkill(member) or matchesSkill(name)) then
            found[#found + 1] = name .. "." .. member
          end
        end
      end
    end
  end
  table.sort(found)
  return found
end

-- Raw C_SkillInfo rows, so the return shape can be mapped from real data.
local MAX_DUMP_ROWS = 60

local function packRow(...)
  local first = ...
  if type(first) == "table" then
    local copy = {}
    for k, v in pairs(first) do copy[tostring(k)] = tostring(v) end
    return { table = copy }
  end
  local row = {}
  for i = 1, select("#", ...) do row[i] = tostring((select(i, ...))) end
  return row
end

local function dumpSkillLines()
  if not (C_SkillInfo and C_SkillInfo.GetNumSkillLines and C_SkillInfo.GetSkillLineInfo) then return nil end
  local rows = {}
  for i = 1, math.min(C_SkillInfo.GetNumSkillLines(), MAX_DUMP_ROWS) do
    rows[i] = packRow(C_SkillInfo.GetSkillLineInfo(i))
  end
  return rows
end

function Probe.Collect()
  local report = { apis = {}, apiOrder = APIS }
  local version, build, date, interface = GetBuildInfo()
  report.build = { version = version, build = build, date = date, interface = interface }
  for _, path in ipairs(APIS) do
    report.apis[path] = Probe.Resolve(path) ~= nil
  end
  report.tooltipSetItemScript = GameTooltip ~= nil and GameTooltip:HasScript("OnTooltipSetItem") or false
  local _, class = UnitClass("player")
  report.player = { class = class, faction = UnitFactionGroup("player") }
  report.skills = collectSkills()
  report.skillApis = collectSkillApis()
  report.skillLineDump = dumpSkillLines()
  return report
end

function Probe.Run()
  local report = Probe.Collect()
  if ns.devDB then ns.devDB.probe = report end
  local b = report.build
  ns.Print(("build %s (%s), interface %s"):format(tostring(b.version), tostring(b.build), tostring(b.interface)))
  for _, path in ipairs(APIS) do
    ns.Print(("  %s %s"):format(report.apis[path] and "yes" or "NO ", path))
  end
  ns.Print("  OnTooltipSetItem script: " .. tostring(report.tooltipSetItemScript))
  for _, s in ipairs(report.skills) do
    if s.header and s.header:find("Weapon") then
      ns.Print(("  skill %s %s/%s"):format(s.name, tostring(s.rank), tostring(s.max)))
    end
  end
  ns.Print(("  %d skill-related functions found"):format(#report.skillApis))
  ns.Print("saved to WeaponWiseDevDB.probe (written on /reload or logout)")
end

ns.RegisterCommand("probe", Probe.Run, "report client APIs and weapon skills")
