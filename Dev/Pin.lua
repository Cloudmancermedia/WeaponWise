-- Dev check for map pins: /ww pin <trainer> sets the same waypoint a
-- Ctrl + Right-Click would, for any trainer, without needing a weapon.
local _, ns = ...

local function find(query)
  local q = query:lower()
  for _, t in ipairs(ns.WeaponTrainers) do
    if t.name:lower():sub(1, #q) == q then return t end
  end
end

ns.RegisterCommand("pin", function(arg)
  if arg == "" then
    ns.Print("trainers (/ww pin <name>):")
    for _, t in ipairs(ns.WeaponTrainers) do
      ns.Print(("  %s - %s, %s"):format(t.name, t.city, t.faction))
    end
    return
  end
  local trainer = find(arg)
  if not trainer then return ns.Print("no trainer named " .. arg) end
  ns.NavigationService.Track(trainer, trainer.teaches[1])
end, "dev: pin a trainer on the map without a weapon")
