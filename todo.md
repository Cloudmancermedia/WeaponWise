# WeaponWise todo

Working memory for the build. Spec: Obsidian `Personal/_Projects/WeaponWise/Spec.md`.
Everything under "Code" is written and unit tested; everything under "In-game"
needs the Forever client.

## Code (done)

- [x] Phase 0: repo, TOC, Core, busted + luacheck, /ww probe, capture, clicktest
- [x] Phase 1: WeaponTypes, ClassicWeapons + ForeverAdditions, WeaponSkillService, Tooltip
- [x] Phase 2: trainer seed data (wiki, unverified), Cities, Location, TrainerService, Lookup
- [x] Phase 3: NavigationService (native, TomTom, coords), ItemClickHandler
- [x] Phase 4: Shift alternatives, Config + /ww set, release gate spec, capture importer

## In-game (needs the owner)

- Forever's client runs the modern Mainline UI (TooltipDataProcessor, Mainline/ContainerFrame.lua),
  not the Classic UI. Bag button names and click hooks are unconfirmed on it; clicktest decides.
- [x] Fixed: tooltip hook called GetItem on ShoppingTooltip1, which lacks it (reported 2026-10-13)
- Probe 2026-10-13: interface 16001, native waypoints present, TooltipDataProcessor only,
  C_Container/C_Item only. GetNumSkillLines/GetSkillLineInfo MISSING: no way yet to read
  weapon skill. Skill-related functions now listed by /ww probe (skillApis) to find one.
- [x] Fixed: hovering a weapon crashed in ReadSkills; usable weapons now show nothing until skills can be read
- [x] Skill API found: C_SkillInfo.GetNumSkillLines / GetSkillLineInfo. ReadSkills uses it if it returns
  classic-style values; table returns read as unknown until probe.skillLineDump shows the fields
- [x] C_SkillInfo returns one table per row (name, isHeader, rank, maxRank, skillID, skillLineCategoryID);
  ReadSkills reads it. Rogue dump: Axes 44, Daggers 173, Swords 43, Thrown 176 all match skillName
- [x] Skills matched by skillID first, enUS name as fallback. IDs confirmed on Forever: 44, 43, 173, 176
  (Rogue), 54, 136, 160 (Shaman). The other 8 are Classic Era values; a probe on any class that has them confirms.
- [x] Clicks: bag and weapon-slot modified clicks all reach HandleModifiedItemClick with the right
  button; ItemClickHandler now hooks only that. Neither binding does anything else to a weapon.

- [x] Interface number 16001 (from installed addons; probe confirms build). Linked into _classic_beta_/Interface/AddOns
- [x] Trainer data: owner confirmed the wiki lists are current for Forever (2026-10-13); prices
  set to 10s per weapon, polearms 1g at level 20. Captures now optional.
- [ ] Confirm weapon subclass IDs (hover a few weapons; wrong IDs show wrong or no lines)
- [x] City uiMapIDs: all six confirmed by owner pin tests 2026-10-13
- [x] Forever weapon changes, per owner 2026-10-13: Shaman 2H axes/maces, Rogue 1H axes, Druid polearms.
  No others known. (Orc Rogue starts with Axes; Skyborn Shaman starts with 2H Maces. The skill list handles both.)
- [x] Owner-verified in client 2026-10-13: scenario 1 (known skill), scenario 2 (trainable, mace -> trainer),
  unavailable line, scenario 3 (Ctrl+Right-Click sets native map pin; Thunder Bluff mapID 1456 works)
- [x] Scenario 4 (Shift alternatives) verified 2026-10-13

## Still to test in game

- [ ] Shaman: two-handed axe shows Hanashi + "New in Forever"; two-handed mace shows known + "New in Forever"
- [ ] Scenario 5: after training a weapon skill, its tooltip flips to "You know this weapon skill" without /reload
- [ ] Auction house: unconfirmed. The 2026-10-13 click log holds no AH entries, so either AH rows never call
  HandleModifiedItemClick or /ww clicktest was off. Retest: /ww clicktest (chat prints "click:" per click),
  Alt + Left-Click and Ctrl + Right-Click a weapon row, /ww clicktest, /reload. Not a release blocker.
- [ ] Release smoke test: swap the dev symlink for the built zip, /reload, check tooltips and that /ww lists
  only config and set, then restore the symlink

## Release

- [x] `make release VERSION=x.y.z` builds dist/WeaponWise-x.y.z.zip without Dev\ files or WeaponWiseDevDB
- [x] Owner 2026-10-13: Orgrimmar pin works; Shift alternatives show
- [x] Shift alternatives use the main trainer's format; "Hold Shift for other trainers" hint added
- [x] Owner 2026-10-13: Shift updates the tooltip in place (RefreshData); coin icons show
- [x] Owner 2026-10-13: pins correct in all six cities (/ww pin); Woo Ping moved to 63, 69 (owner)
- [x] Owner 2026-10-13: Ctrl + Right-Click on a merchant item sets the pin and does not buy it
- [ ] Owner: where to publish (CurseForge / Wago / GitHub / zip)
- [x] First commit 28e2c94 pushed to github.com/Cloudmancermedia/WeaponWise main (2026-10-13)

## Spec note updates (all applied 2026-10-13)

- [x] Rename M1-M4 to Phase 1-4 (applied 2026-10-13)
- [x] Add the "New in Forever" requirement (section 2.5)
- [x] Fix the examples: Hanashi (Orgrimmar) replaces Archibald; Sayoc replaces Ansekhwa as the alternative
- [x] Known-skill line wording: "You know this weapon skill (current/max)"

## Decisions to revisit

- Waypoint labels use " - " instead of an em dash; the game font may lack the glyph.
- Captured cost keeps the highest seen across classes; reputation discounts only lower it.
