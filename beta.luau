-- GALAXIS HUB | MODULAR BETA LOADER
-- Execute this file only. Feature code lives in /modules and shares one isolated environment.
local BASE = "https://raw.githubusercontent.com/lCoastal/testing/main/modules/"
local CACHE_BUSTER = "431127d6485845ed"
local MODULES = {
    {"01_core.luau", "Core and shared services"},
    {"02_dredge.luau", "Dredge routing and quest engine"},
    {"03_logger.luau", "Mineral logger"},
    {"04_ui_foundation.luau", "UI foundation and widgets"},
    {"05_tabs.luau", "Tabs and zone editor"},
    {"06_pack.luau", "Infinite Pack inspector"},
    {"07_reforge.luau", "Manual and automatic reforge"},
    {"08_debug_ui.luau", "Debug UI and shutdown"},
    {"09_farming.luau", "Selling and farming helpers"},
    {"10_routes_ui.luau", "Zone controls and route recording"},
    {"11_worker.luau", "Farm worker and input handlers"},
    {"12_treasure.luau", "Treasure Map diagnostics"},
}
local parentEnv = getfenv()
local sharedEnv = setmetatable({}, {__index = parentEnv})
sharedEnv._G = sharedEnv
local function loadModule(file, label)
    local url = BASE .. file .. "?v=" .. CACHE_BUSTER
    local okDownload, source = pcall(function()
        return game:HttpGet(url, true)
    end)
    if not okDownload or type(source) ~= "string" or #source < 20 then
        error("Could not download " .. file .. ": " .. tostring(source))
    end
    local fn, compileError = loadstring(source, "@Galaxis/" .. file)
    if type(fn) ~= "function" then
        error("Compile failed in " .. file .. ": " .. tostring(compileError))
    end
    if type(setfenv) ~= "function" then
        error("Executor does not provide setfenv; modular loader cannot share state.")
    end
    setfenv(fn, sharedEnv)
    local okRun, runError = pcall(fn)
    if not okRun then error("Runtime error in " .. file .. ": " .. tostring(runError)) end
    print("[GALAXIS] Loaded " .. label .. " (" .. file .. ")")
end
for _, module in ipairs(MODULES) do
    local ok, err = pcall(loadModule, module[1], module[2])
    if not ok then warn("[GALAXIS] MODULE LOAD FAILED:", err); return end
end
print("[GALAXIS] All modules loaded successfully.")
