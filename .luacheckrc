std = "lua51"
max_line_length = 120
exclude_files = { ".claude/", "dist/" }

globals = {
  "SLASH_WEAPONWISE1", "SLASH_WEAPONWISE2", "SlashCmdList", "WeaponWiseDB", "WeaponWiseDevDB",
}

read_globals = {
  "CreateFrame", "hooksecurefunc", "GameTooltip",
  "GetBuildInfo", "UnitClass", "UnitFactionGroup", "UnitGUID", "UnitName", "UnitLevel",
  "GetZoneText", "GetSubZoneText", "C_Map", "C_Container", "time",
  "GetNumSkillLines", "GetSkillLineInfo",
  "GetNumTrainerServices", "GetTrainerServiceInfo", "GetTrainerServiceCost",
  "GetTrainerServiceLevelReq", "GetTrainerServiceTypeFilter", "SetTrainerServiceTypeFilter",
  "GetContainerItemLink", "GetInventoryItemLink", "NUM_CONTAINER_FRAMES", "MAX_CONTAINER_ITEMS",
  "IsControlKeyDown", "IsAltKeyDown", "IsShiftKeyDown",
  "GetItemInfoInstant", "C_Item", "TooltipDataProcessor", "Enum", "UiMapPoint", "C_SuperTrack",
  "TomTom", "CreateVector2D", "GetCoinTextureString", "C_CurrencyInfo", "GetMoneyString", "AuctionHouseFrame", "GetMouseButtonClicked",
  "C_SkillInfo", "HandleModifiedItemClick",
}

files["spec/"] = {
  std = "+busted",
  globals = { "_G" },
}

-- Host-side tools run on Lua 5.4, not in the game.
files["tools/"] = {
  std = "lua54",
}
