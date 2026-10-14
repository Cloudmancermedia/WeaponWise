-- Builds dist/WeaponWise-<version>.zip: the files the TOC lists, minus Dev\
-- tools and their saved variable, with the version set. The checkout stays a
-- dev build. Usage: lua tools/release.lua <version> (or make release).
local Release = {}

-- Returns the release TOC text and the files it loads (forward slashes).
function Release.Toc(text, version)
  assert(version and version:match("^%d+%.%d+%.%d+$"), "version must look like 1.2.3, got " .. tostring(version))
  local out, files = {}, {}
  for line in (text .. "\n"):gmatch("(.-)\n") do
    if line:match("^## Version:") then
      line = "## Version: " .. version
    elseif line:match("^## SavedVariables:") then
      local vars = {}
      for v in line:gsub("^## SavedVariables:", ""):gmatch("[^,%s]+") do
        if v ~= "WeaponWiseDevDB" then vars[#vars + 1] = v end
      end
      line = "## SavedVariables: " .. table.concat(vars, ", ")
    elseif line ~= "" and not line:match("^#") then
      local path = line:gsub("\\", "/")
      if path:match("^Dev/") then line = nil else files[#files + 1] = path end
    end
    if line then out[#out + 1] = line end
  end
  if out[#out] == "" then out[#out] = nil end
  return table.concat(out, "\n") .. "\n", files
end

local function sh(cmd)
  assert(os.execute(cmd), "failed: " .. cmd)
end

local function quote(s) return "'" .. s:gsub("'", "'\\''") .. "'" end

function Release.Build(version)
  local ns = {}
  assert(loadfile("Data/WeaponTrainers.lua"))("WeaponWise", ns)
  for _, t in ipairs(ns.WeaponTrainers) do assert(t.verified, t.name .. " is unverified") end

  local f = assert(io.open("WeaponWise.toc"))
  local toc, files = Release.Toc(f:read("a"), version)
  f:close()

  local root = "dist/WeaponWise"
  sh("rm -rf " .. quote(root) .. " && mkdir -p " .. quote(root))
  for _, path in ipairs(files) do
    local dir = path:match("^(.*)/")
    if dir then sh("mkdir -p " .. quote(root .. "/" .. dir)) end
    sh("cp " .. quote(path) .. " " .. quote(root .. "/" .. path))
  end
  local out = assert(io.open(root .. "/WeaponWise.toc", "w"))
  out:write(toc)
  out:close()
  local zip = "WeaponWise-" .. version .. ".zip"
  sh("cd dist && rm -f " .. quote(zip) .. " && zip -qr " .. quote(zip) .. " WeaponWise")
  return "dist/" .. zip
end

if arg and arg[0] and arg[0]:match("release%.lua$") and arg[1] then
  print("built " .. Release.Build(arg[1]))
end

return Release
