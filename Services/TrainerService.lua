-- Finds and ranks the weapon masters that teach a weapon skill (spec 4).
local _, ns = ...

local TrainerService = {}
ns.TrainerService = TrainerService

local function teaches(trainer, weaponKey)
  for _, key in ipairs(trainer.teaches) do
    if key == weaponKey then return true end
  end
  return false
end

function TrainerService.ForWeapon(weaponKey, faction)
  local list = {}
  for _, t in ipairs(ns.WeaponTrainers) do
    if t.faction == faction and teaches(t, weaponKey) then list[#list + 1] = t end
  end
  return list
end

-- Ranking: trainer in the player's city, then the player's continent (nearest
-- first when world positions exist), then everyone else. Ties go to verified
-- records, then data order, so the result never depends on table iteration.
-- Straight-line distance is not travel time; spec 4.2 forbids claiming it is.
function TrainerService.Recommend(weaponKey, faction, player, worldOf)
  local ranked = {}
  for index, t in ipairs(TrainerService.ForWeapon(weaponKey, faction)) do
    local city = ns.Cities[t.city]
    local tier, dist = 3, math.huge
    if t.city == player.zone then
      tier = 1
    elseif city and player.continent and city.continent == player.continent then
      tier = 2
      local tw = worldOf and player.world and worldOf(t)
      if tw then
        local dx, dy = tw.x - player.world.x, tw.y - player.world.y
        dist = math.sqrt(dx * dx + dy * dy)
      end
    end
    ranked[#ranked + 1] = { trainer = t, tier = tier, dist = dist, verified = t.verified and 0 or 1, index = index }
  end
  table.sort(ranked, function(a, b)
    if a.tier ~= b.tier then return a.tier < b.tier end
    if a.dist ~= b.dist then return a.dist < b.dist end
    if a.verified ~= b.verified then return a.verified < b.verified end
    return a.index < b.index
  end)
  local alternatives = {}
  for i = 2, #ranked do alternatives[#alternatives + 1] = ranked[i].trainer end
  return ranked[1] and ranked[1].trainer, alternatives
end
