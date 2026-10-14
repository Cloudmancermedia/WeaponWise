-- Renders Lookup results into item tooltips (spec 2). BuildLines is pure;
-- the hook functions below only fetch inputs and add the lines.
local _, ns = ...

local Tooltip = {}
ns.Tooltip = Tooltip

local GREEN = { 0.1, 1, 0.1 }
local RED = { 1, 0.13, 0.13 }
local ORANGE = { 1, 0.5, 0.25 }
local YELLOW = { 1, 0.82, 0 }
local GRAY = { 0.6, 0.6, 0.6 }
local HINT_GRAY = { 0.5, 0.5, 0.5 }
local FOREVER_BLUE = { 0.4, 0.8, 1 }
local WHITE = { 1, 1, 1 }
local WHITE_CODE = "|cffffffff"

local function coin(name)
  return ("|TInterface\\MoneyFrame\\UI-%sIcon:0:0:2:0|t"):format(name)
end

-- Money with coin icons. Uses the client's formatter when it has one (the
-- global GetCoinTextureString is missing on Forever 1.60.1), else draws the
-- client's own coin textures.
function Tooltip.FormatMoney(copper)
  if C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString then
    return C_CurrencyInfo.GetCoinTextureString(copper)
  end
  if GetMoneyString then return GetMoneyString(copper) end
  if GetCoinTextureString then return GetCoinTextureString(copper) end
  local g, s, c = math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100
  local parts = {}
  if g > 0 then parts[#parts + 1] = g .. coin("Gold") end
  if s > 0 then parts[#parts + 1] = s .. coin("Silver") end
  if c > 0 or #parts == 0 then parts[#parts + 1] = c .. coin("Copper") end
  return table.concat(parts, " ")
end

local function coords(t)
  if ns.config.showCoordinates and t.x and t.y then return ("(%.1f, %.1f)"):format(t.x, t.y) end
end

local function locationLine(t, svc)
  local place = {}
  place[#place + 1] = t.district
  place[#place + 1] = coords(t)
  local segments = {}
  if #place > 0 then segments[#segments + 1] = table.concat(place, " ") end
  if ns.config.showCost and svc.cost then segments[#segments + 1] = "Cost: " .. Tooltip.FormatMoney(svc.cost) end
  if not t.verified then segments[#segments + 1] = "unverified" end
  if #segments > 0 then return table.concat(segments, " · ") end
end

-- A trainer's name line, then a gray location line, then a level warning.
-- The recommended trainer and Shift alternatives share this, so they match.
local function trainerLines(lines, ctx, t)
  -- Cost and level are per weapon; records without services have neither.
  local svc = t.services and t.services[ctx.result.weapon] or {}
  lines[#lines + 1] = { text = ("Can be trained by %s%s|r (%s)"):format(WHITE_CODE, t.name, t.city), color = YELLOW }
  local loc = locationLine(t, svc)
  if loc then lines[#lines + 1] = { text = loc, color = WHITE } end
  if svc.levelReq and ctx.playerLevel and ctx.playerLevel < svc.levelReq then
    lines[#lines + 1] = { text = ("Requires Level %d to train"):format(svc.levelReq), color = ORANGE }
  end
end

local function hasAlternatives(ctx)
  return ns.config.showAlternatives and ctx.alternatives ~= nil and #ctx.alternatives > 0
end

local function alternativeLines(lines, ctx)
  if not (ctx.shiftDown and hasAlternatives(ctx)) then return end
  lines[#lines + 1] = { text = " ", color = GRAY }
  lines[#lines + 1] = { text = "Other Trainers:", color = YELLOW }
  for _, t in ipairs(ctx.alternatives) do trainerLines(lines, ctx, t) end
end

local function hintLines(lines, ctx)
  if not ns.config.showHint then return end
  local hints = {}
  if not ctx.shiftDown and hasAlternatives(ctx) then hints[#hints + 1] = "Hold Shift for other trainers" end
  if ctx.canTrack then hints[#hints + 1] = ns.Config.BindingLabel(ns.config.trackBinding) .. " to track trainer" end
  if #hints == 0 then return end
  lines[#lines + 1] = { text = " ", color = GRAY }
  for _, h in ipairs(hints) do lines[#lines + 1] = { text = h, color = HINT_GRAY } end
end

-- ctx: { result, recommended?, alternatives?, playerLevel?, shiftDown?, canTrack? }
function Tooltip.BuildLines(ctx)
  local lines = {}
  local cfg, result = ns.config, ctx.result
  if not cfg.enabled then return lines end

  if result.state == "KNOWN" then
    if not cfg.showKnown then return lines end
    lines[#lines + 1] = { text = ("You know this weapon skill (%d/%d)"):format(result.rank, result.max), color = GREEN }
  elseif result.state == "UNAVAILABLE" then
    if not cfg.showUnavailable then return lines end
    lines[#lines + 1] = { text = "Your class cannot use this weapon type", color = RED }
  else
    if not cfg.showTrainable then return lines end
    if ctx.recommended then
      trainerLines(lines, ctx, ctx.recommended)
    else
      lines[#lines + 1] = { text = "Your class can learn this weapon type", color = YELLOW }
    end
  end

  if result.newInForever then lines[#lines + 1] = { text = "New in Forever", color = FOREVER_BLUE } end

  if result.state == "TRAINABLE" and ctx.recommended then
    alternativeLines(lines, ctx)
    hintLines(lines, ctx)
  end
  return lines
end

-- The data post-call passes the item directly. Not every tooltip has
-- GetItem (ShoppingTooltip1 on Forever lacks it).
local function itemOf(tooltip, data)
  if data and (data.hyperlink or data.id) then return data.hyperlink or data.id end
  if tooltip.GetItem then
    local _, link = tooltip:GetItem()
    return link
  end
end

-- Auction house rows never call HandleModifiedItemClick on Forever (owner-tested
-- 2026-10-14), so a weapon there cannot be tracked by clicking it.
local function inAuctionHouse(tooltip)
  local ah = AuctionHouseFrame
  local frame = ah and tooltip.GetOwner and tooltip:GetOwner()
  for _ = 1, 20 do
    if not frame then return false end
    if frame == ah then return true end
    frame = frame.GetParent and frame:GetParent()
  end
  return false
end

local function decorate(tooltip, data)
  if not ns.config.enabled then return end
  local info = ns.Lookup.ForLink(itemOf(tooltip, data))
  if not info then return end
  local rec = info.recommended
  info.playerLevel = UnitLevel("player")
  info.shiftDown = IsShiftKeyDown()
  -- Tracking works wherever an item can be modifier-clicked except the auction
  -- house, so the hint needs a trainer with a known map position.
  info.canTrack = rec ~= nil and rec.x ~= nil and ns.Cities ~= nil and ns.Cities[rec.city] ~= nil
    and not inAuctionHouse(tooltip)
  local lines = Tooltip.BuildLines(info)
  if #lines == 0 then return end
  tooltip:AddLine(" ")
  for _, line in ipairs(lines) do
    tooltip:AddLine(line.text, line.color[1], line.color[2], line.color[3])
  end
  tooltip:Show()
end

-- Dev builds keep the last 20 refresh attempts, so a refresh that does
-- nothing in game shows where it stopped.
local function logRefresh(path)
  local db = ns.devDB
  if not db then return end
  db.refreshLog = db.refreshLog or {}
  table.insert(db.refreshLog, 1, { path = path, time = time and time() })
  db.refreshLog[21] = nil
end

-- Rebuild the shown tooltip so Shift changes appear while hovering.
-- Mainline tooltips rebuild from their stored data with RefreshData, which
-- re-runs our post-call; older clients re-run the owner's OnEnter.
function Tooltip.Refresh()
  if not (GameTooltip and GameTooltip:IsShown()) then return logRefresh("hidden") end
  -- Skip non-item tooltips when the client can tell us; otherwise refresh anyway.
  if GameTooltip.GetItem then
    local _, link = GameTooltip:GetItem()
    if not link then return logRefresh("not an item") end
  end
  if GameTooltip.RefreshData then
    GameTooltip:RefreshData()
    return logRefresh("RefreshData")
  end
  local owner = GameTooltip.GetOwner and GameTooltip:GetOwner()
  local onEnter = owner and owner.GetScript and owner:GetScript("OnEnter")
  if not onEnter then return logRefresh("no OnEnter") end
  onEnter(owner)
  logRefresh("OnEnter")
end

function Tooltip.Install()
  if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, decorate)
    return "TooltipDataProcessor"
  end
  for _, name in ipairs({ "GameTooltip", "ItemRefTooltip", "ShoppingTooltip1", "ShoppingTooltip2" }) do
    local tt = _G[name]
    if tt and tt:HasScript("OnTooltipSetItem") then tt:HookScript("OnTooltipSetItem", decorate) end
  end
  return "OnTooltipSetItem"
end

ns.On("PLAYER_LOGIN", Tooltip.Install)
ns.On("MODIFIER_STATE_CHANGED", function(key)
  if key == "LSHIFT" or key == "RSHIFT" then Tooltip.Refresh() end
end)
-- Lookup clears its skill cache on the same event; it registers first (TOC order).
ns.On("SKILL_LINES_CHANGED", function() Tooltip.Refresh() end)
