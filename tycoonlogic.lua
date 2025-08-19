-- ANTI-TYCOON (extended with Dropper/Wedge/Force keywords)
-- Make sure you added: AntiTycoonEnabled = false, to your State table

local function isPlayerInRestrictedZone(player, radius)
    if not player or not player.Character then return false end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    radius = radius or 8

    -- Keywords to check against
    local blockedKeywords = { "tycoon", "dropper", "wedge", "force" }

    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Folder") then
            local lowerName = tostring(obj.Name):lower()
            for _, kw in ipairs(blockedKeywords) do
                if lowerName:find(kw) then
                    -- if HRP is inside this object, ignore
                    if hrp:IsDescendantOf(obj) then
                        return true
                    end
                    -- otherwise check proximity to any parts inside
                    for _, part in pairs(obj:GetDescendants()) do
                        if part:IsA("BasePart") then
                            if (hrp.Position - part.Position).Magnitude <= radius then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end

    return false
end

-- Wrap your target validator
local oldIsValidTarget = isValidTarget
isValidTarget = function(player)
    if Internal.RagdollIgnoredGround[player] or Internal.RagdollIgnoredAir[player] then
        return false
    end

    if State.AntiTycoonEnabled then
        if isPlayerInRestrictedZone(player, 8) then
            return false
        end
    end

    return oldIsValidTarget(player)
end
