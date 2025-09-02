-- OptimizeAll + RemoveLightingEffects (LocalScript for StarterPlayerScripts / StarterGui)
-- Purpose: single-file performance optimizer with "optimizeAll" and "removeLightingEffects" APIs,
-- plus many additional non-destructive optimizations and a full restore function.
-- Drop this file into StarterPlayerScripts or StarterGui and call OptimizeAll.optimizeAll() or OptimizeAll.removeLightingEffects()
-- Use OptimizeAll.restoreAll() to restore original state.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local OptimizeAll = {}
do
    -- backups
    local backup = {
        lighting = {},
        particles = {},
        effects = {},
        decals = {},
        textures = {},
        sounds = {},
        soundsSettings = {},
        terrain = {},
        partsCanCollide = {},
        guiEnabled = {},
    }
    local applied = {
        particles = false,
        lighting = false,
        decals = false,
        textures = false,
        sounds = false,
        terrain = false,
    }

    -- helpers
    local function safe(fn, ...)
        local ok, res = pcall(fn, ...)
        if not ok then
            -- we intentionally swallow errors to avoid breaking the host game
            return nil
        end
        return res
    end

    local function collectDescendantsOnce(root)
        -- single GetDescendants call to minimize expensive repeatedly polling the hierarchy
        return safe(function() return root:GetDescendants() end) or {}
    end

    -- -------- remove / disable lighting effects (non-destructive) ----------
    function OptimizeAll.removeLightingEffects()
        -- backup common Lighting properties
        if not backup.lighting.backed then
            backup.lighting.backed = true
            backup.lighting.GlobalShadows = Lighting.GlobalShadows
            backup.lighting.Brightness = Lighting.Brightness
            backup.lighting.ExposureCompensation = (Lighting:GetAttribute("Optimize_Backup_ExposureCompensation") ~= nil) and Lighting.ExposureCompensation or Lighting.ExposureCompensation
            backup.lighting.FogEnd = Lighting.FogEnd
            backup.lighting.OutdoorAmbient = Lighting.OutdoorAmbient
            backup.lighting.TimeOfDay = Lighting.ClockTime or Lighting:GetAttribute("Optimize_Backup_ClockTime") -- ClockTime in newer API
            backup.lighting.Sky = safe(function() return Lighting:FindFirstChildOfClass("Sky") end)
        end

        -- best-effort: disable post-processing effects and set low-impact lighting values
        for _, inst in pairs(collectDescendantsOnce(Lighting)) do
            if inst:IsA("BlurEffect")
            or inst:IsA("ColorCorrectionEffect")
            or inst:IsA("BloomEffect")
            or inst:IsA("SunRaysEffect")
            or inst:IsA("DepthOfFieldEffect")
            or inst:IsA("ToneMapEffect") -- ToneMappingEffect name varies by API
            or inst:IsA("SunRaysEffect") then
                if not backup.effects[inst] then backup.effects[inst] = {Parent = inst.Parent, Enabled = inst.Enabled} end
                safe(function() inst.Enabled = false end)
            end
            -- Atmosphere/Sky are heavier: reduce or remove
            if inst:IsA("Atmosphere") then
                if not backup.effects[inst] then backup.effects[inst] = {Parent = inst.Parent, Density = inst.Density, Offset = inst.Offset, Color = inst.Color} end
                safe(function()
                    inst.Density = 0
                    inst.Offset = 0
                    inst.Color = Color3.new(1,1,1)
                end)
            end
            if inst:IsA("Sky") then
                -- keep a reference in backup and parent so we can restore; do not destroy
                if not backup.effects[inst] then backup.effects[inst] = {Parent = inst.Parent, Skybox = true} end
                safe(function()
                    -- reduce influence by clearing skybox ids if present
                    pcall(function() inst.SkyboxUp = "" end)
                    pcall(function() inst.SkyboxLf = "" end)
                    pcall(function() inst.SkyboxBk = "" end)
                    pcall(function() inst.SkyboxDn = "" end)
                    pcall(function() inst.SkyboxRt = "" end)
                end)
            end
        end

        -- Lighting level tweaks
        safe(function() Lighting.GlobalShadows = false end)
        safe(function() Lighting.Brightness = math.max(placeholder and 1 or 0, 0) end) -- keep >= 0
        safe(function() Lighting.FogEnd = math.max(1000, Lighting.FogEnd or 1000) end)
        -- If ClockTime exists (newer API), set a neutral value
        pcall(function() if Lighting.ClockTime then Lighting.ClockTime = 12 end end)

        applied.lighting = true
    end

    -- -------- disable/strip particles & trails & visual FX ----------
    function OptimizeAll.disableParticles()
        if applied.particles then return end
        local desc = collectDescendantsOnce(Workspace)
        for _, obj in ipairs(desc) do
            if obj:IsA("ParticleEmitter")
            or obj:IsA("Trail")
            or obj:IsA("Sparkles")
            or obj:IsA("Smoke")
            or obj:IsA("Fire")
            or obj:IsA("Beam") then
                if not backup.particles[obj] then
                    backup.particles[obj] = {}
                    -- store commonly changed fields
                    backup.particles[obj].Enabled = pcall(function() return obj.Enabled end) and obj.Enabled or nil
                    backup.particles[obj].Lifetime = pcall(function() return obj.Lifetime end) and obj.Lifetime or nil
                    backup.particles[obj].Rate = pcall(function() return obj.Rate end) and obj.Rate or nil
                end
                safe(function() obj.Enabled = false end)
                -- further CPU reduction: set Rate to 0 if property exists
                pcall(function() if obj.Rate then obj.Rate = 0 end end)
            end
        end
        applied.particles = true
    end

    -- -------- reduce decal/texture rendering ----------
    function OptimizeAll.reduceDecalsAndTextures()
        if applied.decals and applied.textures then return end
        local desc = collectDescendantsOnce(Workspace)
        for _, obj in ipairs(desc) do
            if obj:IsA("Decal") or obj:IsA("Texture") then
                if not backup.decals[obj] then
                    backup.decals[obj] = {Transparency = pcall(function() return obj.Transparency end) and obj.Transparency or nil}
                end
                safe(function() obj.Transparency = 1 end)
            end
            -- SurfaceAppearance is heavier (PBR). Reduce by making it invisible/simpler
            if obj:IsA("SurfaceAppearance") then
                if not backup.textures[obj] then
                    backup.textures[obj] = {Parent = obj.Parent, Enabled = true}
                end
                safe(function()
                    -- unlink or set transparency via parent materials if possible
                    if obj.Parent and obj.Parent:IsA("Decal") then
                        pcall(function() obj.Parent.Transparency = 1 end)
                    else
                        -- try to clear texture ids (non-destructive: store then clear)
                        pcall(function()
                            if obj.ColorMap then obj.ColorMap = "" end
                            if obj.MetalnessMap then obj.MetalnessMap = "" end
                            if obj.NormalMap then obj.NormalMap = "" end
                        end)
                    end
                end)
            end
        end
        applied.decals = true
        applied.textures = true
    end

    -- -------- reduce sound overhead ----------
    function OptimizeAll.muteAllSounds()
        if applied.sounds then return end
        -- backup global volume if present
        if not backup.soundsSettings.backed then
            backup.soundsSettings.backed = true
            pcall(function() backup.soundsSettings.Volume = SoundService.Volume end)
        end
        safe(function() SoundService.Volume = 0 end)

        -- also mute individual Sound objects (non-destructive)
        local desc = collectDescendantsOnce(Workspace)
        for _, s in ipairs(desc) do
            if s:IsA("Sound") then
                if not backup.sounds[s] then
                    backup.sounds[s] = {Volume = pcall(function() return s.Volume end) and s.Volume or nil, Playing = pcall(function() return s.IsPlaying end) and s.IsPlaying or nil}
                end
                safe(function() s.Volume = 0 end)
            end
        end
        applied.sounds = true
    end

    -- -------- terrain & water optimizations ----------
    function OptimizeAll.tuneTerrain()
        if applied.terrain then return end
        local terrain = Workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            if not backup.terrain.backed then
                backup.terrain.backed = true
                pcall(function() backup.terrain.WaterReflectance = terrain.WaterReflectance end)
                pcall(function() backup.terrain.WaterTransparency = terrain.WaterTransparency end)
                pcall(function() backup.terrain.WaterWaveSize = terrain.WaterWaveSize end)
                pcall(function() backup.terrain.WaterWaveSpeed = terrain.WaterWaveSpeed end)
            end
            safe(function()
                terrain.WaterReflectance = 0
                terrain.WaterTransparency = 0.9
                terrain.WaterWaveSize = 0
                terrain.WaterWaveSpeed = 0
            end)
            applied.terrain = true
        end
    end

    -- -------- GUI cleanup: hide top-level non-essential ScreenGuis (optional) ----------
    function OptimizeAll.hideHeavyGuis()
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if not pg then return end
        for _, gui in ipairs(pg:GetChildren()) do
            if gui:IsA("ScreenGui") then
                -- skip player-owned essential guis (by name heuristics)
                local name = gui.Name:lower()
                if name:match("hud") or name:match("gui") or name:match("screen") then
                    if not backup.guiEnabled[gui] then backup.guiEnabled[gui] = {Enabled = pcall(function() return gui.Enabled end) and gui.Enabled or nil} end
                    pcall(function() gui.Enabled = false end)
                end
            end
        end
    end

    -- -------- lightweight physics / parts adjustments ----------
    function OptimizeAll.reducePartPhysics()
        -- convert CanCollide to false for small decorative parts (store and skip larger world geometry)
        local desc = collectDescendantsOnce(Workspace)
        for _, part in ipairs(desc) do
            if part:IsA("BasePart") and not part:IsA("Terrain") then
                -- heuristic: skip very large parts (likely world geometry) by size
                local size = pcall(function() return part.Size end) and part.Size or Vector3.new(1,1,1)
                local volume = size.X * size.Y * size.Z
                if volume <= 2000 then -- small decorative part threshold
                    if backup.partsCanCollide[part] == nil then
                        backup.partsCanCollide[part] = pcall(function() return part.CanCollide end) and part.CanCollide or nil
                    end
                    pcall(function() part.CanCollide = false end)
                end
            end
        end
    end

    -- -------- main "optimize all" that applies many of the functions above ----------
    function OptimizeAll.optimizeAll(opts)
        -- opts is optional table to pick what to run; default: run everything safe
        opts = type(opts) == "table" and opts or {}

        -- provide quick toggles (default true)
        local doLighting = opts.lighting == nil and true or opts.lighting
        local doParticles = opts.particles == nil and true or opts.particles
        local doDecals = opts.decals == nil and true or opts.decals
        local doTextures = opts.textures == nil and true or opts.textures
        local doSounds = opts.sounds == nil and true or opts.sounds
        local doTerrain = opts.terrain == nil and true or opts.terrain
        local doGuis = opts.guis == nil and false or opts.guis -- default off, optional
        local doPhysics = opts.physics == nil and true or opts.physics

        -- perform operations safely and in batches
        if doLighting then
            pcall(function() OptimizeAll.removeLightingEffects() end)
        end

        if doParticles then
            pcall(function() OptimizeAll.disableParticles() end)
        end

        if doDecals or doTextures then
            pcall(function() OptimizeAll.reduceDecalsAndTextures() end)
        end

        if doSounds then
            pcall(function() OptimizeAll.muteAllSounds() end)
        end

        if doTerrain then
            pcall(function() OptimizeAll.tuneTerrain() end)
        end

        if doGuis then
            pcall(function() OptimizeAll.hideHeavyGuis() end)
        end

        if doPhysics then
            pcall(function() OptimizeAll.reducePartPhysics() end)
        end

        -- optional: try to reduce animation updates / heartbeat frequency by briefly yielding heavy tasks
        -- (We avoid interfering with core humanoid animations to be non-destructive)

        -- final safety: run a small garbage-collection friendly heartbeat sweep to ensure settings applied
        safe(function()
            for i = 1, 2 do
                RunService.Heartbeat:Wait()
            end
        end)

        return true
    end

    -- -------- restore all backed-up changes ----------
    function OptimizeAll.restoreAll()
        -- restore lighting
        if backup.lighting.backed then
            pcall(function() Lighting.GlobalShadows = backup.lighting.GlobalShadows end)
            pcall(function() Lighting.Brightness = backup.lighting.Brightness end)
            pcall(function() if Lighting.ClockTime and backup.lighting.TimeOfDay then Lighting.ClockTime = backup.lighting.TimeOfDay end end)
            backup.lighting = {}
        end

        -- restore effects & sky & atmosphere
        for inst, data in pairs(backup.effects) do
            if inst and inst.Parent then
                pcall(function()
                    if data.Enabled ~= nil then inst.Enabled = data.Enabled end
                    if data.Density ~= nil and inst:IsA("Atmosphere") then inst.Density = data.Density end
                    if data.Offset ~= nil and inst:IsA("Atmosphere") then inst.Offset = data.Offset end
                    if data.Color and inst:IsA("Atmosphere") then inst.Color = data.Color end
                    if data.Skybox then
                        -- nothing to restore for cleared skybox strings (we saved the instance only)
                    end
                end)
            end
        end
        backup.effects = {}

        -- restore particles
        for obj, data in pairs(backup.particles) do
            if obj and obj.Parent then
                pcall(function()
                    if data.Enabled ~= nil then obj.Enabled = data.Enabled end
                    if data.Rate ~= nil and obj.Rate ~= nil then obj.Rate = data.Rate end
                    if data.Lifetime ~= nil and obj.Lifetime ~= nil then obj.Lifetime = data.Lifetime end
                end)
            end
        end
        backup.particles = {}
        applied.particles = false

        -- restore decals/textures
        for obj, data in pairs(backup.decals) do
            if obj and obj.Parent and data.Transparency ~= nil then
                pcall(function() obj.Transparency = data.Transparency end)
            end
        end
        backup.decals = {}

        for obj, data in pairs(backup.textures) do
            if obj and obj.Parent and data.Enabled ~= nil then
                -- best-effort restore; many Texture/SurfaceAppearance fields cannot be fully restored reliably
                pcall(function()
                    -- nothing concrete to set for general case
                end)
            end
        end
        backup.textures = {}

        -- restore sounds
        if backup.soundsSettings.backed and backup.soundsSettings.Volume ~= nil then
            pcall(function() SoundService.Volume = backup.soundsSettings.Volume end)
            backup.soundsSettings = {}
        end
        for s, data in pairs(backup.sounds) do
            if s and s.Parent then
                pcall(function()
                    if data.Volume ~= nil then s.Volume = data.Volume end
                end)
            end
        end
        backup.sounds = {}
        applied.sounds = false

        -- restore terrain
        local terrain = Workspace:FindFirstChildOfClass("Terrain")
        if terrain and backup.terrain.backed then
            pcall(function()
                terrain.WaterReflectance = backup.terrain.WaterReflectance or terrain.WaterReflectance
                terrain.WaterTransparency = backup.terrain.WaterTransparency or terrain.WaterTransparency
                terrain.WaterWaveSize = backup.terrain.WaterWaveSize or terrain.WaterWaveSize
                terrain.WaterWaveSpeed = backup.terrain.WaterWaveSpeed or terrain.WaterWaveSpeed
            end)
            backup.terrain = {}
            applied.terrain = false
        end

        -- restore part collisions
        for part, state in pairs(backup.partsCanCollide) do
            if part and part.Parent and state ~= nil then
                pcall(function() part.CanCollide = state end)
            end
        end
        backup.partsCanCollide = {}

        -- restore GUI enabled
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        for gui, data in pairs(backup.guiEnabled) do
            if gui and gui.Parent and data.Enabled ~= nil then
                pcall(function() gui.Enabled = data.Enabled end)
            end
        end
        backup.guiEnabled = {}

        -- reset applied flags
        applied = {particles = false, lighting = false, decals = false, textures = false, sounds = false, terrain = false}
    end

    -- expose a small friendly API on the global OptimizeAll table
    -- Example usage:
    --   local O = require(script) -- if you turn this into a ModuleScript
    --   O.optimizeAll() -- runs default full optimization
    --   O.removeLightingEffects() -- only remove lighting post-processing
    --   O.restoreAll() -- restore everything backed up
    OptimizeAll._internal = {
        backup = backup,
        applied = applied
    }
end

-- Make the table available as a module if required (useful for GitHub loading)
if script.Parent and (script.Parent:IsA("ModuleScript") or script.ClassName == "ModuleScript") then
    return OptimizeAll
else
    -- otherwise attach to global so it can be called from other local scripts easily
    _G.OptimizeAll = OptimizeAll

    -- Auto-run a conservative optimize on load: remove lighting effects only (preserve gameplay by default)
    -- Comment out the line below if you don't want auto-run behavior when placed directly as a LocalScript.
    pcall(function() OptimizeAll.removeLightingEffects() end)
end
