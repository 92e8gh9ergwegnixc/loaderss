-- Optimized auto-remove (reactive + chunked sweep)
local RunService = game:GetService("RunService")
local Workspace = workspace
local keywords = { "tycoon", "dropper", "wedge", "force", "building" }
for i,k in ipairs(keywords) do keywords[i] = k:lower() end

local function nameMatchesAny(name)
    if not name then return false end
    local ln = tostring(name):lower()
    for _, kw in ipairs(keywords) do
        if ln:find(kw, 1, true) then
            return true
        end
    end
    return false
end

-- Safe destroy helper (silences errors)
local function safeDestroy(obj)
    pcall(function()
        if obj and obj.Parent then
            obj:Destroy()
        end
    end)
end

-- Reactive removal: handle newly added descendants quickly
local function onDescendantAdded(desc)
    -- quick class filter to reduce work
    if not (desc:IsA("BasePart") or desc:IsA("Model") or desc:IsA("Folder")) then return end
    if nameMatchesAny(desc.Name) then
        -- destroy immediately (fast path)
        safeDestroy(desc)
    end
end
local connAdded = Workspace.DescendantAdded:Connect(onDescendantAdded)

-- Periodic chunked sweep (fallback) to catch existing/stale stuff
local SWEEP_INTERVAL = 4       -- seconds between full sweeps (tune: 2..8)
local CHUNK_SIZE = 250         -- how many descendants to check per frame (tune: 100..500)

task.spawn(function()
    while true do
        task.wait(SWEEP_INTERVAL)
        -- gather snapshots once
        local all = Workspace:GetDescendants()
        local n = #all
        if n == 0 then continue end

        local i = 1
        while i <= n do
            local upper = math.min(i + CHUNK_SIZE - 1, n)
            for j = i, upper do
                local obj = all[j]
                if obj and obj.Parent then
                    -- cheap class check first
                    local c = obj.ClassName
                    if c == "Part" or c == "MeshPart" or c == "Model" or c == "Folder" or c == "UnionOperation" or c == "WedgePart" or c == "BasePart" then
                        if nameMatchesAny(obj.Name) then
                            -- queue destroy (destroy here is okay because we're working on snapshot)
                            safeDestroy(obj)
                        end
                    else
                        -- optionally do a name-only check for heavier types if needed:
                        if nameMatchesAny(obj.Name) and (obj:IsA("Folder") or obj:IsA("Model")) then
                            safeDestroy(obj)
                        end
                    end
                end
            end
            -- yield a frame to avoid a big spike
            task.wait()
            i = upper + 1
        end
    end
end)
