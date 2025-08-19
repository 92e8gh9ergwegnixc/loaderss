-- ANTI-TYCOON LOGIC (paste this in place of the current isValidTarget wrapper)
-- Add `AntiTycoonEnabled = false,` to your `State = { ... }` table if not present.

local function isPlayerInTycoon(player, radius)
    if not player or not player.Character then return false end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    radius = radius or 8

    -- look for Models whose name contains "tycoon" (case-insensitive)
    for _, m in pairs(Workspace:GetDescendants()) do
        if m:IsA("Model") and tostring(m.Name):lower():find("tycoon") then
            -- if the player's HRP is parented under the tycoon model, count it
            if hrp:IsDescendantOf(m) then
                return true
            end
            -- otherwise check proximity to any BasePart inside that model
            for _, part in pairs(m:GetDescendants()) do
                if part:IsA("BasePart") then
                    if (hrp.Position - part.Position).Magnitude <= radius then
                        return true
                    end
                end
            end
        end
    end

    return false
end

-- Replace your existing wrapper with this one so anti-tycoon can block targets
local oldIsValidTarget = isValidTarget
isValidTarget = function(player)
    if Internal.RagdollIgnoredGround[player] or Internal.RagdollIgnoredAir[player] then
        return false
    end

    -- if you enable this flag in State, players inside/near tycoons will be ignored
    if State.AntiTycoonEnabled then
        if isPlayerInTycoon(player, 8) then
            return false
        end
    end

    return oldIsValidTarget(player)
end
