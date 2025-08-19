-- antispectator.lua
-- Detecta jugadores "Spectator" (herramienta llamada "Spectator" o leaderstats.Glove == "Spectator")
-- Usa cache + listeners para evitar lag. Expone _G.SB_isSpectator(player)

if _G.SB_antispectator_loaded then return end
_G.SB_antispectator_loaded = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- cache: player -> bool (true = is spectator)
local SpectatorCache = {}

-- helpers
local function nameHasSpectator(str)
    if not str then return false end
    return tostring(str):lower():find("spectator") ~= nil
end

local function checkToolsInContainer(container)
    if not container then return false end
    for _, child in ipairs(container:GetChildren()) do
        if child and child:IsA("Tool") then
            if nameHasSpectator(child.Name) then return true end
        end
    end
    return false
end

local function checkLeaderstatsForGlove(player)
    if not player then return false end
    local ls = player:FindFirstChild("leaderstats")
    if not ls then return false end
    local glove = ls:FindFirstChild("Glove") or ls:FindFirstChild("glove") or ls:FindFirstChild("Gloves")
    if glove and (type(glove.Value) == "string" or typeof(glove.Value) == "string") then
        return nameHasSpectator(glove.Value)
    end
    return false
end

local function computeIsSpectator(player)
    -- quick negative checks
    if not player then return false end

    -- 1) Character tools
    local char = player.Character
    if char and checkToolsInContainer(char) then return true end

    -- 2) Backpack tools
    local backpack = player:FindFirstChild("Backpack")
    if backpack and checkToolsInContainer(backpack) then return true end

    -- 3) leaderstats Glove
    if checkLeaderstatsForGlove(player) then return true end

    -- 4) fallback: check a direct child string value (some games store glove as player.Glove StringValue)
    local gloveVal = player:FindFirstChild("Glove") or player:FindFirstChild("glove")
    if gloveVal and (type(gloveVal.Value) == "string" or typeof(gloveVal.Value) == "string") then
        if nameHasSpectator(gloveVal.Value) then return true end
    end

    return false
end

-- update cache for one player (safe)
local function updatePlayerCache(player)
    if not player then return end
    local ok, res = pcall(function() return computeIsSpectator(player) end)
    SpectatorCache[player] = ok and res or false
end

-- attach listeners for a player to keep cache updated
local function attachPlayerListeners(player)
    if not player then return end
    -- initial compute
    updatePlayerCache(player)

    -- CharacterAdded: when tools appear in character
    player.CharacterAdded:Connect(function(char)
        updatePlayerCache(player)
        -- monitor tools added/removed in the character
        char.ChildAdded:Connect(function() updatePlayerCache(player) end)
        char.ChildRemoved:Connect(function() updatePlayerCache(player) end)
    end)

    -- Backpack changes
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        backpack.ChildAdded:Connect(function() updatePlayerCache(player) end)
        backpack.ChildRemoved:Connect(function() updatePlayerCache(player) end)
    end
    -- watch for Backpack being created later
    player:GetPropertyChangedSignal("Backpack"):Connect(function()
        local bp = player:FindFirstChild("Backpack")
        if bp then
            bp.ChildAdded:Connect(function() updatePlayerCache(player) end)
            bp.ChildRemoved:Connect(function() updatePlayerCache(player) end)
            updatePlayerCache(player)
        end
    end)

    -- leaderstats: watch for the folder and inside Glove value changes
    local function watchLeaderstats()
        local ls = player:FindFirstChild("leaderstats")
        if not ls then return end
        local glove = ls:FindFirstChild("Glove") or ls:FindFirstChild("glove") or ls:FindFirstChild("Gloves")
        if glove and glove:IsA("ValueBase") then
            -- Value changes trigger recalc
            glove:GetPropertyChangedSignal("Value"):Connect(function() updatePlayerCache(player) end)
        end
        -- also if Glove added later
        ls.ChildAdded:Connect(function(child)
            if child and (child.Name == "Glove" or child.Name:lower():find("glove")) then
                if child:IsA("ValueBase") then child:GetPropertyChangedSignal("Value"):Connect(function() updatePlayerCache(player) end) end
                updatePlayerCache(player)
            end
        end)
    end
    -- initial attempt and also react when leaderstats appears
    watchLeaderstats()
    player.ChildAdded:Connect(function(child)
        if child and child.Name == "leaderstats" then
            watchLeaderstats()
            updatePlayerCache(player)
        end
    end)

    -- small periodic check as a fallback but very low frequency to avoid lag
    -- this covers edge cases where events aren't fired (0.8s is low enough for responsiveness, high enough to avoid lag)
    task.spawn(function()
        while _G.Internal and _G.Internal.MainAlive and player.Parent do
            updatePlayerCache(player)
            task.wait(0.8)
        end
    end)
end

-- expose public query function (fast, reads cache)
local function isSpectator(player)
    if not player then return false end
    local v = SpectatorCache[player]
    if v ~= nil then return v end
    -- no cache yet, compute once and attach listeners
    updatePlayerCache(player)
    attachPlayerListeners(player)
    return SpectatorCache[player] or false
end

-- bootstrap for existing players
for _, p in ipairs(Players:GetPlayers()) do
    attachPlayerListeners(p)
end
Players.PlayerAdded:Connect(function(p)
    attachPlayerListeners(p)
end)
Players.PlayerRemoving:Connect(function(p)
    SpectatorCache[p] = nil
end)

-- expose globally for main loader to use (name chosen to be explicit)
_G.SB_isSpectator = isSpectator
