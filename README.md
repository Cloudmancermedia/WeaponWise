# WeaponWise

A World of Warcraft: Forever addon that answers one question when you hover a
weapon: can I use this, and if not, where do I learn it?

```
Can be trained by Hanashi (Orgrimmar)
Valley of Honor (81.5, 19.6) · Cost: 10s
New in Forever

Hold Shift for other trainers
Ctrl + Right-Click to track trainer
```

## Features

- **Your skill.** Weapons you know show your current skill, for example
  "You know this weapon skill (50/60)".
- **Where to train.** Weapons your class can learn show the weapon master,
  their city and district, map coordinates, the cost, and any level
  requirement. The first trainer listed is the one nearest to you.
- **Other trainers.** Hold Shift to list every other trainer for that weapon.
  The tooltip updates as you press the key.
- **Map pins.** Ctrl + Right-Click a weapon in your bags, on your character or
  at a merchant to pin its trainer on the map. TomTom is used if you prefer it.
- **Forever changes.** Weapons Forever added to a class are tagged
  "New in Forever": two-handed axes and maces for Shamans, one-handed axes for
  Rogues, and polearms for Druids.
- **Weapons you can't use** say so in red.

## Install

Download the latest release from CurseForge, or a release zip from GitHub, and
extract the `WeaponWise` folder into
`World of Warcraft/_classic_beta_/Interface/AddOns/`.

WeaponWise runs on the WoW Forever client (interface 16001). It has no
required dependencies; TomTom is optional.

## Settings

Type `/ww config` to see your settings and `/ww set <setting> <value>` to change
one, for example `/ww set showCost off`.

| Setting | Default | What it does |
|---|---|---|
| `enabled` | on | Turns the addon on or off. |
| `showKnown` | on | Shows your skill on weapons you know. |
| `showTrainable` | on | Shows the trainer on weapons you can learn. |
| `showUnavailable` | on | Shows the red line on weapons your class can't use. |
| `showCost` | on | Shows the training cost. |
| `showCoordinates` | on | Shows the trainer's map coordinates. |
| `recommendNearest` | on | Lists the nearest trainer first. Off uses a fixed order. |
| `showAlternatives` | on | Lists other trainers while Shift is held. |
| `showHint` | on | Shows the Shift and tracking hints. |
| `trackBinding` | `CTRL-RightButton` | The click that pins a trainer. Also accepts `ALT-LeftButton`. |
| `preferTomTom` | off | Uses TomTom for pins instead of the built-in map pin. |

## Known limitations

- Clicking a weapon in the auction house or a chat link can't pin its trainer,
  because the game doesn't pass those clicks to addons. The tracking hint is
  hidden there.
- "Nearest" means straight-line distance on your continent, not travel time.
- Text is English only. Skills are matched by ID, which doesn't depend on the
  client language, but only the English client has been tested.

## Development

Code layout:

```
Core.lua                 namespace, slash commands, events
Config.lua               settings
Data/                    weapon types, class weapon lists, cities, trainers
Services/                skill checks, trainer ranking, location, map pins
UI/                      tooltip lines and click handling
Dev/                     diagnostic commands, left out of release builds
tools/                   release builder and trainer-capture importer
spec/                    tests
```

The services hold the logic and touch no game frames, so the tests call them
directly against a small stand-in for the WoW API in `spec/helpers/wow_env.lua`.

Tests use [busted](https://lunarmodules.github.io/busted/) and linting uses
[luacheck](https://github.com/lunarmodules/luacheck). Setup on macOS:

```sh
brew install lua@5.4 luarocks
luarocks --lua-version=5.4 --lua-dir="$(brew --prefix lua@5.4)" install --local busted
luarocks --lua-version=5.4 --lua-dir="$(brew --prefix lua@5.4)" install --local luacheck
```

Use Lua 5.4; luacheck 1.2.0 doesn't load under Lua 5.5.

```sh
make check                                     # lint and tests
make link ADDONS="/path/to/Interface/AddOns"   # symlink this checkout into the game
make release VERSION=0.1.0                     # build dist/WeaponWise-0.1.0.zip
```

A checkout is a dev build: it loads the `Dev/` commands (`/ww probe`,
`/ww capture`, `/ww clicktest`, `/ww pin`). `make release` builds the zip
without them.

## License

MIT. See [LICENSE](LICENSE).
