-- antisakura.lua
-- Anti Sakura Tree module
-- When loaded it wraps/adopts the global isValidTarget to ignore players
-- that are within 5 studs of any island1/island2/island3 "Sakura Tree" trunk.
-- Expects loader to expose: _G.State, _G.Internal, and optionally _G.isValidTarget.

if _G.SB_antisakura_loaded then return end
_G.SB_antisakura_loaded = true

local CHECK_RADIUS = 5

-- safe reference to workspace
local Workspace = workspace

local function findTrunkInSakura(sakuraModel)
    if not sakuraModel then return nil end
    -- prefer explicit "Trunk" child
    local t = sakuraModel:FindFirstChild("Trunk")
    if t and t:IsA("BasePart") then return t end
    -- otherwise search descendants for a part with "trunk" in the name
    for _, d in ipairs(sakuraModel:GetDescendants()) do
        if d:IsA("BasePart") and tostring(d.Name):lower():find("trunk") then
            return d
        end
    end
    return nil
end

local function isPlayerNearAnySakura(player)
    if not player or not player.Character then return false end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local arena = Workspace:FindFirstChild("Arena")
    if not arena then return false end

    for i = 1, 3 do
        local islandName = "island" .. tostring(i)
        local island = arena:FindFirstChild(islandName)
        if island then
            local sakura = island:FindFirstChild("Sakura Tree")
            if sakura then
                local trunk = findTrunkInSakura(sakura)
                if trunk and trunk:IsA("BasePart") then
                    local dist = (hrp.Position - trunk.Position).Magnitude
                    if dist <= CHECK_RADIUS then
                        return true
                    end
                end
            end
        end
    end

    return false
end

-- adopt existing global validator (if any)
local previousValidator = _G.isValidTarget or function(p) return true end

-- install new validator that respects the AntiSakura flag
_G.isValidTarget = function(player)
    -- keep existing ragdoll / other checks if remote modules set Internal
    if _G.Internal then
        if _G.Internal.RagdollIgnoredGround and _G.Internal.RagdollIgnoredGround[player] then return false end
        if _G.Internal.RagdollIgnoredAir and _G.Internal.RagdollIgnoredAir[player] then return false end
    end

    -- if user enabled AntiSakura, ignore players near sakura trunks
    if _G.State and _G.State.AntiSakuraEnabled then
        local ok, near = pcall(isPlayerNearAnySakura, player)
        if ok and near then
            return false
        end
    end

    -- delegate to previous validator
    return previousValidator(player)
end

-- optional: expose a small helper so remote callers (or you) can query quickly
_G.SB_antisakura_isNear = isPlayerNearAnySakura

-- module loaded
