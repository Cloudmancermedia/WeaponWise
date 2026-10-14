# WeaponWise

A World of Warcraft: Forever addon. Weapon tooltips show your current skill
with the weapon type, or which trainer teaches it, where they stand, and what
it costs. Weapons your class gained in Forever, such as two-handed axes and
maces for Shamans or polearms for Druids, are tagged "New in Forever". The full spec lives in
Obsidian at `Personal/_Projects/WeaponWise/Spec.md`.

Status: 0.1.0-dev. All features are coded and unit tested, and the owner has
checked the tooltip lines and map pins in the Forever client. See `todo.md`.

## How it works

```
Core.lua                 namespace, slash commands, event dispatch
Config.lua               settings (WeaponWiseDB), /ww set and /ww config
Data/                    weapon types, class rules, cities, trainers
Services/
  WeaponSkillService     KNOWN / TRAINABLE / UNAVAILABLE for a weapon subclass
  TrainerService         trainers for a weapon, ranked by city, continent, distance
  Location               player and trainer positions from the map APIs
  NavigationService      native waypoint, TomTom, or coordinates in chat
  Lookup                 item link -> skill state + recommended trainer
UI/
  Tooltip                renders Lookup results; hooks item tooltips
  ItemClickHandler       modifier-click on a weapon in bags, equipment or a merchant tracks the trainer
                         (auction house rows and chat links never reach it, so the hint is hidden there)
Dev/                     probe, capture, and click-test tools (left out of release builds)
tools/                   host-side capture importer and release builder
```

The services hold the logic and have no frame code, so the tests exercise them
directly. The UI files only gather inputs and add lines.

Class rules come in two layers. `ClassicWeapons` is the Classic Era baseline and
`ForeverAdditions` lists what Forever adds; the additions drive the
"New in Forever" tag.

Whether you know a weapon skill comes from your character's skill list, matched
by skill ID so every client language works (the enUS name is the fallback), so
racial or starting skills need no data. The class tables only answer the
other question: for a skill you lack, can your class train it at all?

Trainer records come from wiki lists the owner confirmed for Forever, priced at
10s per weapon (polearms 1g, level 20). A record with `verified = false` gets an
"unverified" tag in the tooltip, and the release gate in `spec/toc_spec.lua`
fails any non-dev version that ships one, or ships dev tools.

## Development

Tests run outside the game with [busted](https://lunarmodules.github.io/busted/)
against a small stand-in for the WoW API (`spec/helpers/wow_env.lua`).
Linting uses [luacheck](https://github.com/lunarmodules/luacheck) with
`std = "lua51"`, the Lua version the game client runs.

One-time setup on macOS:

```sh
brew install lua@5.4 luarocks
luarocks --lua-version=5.4 --lua-dir="$(brew --prefix lua@5.4)" install --local busted
luarocks --lua-version=5.4 --lua-dir="$(brew --prefix lua@5.4)" install --local luacheck
```

Use Lua 5.4. luacheck 1.2.0 fails to load under Lua 5.5.

```sh
make check                                     # lint + tests
make link ADDONS="/path/to/Interface/AddOns"   # symlink into the game
make import SV="/path/to/SavedVariables/WeaponWise.lua"   # merge trainer captures
make release VERSION=0.1.0                     # dist/WeaponWise-0.1.0.zip
```

The checkout always stays a dev build. `make release` runs the checks, then
copies the files the TOC lists into `dist/WeaponWise/`. It leaves out `Dev\`
files and `WeaponWiseDevDB`, sets the version, and zips the result. It refuses
to build if any trainer record is unverified.

## In-game commands

| Command | What it does |
|---|---|
| `/ww config` | Lists settings. |
| `/ww set <setting> <value>` | Changes a setting, e.g. `/ww set trackBinding ALT-LeftButton`. |
| `/ww probe` | Dev: lists which client APIs exist and your weapon skills. |
| `/ww capture on` | Dev: records every trainer window you open. |
| `/ww clicktest` | Dev: logs which hooks fire when you modifier-click a weapon. Observes only. |
| `/ww pin <trainer>` | Dev: sets a trainer's map pin without a weapon, e.g. `/ww pin arch`. No name lists trainers. |

Saved data is written to `WTF/Account/<ACCOUNT>/SavedVariables/WeaponWise.lua`
on `/reload` or logout. `make import` reads captures from that file, rewrites
`Data/WeaponTrainers.lua`, and lists any weapon a faction still has no trainer
for. A capture only shows the visiting class's weapons, so a gap usually means
another class needs to visit that trainer.

## License

MIT. See `LICENSE`. Release zips include it.
