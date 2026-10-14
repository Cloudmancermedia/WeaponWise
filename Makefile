BIN := $(HOME)/.luarocks/bin
LUA := $(shell brew --prefix lua@5.4)/bin/lua5.4

.PHONY: check test lint link import release

check: lint test

test:
	$(BIN)/busted

lint:
	$(BIN)/luacheck .

# Symlink this checkout into the game. Usage: make link ADDONS="/path/to/Interface/AddOns"
link:
	@test -n "$(ADDONS)" || (echo "set ADDONS=/path/to/Interface/AddOns" && exit 1)
	ln -sfn "$(CURDIR)" "$(ADDONS)/WeaponWise"

# Merge /ww capture data into Data/WeaponTrainers.lua. Usage: make import SV="<path>/SavedVariables/WeaponWise.lua"
import:
	@test -n "$(SV)" || (echo "set SV=/path/to/SavedVariables/WeaponWise.lua" && exit 1)
	$(LUA) tools/import_captures.lua "$(SV)"

# Build dist/WeaponWise-<version>.zip without dev tools. Usage: make release VERSION=0.1.0
release: check
	@test -n "$(VERSION)" || (echo "set VERSION=x.y.z" && exit 1)
	$(LUA) tools/release.lua "$(VERSION)"
