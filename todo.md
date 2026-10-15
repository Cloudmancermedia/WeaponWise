# WeaponWise todo

Open work. The full build history is in git.

## Before the 0.1.0 release

- [ ] Release build check in game: tooltips work, `/ww` lists only `config` and `set`, no errors
- [ ] Auction house: hovering a weapon shows trainer lines but no tracking hint
- [ ] Create the CurseForge project and upload the 0.1.0 zip (Forever game version)

## Not yet confirmed on Forever

- Skill IDs for Two-Handed Axes (172), Bows (45), Guns (46), Polearms (229),
  Two-Handed Swords (55), Fist Weapons (473), Crossbows (226) and Wands (228)
  are Classic Era values. An English client still matches by name if one is
  wrong. `/ww probe` on a character with the skill confirms it.
- TomTom support has unit tests only.

## Later

- Phase 5: damage preview
- Automate CurseForge uploads from GitHub releases
- Localization, travel-time routing, reputation-adjusted prices

## Decisions to revisit

- Waypoint labels use " - " instead of an em dash; the game font may lack the glyph.
- Captured cost keeps the highest seen across classes; reputation discounts only lower it.
