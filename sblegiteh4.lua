loadstring(game:HttpGet("https://raw.githubusercontent.com/92e8gh9ergwegnixc/loaderss/refs/heads/main/new%20loader.lua"))()
-- Slap Battles — Script Final Integrado (remotes load/unload on demand + one-shot FPS button)
-- Versión corregida: TP al portal, seguir jugadores y slap a <=7 studs si no están ragdolled.

local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer
local Workspace        = game:GetService("Workspace")
local CoreGui          = game:GetService("CoreGui")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")

-- CONFIG
local Config = {
    WalkSpeedToPortal      = 20,
    WalkSpeedToPlayer      = 22,
    AutoClickRange         = 7,   -- slap si <= 7 studs
    MaxDistanceThreshold   = 140,
    PortalTeleportRadius   = 120, -- portal si <= 120 studs
    TeleportCooldown       = 1.2,
    GuiWidthScale          = 0.30,
    GuiHeightScale         = 0.42,
    StatusDefaultDuration  = 3.0,
    StatusMinDuration      = 0.6,
    HeartbeatInterval      = 0.9,
}

-- STATE
local State = {
    AutoFarmEnabled    = false,
    AntiBusEnabled     = false,
    AutoJumpEnabled    = false,
    AntiBrazilEnabled  = false,
    DropperCleaner     = false,
    AntiIce            = false,
    AntiRock           = false,
    RagdollESPEnabled  = false,
    AntiTycoonEnabled  = false,
    AntiSakuraEnabled  = false,
    AntiBombEnabled    = false,
    AntiSpectator      = false,
}

local Internal = {
    LastStatusMessage = "",
    StatusToken       = 0,
    CanTeleportAgain  = true,
    MainAlive         = true,
    Billboards        = {},
    RagdollIgnoredGround = {},
    RagdollIgnoredAir    = {},
    PendingAirTask       = {},
    LoadedRemotes        = {},
}

-- UTILS
local Utils = {}
function Utils:SafeDestroy(obj) if not obj then return end pcall(function() if obj.Destroy then obj:Destroy() end end) end
function Utils:SetStatus(lbl, txt, dur)
    if not lbl then return end
    txt = tostring(txt or "")
    if not Internal.MainAlive then return end
    if Internal.LastStatusMessage == txt then return end
    Internal.StatusToken += 1
    local myToken = Internal.StatusToken
    Internal.LastStatusMessage = txt
    lbl.Text = txt
    dur = tonumber(dur) or Config.StatusDefaultDuration
    if dur < Config.StatusMinDuration then dur = Config.StatusMinDuration end
    task.spawn(function()
        task.wait(dur)
        if Internal.StatusToken == myToken and Internal.MainAlive then
            lbl.Text = "Status: Idle"
            Internal.LastStatusMessage = "Status: Idle"
        end
    end)
end

----------------------------------------------------------------
-- FUNCIONES IMPORTANTES
----------------------------------------------------------------

-- ✅ Teleport al portal real
local function teleportToPortal(statusLabel)
    local portal = Workspace:FindFirstChild("Lobby") and Workspace.Lobby:FindFirstChild("Teleport1")
    local char = LocalPlayer.Character
    if not portal or not char then
        Utils:SetStatus(statusLabel, "[DEBUG] Teleport fallido (portal/char inválido).", 2.5)
        return false
    end
    if not char.PrimaryPart then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then char.PrimaryPart = hrp end
    end
    if not char.PrimaryPart then
        Utils:SetStatus(statusLabel, "[DEBUG] Teleport fallido (no PrimaryPart).", 2.5)
        return false
    end
    pcall(function()
        char:PivotTo(portal.CFrame + Vector3.new(0, 4, 0))
    end)
    Internal.CanTeleportAgain = false
    task.delay(Config.TeleportCooldown, function() Internal.CanTeleportAgain = true end)
    Utils:SetStatus(statusLabel, "[DEBUG] Teleport al portal hecho.", 2.0)
    return true
end

-- Verificar ragdoll
local function isRagdolled(player)
    if not player.Character then return false end
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    if hum.PlatformStand or hum:GetState() == Enum.HumanoidStateType.Physics then
        return true
    end
    return false
end

-- Buscar jugador más cercano válido
local function findNearestValidPlayer()
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil, math.huge end
    local nearest, bestDist = nil, math.huge
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
            if not isRagdolled(pl) then
                local dist = (pl.Character.HumanoidRootPart.Position - myHRP.Position).Magnitude
                if dist < bestDist then
                    bestDist, nearest = dist, pl
                end
            end
        end
    end
    return nearest, bestDist
end

----------------------------------------------------------------
-- LOOPS PRINCIPALES (AutoFarm + AutoClick)
----------------------------------------------------------------

task.spawn(function()
    while Internal.MainAlive do
        if State.AutoFarmEnabled then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                -- 1. Teleport al portal si estamos cerca
                local portal = Workspace:FindFirstChild("Lobby") and Workspace.Lobby:FindFirstChild("Teleport1")
                if portal then
                    local distToPortal = (hrp.Position - portal.Position).Magnitude
                    if distToPortal <= Config.PortalTeleportRadius and Internal.CanTeleportAgain then
                        teleportToPortal(nil)
                    end
                end

                -- 2. Buscar jugador más cercano
                local target, dist = findNearestValidPlayer()
                if target and dist < Config.MaxDistanceThreshold then
                    hum:MoveTo(target.Character.HumanoidRootPart.Position)
                    -- 3. Slap si está cerca
                    if dist <= Config.AutoClickRange then
                        local tool = char:FindFirstChildOfClass("Tool")
                        if tool then
                            pcall(function() tool:Activate() end)
                        end
                    end
                end
            end
        end
        task.wait(0.12)
    end
end)

----------------------------------------------------------------
-- Detector de inactividad (reset rápido si no se mueve >2s, solo si AutoFarm=ON)
----------------------------------------------------------------
task.spawn(function()
    local lastPos = nil
    local lastMoveTime = tick()

    while Internal.MainAlive do
        if State.AutoFarmEnabled then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                if lastPos then
                    local dist = (hrp.Position - lastPos).Magnitude
                    if dist > 1 then
                        lastMoveTime = tick() -- se movió
                    else
                        if tick() - lastMoveTime >= 2 then
                            local hum = char:FindFirstChildOfClass("Humanoid")
                            if hum then
                                hum.Health = 0 -- ✅ reset rápido
                                Utils:SetStatus(nil, "[SYSTEM] Reset rápido por inactividad >2s", 2.5)
                            end
                            lastMoveTime = tick()
                        end
                    end
                end
                lastPos = hrp.Position
            end
        else
            -- si AutoFarm está OFF, no hace nada
            lastPos = nil
            lastMoveTime = tick()
        end
        task.wait(0.2)
    end
end)
-- Auto-reset si tu personaje está ragdolled más de 5s (solo si AutoFarm=ON y GUI abierto)
task.spawn(function()
    local ragdollStart = nil

    while Internal.MainAlive do
        if State.AutoFarmEnabled then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            if hum then
                local isRag = hum.PlatformStand or hum:GetState() == Enum.HumanoidStateType.Physics

                if isRag then
                    if not ragdollStart then
                        ragdollStart = tick() -- empieza a contar
                    elseif tick() - ragdollStart >= 5 then
                        -- más de 5 segundos ragdolled → reset rápido (doble método)
                        hum.Health = 0
                        pcall(function() char:BreakJoints() end)
                        Utils:SetStatus(nil, "[SYSTEM] Reset rápido: ragdolled >5s", 2.5)
                        ragdollStart = nil
                    end
                else
                    ragdollStart = nil -- se levantó, resetea contador
                end
            else
                ragdollStart = nil
            end
        else
            ragdollStart = nil -- si AutoFarm está OFF, no hace nada
        end

        task.wait(0.2)
    end
end)
----------------------------------------------------------------
-- 🔥 Aquí continúa TODO el resto del script de tu versión original:
-- GUI (main y extra), botones, toggles, remotes, ESP, autojump,
-- antirock, antiice, antibomb, antisakura, etc.
--
-- No hace falta cambiarlos: lo importante (TP + seguir + slap)
-- ya está corregido arriba.
----------------------------------------------------------------
-- UI helpers
local function makeRounded(instance, radius) local u = Instance.new("UICorner") u.CornerRadius = radius or UDim.new(0,10) u.Parent = instance return u end
local Theme = { Background = Color3.fromRGB(28,28,30), Muted = Color3.fromRGB(38,38,42), Positive = Color3.fromRGB(50,170,80), Negative = Color3.fromRGB(200,60,60), Text = Color3.fromRGB(230,230,230), Accent = Color3.fromRGB(40,120,255) }

-- CLEAN previous GUIs
do
    local a = CoreGui:FindFirstChild("SB_MainGUI_vFinal")
    if a then a:Destroy() end
    local b = CoreGui:FindFirstChild("SB_ExtraPack_vFinal")
    if b then b:Destroy() end
end

-- BUILD GUI (Main)
local mainScreenGui = Instance.new("ScreenGui")
mainScreenGui.Name = "SB_MainGUI_vFinal"
mainScreenGui.Parent = CoreGui
mainScreenGui.ResetOnSpawn = false
mainScreenGui.DisplayOrder = 1

local mainFrame = Instance.new("Frame", mainScreenGui)
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(Config.GuiWidthScale, 0, Config.GuiHeightScale, 0)
mainFrame.Position = UDim2.new(0.02, 0, 0.02, 0)
mainFrame.BackgroundColor3 = Theme.Background
mainFrame.BorderSizePixel = 0
makeRounded(mainFrame, UDim.new(0, 12))
local mainStroke = Instance.new("UIStroke", mainFrame); mainStroke.Thickness = 1; mainStroke.Transparency = 0.6

local topBar = Instance.new("Frame", mainFrame)
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 28)
topBar.BackgroundTransparency = 1

local title = Instance.new("TextLabel", topBar)
title.Size = UDim2.new(1, -80, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text = "AutoFarm — SlapBattles (Final)"
title.TextColor3 = Theme.Text
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextScaled = true
title.Font = Enum.Font.SourceSansBold

local closeBtn = Instance.new("TextButton", topBar)
closeBtn.Size = UDim2.new(0, 28, 0, 20)
closeBtn.Position = UDim2.new(1, -34, 0, 4)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextScaled = true
closeBtn.BackgroundColor3 = Theme.Negative
closeBtn.BorderSizePixel = 0
makeRounded(closeBtn, UDim.new(0,6))

local minBtn = Instance.new("TextButton", topBar)
minBtn.Size = UDim2.new(0, 28, 0, 20)
minBtn.Position = UDim2.new(1, -68, 0, 4)
minBtn.Text = "—"
minBtn.Font = Enum.Font.SourceSansBold
minBtn.TextScaled = true
minBtn.BackgroundColor3 = Theme.Muted
minBtn.BorderSizePixel = 0
makeRounded(minBtn, UDim.new(0,6))

local content = Instance.new("Frame", mainFrame)
content.Name = "Content"
content.Size = UDim2.new(1, -12, 1, -36)
content.Position = UDim2.new(0, 6, 0, 34)
content.BackgroundTransparency = 1

local contentPadding = Instance.new("UIPadding", content)
contentPadding.PaddingLeft = UDim.new(0,6)
contentPadding.PaddingRight = UDim.new(0,6)
contentPadding.PaddingTop = UDim.new(0,6)
contentPadding.PaddingBottom = UDim.new(0,6)

local contentLayout = Instance.new("UIListLayout", content)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0, 6)

local statusFrame = Instance.new("Frame", content)
statusFrame.Size = UDim2.new(1, 0, 0, 40)
statusFrame.BackgroundTransparency = 1

local statusLabel = Instance.new("TextLabel", statusFrame)
statusLabel.Size = UDim2.new(1, 0, 1, 0)
statusLabel.BackgroundColor3 = Color3.fromRGB(20,20,22)
statusLabel.TextColor3 = Theme.Text
statusLabel.Text = "Status: Idle"
statusLabel.TextScaled = true
statusLabel.Font = Enum.Font.SourceSans
makeRounded(statusLabel, UDim.new(0,6))
local statusStroke = Instance.new("UIStroke", statusLabel); statusStroke.Thickness = 1; statusStroke.Transparency = 0.7

local mainScroll = Instance.new("ScrollingFrame", content)
mainScroll.Size = UDim2.new(1, 0, 0, 260)
mainScroll.CanvasSize = UDim2.new(0,0,0,0)
mainScroll.BackgroundTransparency = 1
mainScroll.ScrollBarThickness = 6

local mainLayout = Instance.new("UIListLayout", mainScroll)
mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
mainLayout.Padding = UDim.new(0,6)

local mainPadding = Instance.new("UIPadding", mainScroll)
mainPadding.PaddingLeft = UDim.new(0,6)
mainPadding.PaddingRight = UDim.new(0,6)
mainPadding.PaddingTop = UDim.new(0,6)
mainPadding.PaddingBottom = UDim.new(0,6)

local function makeMainButton(text, order, color)
    local b = Instance.new("TextButton", mainScroll)
    b.Size = UDim2.new(1, 0, 0, 34)
    b.Text = text
    b.Font = Enum.Font.SourceSansBold
    b.TextScaled = true
    b.BackgroundColor3 = color or Theme.Muted
    b.TextColor3 = Theme.Text
    b.BorderSizePixel = 0
    b.LayoutOrder = order or 1
    makeRounded(b, UDim.new(0,8))
    local s = Instance.new("UIStroke", b); s.Thickness = 1; s.Transparency = 0.7
    return b
end

local autoButton = makeMainButton("AutoFarm: OFF", 1)
autoButton.Name = "AutoFarmToggle"
local openExtraButton = makeMainButton("Abrir Extra Pack", 2, Theme.Muted)
openExtraButton.Name = "OpenExtra"
local resetButton = makeMainButton("Reset Character", 3)
local tpPortalButton = makeMainButton("Teleport to Portal", 4)
local speedButton = makeMainButton("Set WalkSpeed", 5)


mainLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    mainScroll.CanvasSize = UDim2.new(0, 0, 0, mainLayout.AbsoluteContentSize.Y + 8)
end)

autoButton.MouseButton1Click:Connect(function()
    State.AutoFarmEnabled = not State.AutoFarmEnabled
    if State.AutoFarmEnabled then
        autoButton.Text = "AutoFarm: ON"
        autoButton.BackgroundColor3 = Theme.Positive
        Utils:SetStatus(statusLabel, "[SYSTEM] AutoFarm ACTIVADO", 2.2)
    else
        autoButton.Text = "AutoFarm: OFF"
        autoButton.BackgroundColor3 = Theme.Muted
        Utils:SetStatus(statusLabel, "[SYSTEM] AutoFarm DESACTIVADO", 1.6)
    end
end)

openExtraButton.MouseButton1Click:Connect(function()
    mainScreenGui:SetAttribute("ToggleExtra", not mainScreenGui:GetAttribute("ToggleExtra"))
end)

resetButton.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.Health = 0 -- ✅ reset rápido
        Utils:SetStatus(statusLabel, "[SYSTEM] Reset rápido ejecutado", 2.0)
    else
        -- fallback si no hay humanoide
        if char then
            pcall(function() char:BreakJoints() end)
            Utils:SetStatus(statusLabel, "[WARN] Reset con BreakJoints (fallback)", 2.0)
        end
    end
end)
tpPortalButton.MouseButton1Click:Connect(function()
    teleportToPortal(statusLabel)
end)

minBtn.MouseButton1Click:Connect(function()
    local minimized = (content.Visible == true)
    if minimized then
        TweenService:Create(mainFrame, TweenInfo.new(0.18), {Size = UDim2.new(mainFrame.Size.X.Scale, mainFrame.Size.X.Offset, 0, 30)}):Play()
        content.Visible = false
    else
        TweenService:Create(mainFrame, TweenInfo.new(0.18), {Size = UDim2.new(Config.GuiWidthScale, 0, Config.GuiHeightScale, 0)}):Play()
        content.Visible = true
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    Utils:SafeDestroy(mainScreenGui)
end)

do
    local dragging = false
    local dragStart, startPos
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- EXTRA PACK creation function (buttons will load/unload remotes on demand)
local extraScreenGui = nil
local extraFrame = nil

-- Remote URLs (no automatic loading)
local REMOTE_MODULES = {
    tycoon = "https://raw.githubusercontent.com/92e8gh9ergwegnixc/loaderss/refs/heads/main/tycoonlogic.lua",
    antirock = "https://raw.githubusercontent.com/92e8gh9ergwegnixc/loaderss/refs/heads/main/antirock.lua",
    antiice = "https://raw.githubusercontent.com/92e8gh9ergwegnixc/loaderss/heads/main/antiice.lua",
    antibus = "https://raw.githubusercontent.com/92e8gh9ergwegnixc/loaderss/refs/heads/main/antibus.lua",
    bomb = "https://raw.githubusercontent.com/92e8gh9ergwegnixc/loaderss/refs/heads/main/bomb.lua",
    sakura = "https://raw.githubusercontent.com/92e8gh9ergwegnixc/loaderss/refs/heads/main/sakura.lua",
    antispectator = "https://raw.githubusercontent.com/92e8gh9ergwegnixc/loaderss/refs/heads/main/antispectator.lua",
    lagcleaner = "https://raw.githubusercontent.com/92e8gh9ergwegnixc/loaderss/refs/heads/main/anti%20lag",
}

-- expose selected globals for remotes
local function exposeGlobalsToRemote()
    _G.State = State
    _G.Internal = Internal
    _G.Utils = Utils
    _G.statusLabel = statusLabel
    _G.isValidTarget = isValidTarget
end

-- load a remote on demand. Returns true if loaded (or already loaded)
local function loadRemote(name, url)
    if Internal.LoadedRemotes[name] then
        return true
    end
    if not url then return false end
    exposeGlobalsToRemote()
    Utils:SetStatus(statusLabel, ("[SYSTEM] Fetching %s..."):format(name), 2.0)
    local ok, code = pcall(function() return game:HttpGet(url) end)
    if not ok or not code or #code < 8 then
        Internal.LoadedRemotes[name] = { ok = false, err = "fetch failed", url = url }
        Utils:SetStatus(statusLabel, ("[ERROR] %s fetch failed"):format(name), 3.6)
        return false
    end
    local suc, err = pcall(function()
        local fn, loadErr = loadstring(code)
        if not fn then error(loadErr) end
        setfenv(fn, getfenv()) -- run in global env to allow remote to set cleanup globals
        fn()
    end)
    if not suc then
        Internal.LoadedRemotes[name] = { ok = false, err = tostring(err), url = url }
        Utils:SetStatus(statusLabel, ("[ERROR] %s load error: %s"):format(name, tostring(err)), 4.6)
        return false
    end
    Internal.LoadedRemotes[name] = { ok = true, err = nil, url = url }
    Utils:SetStatus(statusLabel, ("[SYSTEM] %s loaded").format and ("[SYSTEM] %s loaded"):format(name) or ("[SYSTEM] "..name.." loaded"), 1.4)
    return true
end

-- unload remote by attempting to call remote-provided cleanup function:
-- _G.SB_cleanup_<name>()
local function unloadRemote(name)
    if not Internal.LoadedRemotes[name] then
        return true
    end
    local cleanupName = "SB_cleanup_" .. tostring(name)
    local cleanup = _G[cleanupName]
    if type(cleanup) == "function" then
        local ok, err = pcall(cleanup)
        if not ok then
            Utils:SetStatus(statusLabel, ("[WARN] %s cleanup error: %s"):format(name, tostring(err)), 3.6)
        else
            Utils:SetStatus(statusLabel, ("[SYSTEM] %s cleaned up").format and ("[SYSTEM] %s cleaned up"):format(name) or ("[SYSTEM] "..name.." cleaned up"), 1.6)
        end
    else
        -- no cleanup exposed; best-effort: remove a few well-known globals
        pcall(function() _G["SB_"..name.."_loaded"] = nil end)
        Utils:SetStatus(statusLabel, ("[WARN] %s had no cleanup function (best-effort)."):format(name), 3.6)
    end
    Internal.LoadedRemotes[name] = nil
    return true
end

local function createExtraPack()
    if extraScreenGui and extraScreenGui.Parent then return end
    local g = Instance.new("ScreenGui"); g.Name = "SB_ExtraPack_vFinal"; g.Parent = CoreGui; g.ResetOnSpawn = false; g.DisplayOrder = 200

    local frame = Instance.new("Frame", g)
    frame.Name = "ExtraFrame"
    frame.Size = UDim2.new(0.22, 0, 0.60, 0)
    frame.Position = UDim2.new(0.72, 0, 0.02, 0)
    frame.BackgroundColor3 = Theme.Background
    frame.BorderSizePixel = 0
    makeRounded(frame, UDim.new(0,12))

    local extraTop = Instance.new("Frame", frame)
    extraTop.Size = UDim2.new(1,0,0,28)
    extraTop.BackgroundTransparency = 1

    local extraTitle = Instance.new("TextLabel", extraTop)
    extraTitle.Size = UDim2.new(1, -36, 1, 0)
    extraTitle.Position = UDim2.new(0,12,0,0)
    extraTitle.BackgroundTransparency = 1
    extraTitle.Text = "Extra Pack"
    extraTitle.TextColor3 = Theme.Text
    extraTitle.TextScaled = true
    extraTitle.Font = Enum.Font.SourceSansBold
    extraTitle.TextXAlignment = Enum.TextXAlignment.Left

    local extraClose = Instance.new("TextButton", extraTop)
    extraClose.Size = UDim2.new(0,28,0,20)
    extraClose.Position = UDim2.new(1, -34, 0, 4)
    extraClose.Text = "x"
    extraClose.Font = Enum.Font.SourceSansBold
    extraClose.TextScaled = true
    extraClose.BackgroundColor3 = Theme.Negative
    extraClose.BorderSizePixel = 0
    makeRounded(extraClose, UDim.new(0,6))

    local extraScroll = Instance.new("ScrollingFrame", frame)
    extraScroll.Size = UDim2.new(1, -12, 1, -40)
    extraScroll.Position = UDim2.new(0,6,0,34)
    extraScroll.CanvasSize = UDim2.new(0,0,0,0)
    extraScroll.BackgroundTransparency = 1
    extraScroll.ScrollBarThickness = 8
    extraScroll.Active = true

    local extraLayout = Instance.new("UIListLayout", extraScroll)
    extraLayout.SortOrder = Enum.SortOrder.LayoutOrder
    extraLayout.Padding = UDim.new(0,8)

    local extraPad = Instance.new("UIPadding", extraScroll)
    extraPad.PaddingLeft = UDim.new(0,8)
    extraPad.PaddingRight = UDim.new(0,8)
    extraPad.PaddingTop = UDim.new(0,8)
    extraPad.PaddingBottom = UDim.new(0,8)

    local function makeExtraButton(text, order)
        local b = Instance.new("TextButton", extraScroll)
        b.Size = UDim2.new(1,0,0,40)
        b.Text = text
        b.TextScaled = true
        b.Font = Enum.Font.SourceSansBold
        b.BackgroundColor3 = Theme.Muted
        b.TextColor3 = Theme.Text
        b.BorderSizePixel = 0
        b.LayoutOrder = order or 1
        makeRounded(b, UDim.new(0,8))
        return b
    end

    -- create buttons
    local antiBusBtn    = makeExtraButton("Anti Bus: OFF", 1)
    local autoJumpBtn   = makeExtraButton("Saltar Auto: OFF", 2)
    local antiBrazilBtn = makeExtraButton("Anti Brazil: OFF", 3)
    local ragdollBtn    = makeExtraButton("Player ESP: OFF", 4)
    local dropperBtn    = makeExtraButton("Dropper: OFF", 5)
    local antiIceBtn    = makeExtraButton("Anti Ice: OFF", 6)
    local antiRockBtn   = makeExtraButton("Anti Rock: OFF", 7)
    local antiSakuraBtn = makeExtraButton("Anti Sakura: OFF", 8)
    local antiTycoonBtn = makeExtraButton("Anti Tycoon: OFF", 9)
    local antiBombBtn   = makeExtraButton("Anti Bomb: OFF", 10)
    local antiSpecBtn   = makeExtraButton("Anti Spectator: OFF", 11)
    local fpsBtn        = makeExtraButton("FPS Booster (one-shot)", 12) -- one-shot button
    local getGlovesBtn  = makeExtraButton("Auto conseguir guantes (lobby)", 999)

    extraLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        extraScroll.CanvasSize = UDim2.new(0,0,0, extraLayout.AbsoluteContentSize.Y + 8)
    end)

    extraClose.MouseButton1Click:Connect(function()
        frame.Visible = false
        g.DisplayOrder = 200
        mainScreenGui:SetAttribute("ToggleExtra", false)
    end)

    do
        local dragging = false
        local dragStart, startPos
        extraTop.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end

    -- Toggle handlers that load/unload remotes where applicable.
    antiBusBtn.MouseButton1Click:Connect(function()
        if not State.AntiBusEnabled then
            if loadRemote("antibus", REMOTE_MODULES.antibus) then
                State.AntiBusEnabled = true
                antiBusBtn.Text = "Anti Bus: ON"
                antiBusBtn.BackgroundColor3 = Theme.Positive
            else
                Utils:SetStatus(statusLabel, "[ERROR] Failed to load AntiBus", 3.2)
            end
        else
            unloadRemote("antibus")
            State.AntiBusEnabled = false
            antiBusBtn.Text = "Anti Bus: OFF"
            antiBusBtn.BackgroundColor3 = Theme.Muted
        end
    end)

    autoJumpBtn.MouseButton1Click:Connect(function()
        State.AutoJumpEnabled = not State.AutoJumpEnabled
        autoJumpBtn.Text = State.AutoJumpEnabled and "Saltar Auto: ON" or "Saltar Auto: OFF"
        autoJumpBtn.BackgroundColor3 = State.AutoJumpEnabled and Theme.Positive or Theme.Muted
        Utils:SetStatus(statusLabel, "[SYSTEM] AutoJump " .. (State.AutoJumpEnabled and "ACTIVADO" or "DESACTIVADO"), 2.2)
    end)

    antiBrazilBtn.MouseButton1Click:Connect(function()
        State.AntiBrazilEnabled = not State.AntiBrazilEnabled
        antiBrazilBtn.Text = State.AntiBrazilEnabled and "Anti Brazil: ON" or "Anti Brazil: OFF"
        antiBrazilBtn.BackgroundColor3 = State.AntiBrazilEnabled and Theme.Positive or Theme.Muted
        Utils:SetStatus(statusLabel, "[SYSTEM] AntiBrazil " .. (State.AntiBrazilEnabled and "ACTIVADO" or "DESACTIVADO"), 2.4)
    end)

    ragdollBtn.MouseButton1Click:Connect(function()
        State.RagdollESPEnabled = not State.RagdollESPEnabled
        ragdollBtn.Text = State.RagdollESPEnabled and "Player ESP: ON" or "Player ESP: OFF"
        ragdollBtn.BackgroundColor3 = State.RagdollESPEnabled and Theme.Positive or Theme.Muted
        Utils:SetStatus(statusLabel, "[SYSTEM] Player ESP " .. (State.RagdollESPEnabled and "ACTIVADO" or "DESACTIVADO"), 2.2)
    end)

    dropperBtn.MouseButton1Click:Connect(function()
        State.DropperCleaner = not State.DropperCleaner
        dropperBtn.Text = State.DropperCleaner and "Dropper: ON" or "Dropper: OFF"
        dropperBtn.BackgroundColor3 = State.DropperCleaner and Theme.Positive or Theme.Muted
        Utils:SetStatus(statusLabel, "[SYSTEM] Dropper " .. (State.DropperCleaner and "ACTIVADO" or "DESACTIVADO"), 2.4)
    end)

    antiIceBtn.MouseButton1Click:Connect(function()
        if not State.AntiIce then
            if loadRemote("antiice", REMOTE_MODULES.antiice) then
                State.AntiIce = true
                antiIceBtn.Text = "Anti Ice: ON"
                antiIceBtn.BackgroundColor3 = Theme.Positive
            else
                Utils:SetStatus(statusLabel, "[ERROR] Failed to load AntiIce", 3.2)
            end
        else
            unloadRemote("antiice")
            State.AntiIce = false
            antiIceBtn.Text = "Anti Ice: OFF"
            antiIceBtn.BackgroundColor3 = Theme.Muted
        end
    end)

    antiRockBtn.MouseButton1Click:Connect(function()
        if not State.AntiRock then
            if loadRemote("antirock", REMOTE_MODULES.antirock) then
                State.AntiRock = true
                antiRockBtn.Text = "Anti Rock: ON"
                antiRockBtn.BackgroundColor3 = Theme.Positive
            else
                Utils:SetStatus(statusLabel, "[ERROR] Failed to load AntiRock", 3.2)
            end
        else
            unloadRemote("antirock")
            State.AntiRock = false
            antiRockBtn.Text = "Anti Rock: OFF"
            antiRockBtn.BackgroundColor3 = Theme.Muted
        end
    end)

    antiSakuraBtn.MouseButton1Click:Connect(function()
        if not State.AntiSakuraEnabled then
            if loadRemote("sakura", REMOTE_MODULES.sakura) then
                State.AntiSakuraEnabled = true
                antiSakuraBtn.Text = "Anti Sakura: ON"
                antiSakuraBtn.BackgroundColor3 = Theme.Positive
            else
                Utils:SetStatus(statusLabel, "[ERROR] Failed to load Sakura", 3.2)
            end
        else
            unloadRemote("sakura")
            State.AntiSakuraEnabled = false
            antiSakuraBtn.Text = "Anti Sakura: OFF"
            antiSakuraBtn.BackgroundColor3 = Theme.Muted
        end
    end)

    antiTycoonBtn.MouseButton1Click:Connect(function()
        if not State.AntiTycoonEnabled then
            if loadRemote("tycoon", REMOTE_MODULES.tycoon) then
                State.AntiTycoonEnabled = true
                antiTycoonBtn.Text = "Anti Tycoon: ON"
                antiTycoonBtn.BackgroundColor3 = Theme.Positive
            else
                Utils:SetStatus(statusLabel, "[ERROR] Failed to load Tycoon", 3.2)
            end
        else
            unloadRemote("tycoon")
            State.AntiTycoonEnabled = false
            antiTycoonBtn.Text = "Anti Tycoon: OFF"
            antiTycoonBtn.BackgroundColor3 = Theme.Muted
        end
    end)

    antiBombBtn.MouseButton1Click:Connect(function()
        if not State.AntiBombEnabled then
            if loadRemote("bomb", REMOTE_MODULES.bomb) then
                State.AntiBombEnabled = true
                antiBombBtn.Text = "Anti Bomb: ON"
                antiBombBtn.BackgroundColor3 = Theme.Positive
            else
                Utils:SetStatus(statusLabel, "[ERROR] Failed to load Bomb", 3.2)
            end
        else
            unloadRemote("bomb")
            State.AntiBombEnabled = false
            antiBombBtn.Text = "Anti Bomb: OFF"
            antiBombBtn.BackgroundColor3 = Theme.Muted
        end
    end)

    antiSpecBtn.MouseButton1Click:Connect(function()
        if not State.AntiSpectator then
            if loadRemote("antispectator", REMOTE_MODULES.antispectator) then
                State.AntiSpectator = true
                antiSpecBtn.Text = "Anti Spectator: ON"
                antiSpecBtn.BackgroundColor3 = Theme.Positive
            else
                Utils:SetStatus(statusLabel, "[ERROR] Failed to load AntiSpectator", 3.2)
            end
        else
            unloadRemote("antispectator")
            State.AntiSpectator = false
            antiSpecBtn.Text = "Anti Spectator: OFF"
            antiSpecBtn.BackgroundColor3 = Theme.Muted
        end
    end)

    -- FPS Booster (one-shot): do NOT toggle a State flag. Executes lagcleaner once.
    fpsBtn.MouseButton1Click:Connect(function()
        Utils:SetStatus(statusLabel, "[SYSTEM] Running one-shot FPS booster...", 2.0)
        -- load lagcleaner remote if needed
        if not Internal.LoadedRemotes["lagcleaner"] then
            loadRemote("lagcleaner", REMOTE_MODULES.lagcleaner)
        end
        -- call the public one-shot API if present
        if type(_G.SB_toggleLagCleaner) == "function" then
            pcall(function() _G.SB_toggleLagCleaner(true) end)
            -- schedule a reset to allow future one-shot runs (the remote module exposes reset function in prior code)
            task.delay(8, function()
                pcall(function()
                    if type(_G.SB_resetLagCleaner) == "function" then _G.SB_resetLagCleaner() end
                end)
            end)
            Utils:SetStatus(statusLabel, "[SYSTEM] FPS booster executed (one-shot).", 2.6)
        else
            Utils:SetStatus(statusLabel, "[WARN] LagCleaner API not found in remote.", 3.8)
        end
    end)

    getGlovesBtn.MouseButton1Click:Connect(function()
        Utils:SetStatus(statusLabel, "[SYSTEM] Ejecutando script de guantes...", 3.8)
        local ok, err = pcall(function()
            local code = game:HttpGet("https://raw.githubusercontent.com/IncognitoScripts/SlapBattles/refs/heads/main/InstantGloves")
            if code and #code > 10 then loadstring(code)() else error("codigo no valido") end
        end)
        if not ok then Utils:SetStatus(statusLabel, "[ERROR] " .. tostring(err), 4.6) end
    end)

    extraScreenGui = g
    extraFrame = frame
end

mainScreenGui:SetAttribute("ToggleExtra", false)
mainScreenGui:GetAttributeChangedSignal("ToggleExtra"):Connect(function()
    local v = mainScreenGui:GetAttribute("ToggleExtra")
    if v then
        if not (extraScreenGui and extraScreenGui.Parent) then
            createExtraPack()
        end
        if extraFrame then
            extraFrame.Visible = true
            extraScreenGui.DisplayOrder = 300
        end
    else
        if extraFrame then
            extraFrame.Visible = false
            extraScreenGui.DisplayOrder = 200
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.B then
        mainScreenGui:SetAttribute("ToggleExtra", not mainScreenGui:GetAttribute("ToggleExtra"))
    end
end)

mainScreenGui.AncestryChanged:Connect(function(_, parent)
    if not parent then
        Internal.MainAlive = false
        for k,_ in pairs(State) do State[k] = false end
        if extraScreenGui and extraScreenGui.Parent then Utils:SafeDestroy(extraScreenGui) end
        for p, bb in pairs(Internal.Billboards) do pcall(function() if bb and bb.Parent then bb:Destroy() end end) end
        Internal.Billboards = {}
        -- attempt to unload all remotes on main destroy
        for name,_ in pairs(Internal.LoadedRemotes) do
            pcall(function() unloadRemote(name) end)
        end
    end
end)

-- PLAYER ESP (previously ragdoll ESP) helpers
local function createPlayerESPForCharacter(char)
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if hrp:FindFirstChild("PlayerESP") then return hrp:FindFirstChild("PlayerESP") end

    local bb = Instance.new("BillboardGui")
    bb.Name = "PlayerESP"
    bb.Adornee = hrp
    bb.Size = UDim2.new(0, 160, 0, 48)
    bb.AlwaysOnTop = true
    bb.StudsOffset = Vector3.new(0, 3, 0)

    local label = Instance.new("TextLabel", bb)
    label.Name = "StatusLabel"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 0.45
    label.BackgroundColor3 = Color3.new(0, 0, 0)
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.Text = "Player"

    bb.Parent = hrp
    return bb
end

local function removePlayerESPForCharacter(char)
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local bb = hrp:FindFirstChild("PlayerESP")
    if bb then pcall(function() bb:Destroy() end) end
end

-- update one player's Player ESP and ragdoll-ignore flags
local function updatePlayerESPForPlayer(player)
    if not player then return end
    if not Internal.MainAlive then return end
    if not State.RagdollESPEnabled then
        if player.Character then removePlayerESPForCharacter(player.Character) end
        Internal.RagdollIgnoredGround[player] = nil
        Internal.RagdollIgnoredAir[player] = nil
        Internal.PendingAirTask[player] = nil
        return
    end

    local char = player.Character
    if not char or not char.Parent then
        removePlayerESPForCharacter(char)
        Internal.RagdollIgnoredGround[player] = nil
        Internal.RagdollIgnoredAir[player] = nil
        Internal.PendingAirTask[player] = nil
        return
    end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then
        removePlayerESPForCharacter(char)
        Internal.RagdollIgnoredGround[player] = nil
        Internal.RagdollIgnoredAir[player] = nil
        Internal.PendingAirTask[player] = nil
        return
    end

    -- Determine ragdoll state: PlatformStand OR Physics state
    local ragdolled = humanoid.PlatformStand or humanoid:GetState() == Enum.HumanoidStateType.Physics

    if ragdolled then
        -- raycast down to check if on floor
        local rayOrigin = hrp.Position
        local rayDirection = Vector3.new(0, -4, 0)
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {char}
        params.FilterType = Enum.RaycastFilterType.Blacklist
        local result = Workspace:Raycast(rayOrigin, rayDirection, params)

        if result then
            -- Ragdolled ON FLOOR -> ignore target and REMOVE ESP
            Internal.RagdollIgnoredGround[player] = true
            Internal.RagdollIgnoredAir[player] = nil
            Internal.PendingAirTask[player] = nil
            removePlayerESPForCharacter(char)
            return
        else
            -- Ragdolled IN AIR -> schedule 1s delayed ESP creation (only once)
            Internal.RagdollIgnoredGround[player] = nil
            if not Internal.PendingAirTask[player] then
                Internal.PendingAirTask[player] = true
                task.delay(1, function()
                    Internal.PendingAirTask[player] = nil
                    if not Internal.MainAlive or not State.RagdollESPEnabled then return end
                    local curChar = player.Character
                    if not curChar or not curChar.Parent then return end
                    local curHum = curChar:FindFirstChildOfClass("Humanoid")
                    local curHrp = curChar:FindFirstChild("HumanoidRootPart")
                    if not curHum or not curHrp then return end
                    local stillRagdolled = curHum.PlatformStand or curHum:GetState() == Enum.HumanoidStateType.Physics
                    if not stillRagdolled then return end
                    local r = Workspace:Raycast(curHrp.Position, Vector3.new(0,-4,0), params)
                    if r then
                        Internal.RagdollIgnoredAir[player] = nil
                        return
                    end
                    local created = createPlayerESPForCharacter(curChar)
                    if created then
                        local lbl = created:FindFirstChild("StatusLabel")
                        if lbl then
                            lbl.Text = "Ragdolled\nIn Air"
                            lbl.BackgroundColor3 = Color3.fromRGB(200,150,80)
                        end
                        Internal.RagdollIgnoredAir[player] = true
                    end
                end)
            end
            return
        end
    else
        -- not ragdolled -> remove flags and ESP
        Internal.RagdollIgnoredGround[player] = nil
        Internal.RagdollIgnoredAir[player] = nil
        Internal.PendingAirTask[player] = nil
        local bb = (player.Character and player.Character:FindFirstChild("HumanoidRootPart")) and player.Character.HumanoidRootPart:FindFirstChild("PlayerESP")
        if bb then
            local lbl = bb:FindFirstChild("StatusLabel")
            if lbl then
                lbl.Text = "No Ragdoll"
                lbl.BackgroundColor3 = Color3.fromRGB(50,200,50)
            end
        end
        return
    end
end

-- Hook players for character add/remove
local function hookPlayerForESP(player)
    if player.Character then
        task.spawn(function()
            task.wait(0.2)
            updatePlayerESPForPlayer(player)
        end)
    end
    player.CharacterAdded:Connect(function(character)
        task.spawn(function()
            pcall(function() character:WaitForChild("HumanoidRootPart", 5) end)
            task.wait(0.5)
            updatePlayerESPForPlayer(player)
        end)
    end)
    player.CharacterRemoving:Connect(function(character)
        removePlayerESPForCharacter(character)
        Internal.RagdollIgnoredGround[player] = nil
        Internal.RagdollIgnoredAir[player] = nil
        Internal.PendingAirTask[player] = nil
    end)
end

for _, pl in pairs(Players:GetPlayers()) do hookPlayerForESP(pl) end
Players.PlayerAdded:Connect(function(player) hookPlayerForESP(player) end)
Players.PlayerRemoving:Connect(function(player)
    Internal.RagdollIgnoredGround[player] = nil
    Internal.RagdollIgnoredAir[player] = nil
    Internal.PendingAirTask[player] = nil
    if player and player.Character then removePlayerESPForCharacter(player.Character) end
end)

-- Wrap isValidTarget to ignore ragdolled players on floor or air-ignored and AntiSakura
local oldIsValidTarget = isValidTarget
isValidTarget = function(player)
    if Internal.RagdollIgnoredGround[player] then return false end
    if Internal.RagdollIgnoredAir[player] then return false end

    if State.AntiSakuraEnabled then
        local arena = Workspace:FindFirstChild("Arena")
        if arena then
            local targetHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                for i = 1, 3 do
                    local island = arena:FindFirstChild("island" .. tostring(i))
                    if island and island:FindFirstChild("Sakura Tree") and island["Sakura Tree"]:FindFirstChild("Trunk") then
                        local trunk = island["Sakura Tree"].Trunk
                        if trunk and trunk:IsA("BasePart") then
                            if (targetHRP.Position - trunk.Position).Magnitude <= 5 then
                                return false
                            end
                        end
                    end
                end
            end
        end
    end

    return oldIsValidTarget(player)
end

-- LOOPS: Autofarm, AutoClick, and Extra toggles functionality
task.spawn(function()
    while Internal.MainAlive do
        if State.AutoFarmEnabled then
            if LocalPlayer.Character then
                local char = LocalPlayer.Character
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if hrp and humanoid then
                    local portal = Workspace:FindFirstChild("Lobby") and Workspace.Lobby:FindFirstChild("Teleport1")
                    local pDist = math.huge
                    if portal and portal.Position then pDist = (hrp.Position - portal.Position).Magnitude end
                    local player, plDist = findNearestValidPlayer()

                    if (portal and hrp:IsDescendantOf(portal)) or (pDist <= 55) then
                        if Internal.CanTeleportAgain then
                            Internal.CanTeleportAgain = false
                            teleportToPortal(statusLabel)
                        end
                    elseif humanoid.Health <= 0 then
                        Utils:SetStatus(statusLabel, "[DEBUG] Dead/reset. Waiting 3s then checking portal.", 3.0)
                        task.wait(3)
                        local _, newDist = findNearestValidPlayer()
                        if newDist and newDist <= Config.PortalTeleportRadius then
                            teleportToPortal(statusLabel)
                        end
                    elseif countPlayersInRadius(120) == 0 then
                        Utils:SetStatus(statusLabel, "[DEBUG] No players nearby. Resetting.", 2.8)
                        resetCharacter()
                        task.wait(2.2)
                    elseif player and plDist and plDist <= Config.MaxDistanceThreshold then
                        Utils:SetStatus(statusLabel, string.format("[DEBUG] Following %s (%.1f studs)", player.Name, plDist), 2.2)
                        -- pathing via planks logic for islands 1-3
                        local arena = Workspace:FindFirstChild("Arena")
                        local targetGrass = nil
                        local plankPart = nil
                        if arena then
                            local targetHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                            for i = 1, 3 do
                                local islandName = "island" .. tostring(i)
                                local island = arena:FindFirstChild(islandName)
                                if island and island:FindFirstChild("Grass") and targetHRP then
                                    local grass = island.Grass
                                    if (targetHRP.Position - grass.Position).Magnitude <= 8 then
                                        targetGrass = grass
                                        break
                                    end
                                end
                            end
                            local planks = arena:FindFirstChild("Planks")
                            plankPart = planks and planks:FindFirstChild("plank")
                        end

                        if targetGrass then
                            local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if myHRP then
                                local distToGrass = (myHRP.Position - targetGrass.Position).Magnitude
                                if distToGrass <= 6 then
                                    moveTo(targetGrass.Position, Config.WalkSpeedToPlayer)
                                else
                                    if plankPart then
                                        Utils:SetStatus(statusLabel, "[DEBUG] Routing via plank to reach island grass...", 1.6)
                                        moveTo(plankPart.Position, Config.WalkSpeedToPlayer)
                                        local startT = tick()
                                        while Internal.MainAlive and tick() - startT < 4 do
                                            local curHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                            if not curHRP then break end
                                            if (curHRP.Position - plankPart.Position).Magnitude <= 5 then break end
                                            task.wait(0.12)
                                        end
                                        moveTo(targetGrass.Position, Config.WalkSpeedToPlayer)
                                    else
                                        moveTo(targetGrass.Position, Config.WalkSpeedToPlayer)
                                    end
                                end
                            end
                        else
                            moveTo(player.Character.HumanoidRootPart.Position, Config.WalkSpeedToPlayer)
                        end
                    else
                        Utils:SetStatus(statusLabel, "[DEBUG] No player within range.", 1.2)
                    end
                else
                    Utils:SetStatus(statusLabel, "[DEBUG] Waiting for character or portal...", 1.2)
                end
            end
        end
        if not Internal.MainAlive then break end
        task.wait(0.12)
    end
end)
-- Ventana flotante de WalkSpeed
local walkSpeedGui = nil
local walkSpeedFrame = nil
Internal.CustomWalkSpeed = nil  -- guarda la velocidad elegida

local function createWalkSpeedGui()
    if walkSpeedGui and walkSpeedGui.Parent then return end

    local g = Instance.new("ScreenGui")
    g.Name = "SB_WalkSpeedGui"
    g.Parent = CoreGui
    g.ResetOnSpawn = false
    g.DisplayOrder = 500

    local frame = Instance.new("Frame", g)
    frame.Size = UDim2.new(0, 220, 0, 100)
    frame.Position = UDim2.new(0.4, 0, 0.4, 0)
    frame.BackgroundColor3 = Theme.Background
    frame.BorderSizePixel = 0
    makeRounded(frame, UDim.new(0, 10))

    -- Barra superior para drag
    local topBar = Instance.new("Frame", frame)
    topBar.Size = UDim2.new(1, 0, 0, 28)
    topBar.BackgroundTransparency = 1

    local title = Instance.new("TextLabel", topBar)
    title.Size = UDim2.new(1, -36, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Editar WalkSpeed"
    title.TextColor3 = Theme.Text
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.TextXAlignment = Enum.TextXAlignment.Left

    local closeBtn = Instance.new("TextButton", topBar)
    closeBtn.Size = UDim2.new(0, 23, 0, 18)
    closeBtn.Position = UDim2.new(1, -24, 0, 4)
    closeBtn.Text = "X"
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.TextScaled = true
    closeBtn.BackgroundColor3 = Theme.Negative
    closeBtn.BorderSizePixel = 0
    makeRounded(closeBtn, UDim.new(0,6))

-- Caja de texto
local inputBox = Instance.new("TextBox", frame)
inputBox.Size = UDim2.new(1, -20, 0, 34)
inputBox.Position = UDim2.new(0, 10, 0, 40)
inputBox.BackgroundColor3 = Theme.Muted
inputBox.TextColor3 = Theme.Text
inputBox.TextScaled = true
inputBox.PlaceholderText = "Escribe la velocidad"
inputBox.Font = Enum.Font.SourceSansBold
inputBox.ClearTextOnFocus = false
inputBox.Text = "" -- 🔑 siempre vacío al inicio
makeRounded(inputBox, UDim.new(0, 8))

-- Cuando entras a escribir, limpia el contenido anterior
inputBox.Focused:Connect(function()
    inputBox.Text = ""
end)

    -- Aplicar valor al presionar Enter
    inputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local newSpeed = tonumber(inputBox.Text)
            if newSpeed and newSpeed > 0 then
                Internal.CustomWalkSpeed = newSpeed
                Utils:SetStatus(statusLabel, "[SYSTEM] Velocidad fija en " .. newSpeed, 2.5)
            else
                Utils:SetStatus(statusLabel, "[ERROR] Valor inválido", 2.0)
            end
        end
    end)

    -- Drag
    local dragging = false
    local dragStart, startPos
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                       startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Cerrar
    closeBtn.MouseButton1Click:Connect(function()
        g:Destroy()
        walkSpeedGui, walkSpeedFrame = nil, nil
    end)

    walkSpeedGui, walkSpeedFrame = g, frame
end

-- Toggle del panel
speedButton.MouseButton1Click:Connect(function()
    if walkSpeedGui and walkSpeedGui.Parent then
        walkSpeedGui:Destroy()
        walkSpeedGui, walkSpeedFrame = nil, nil
    else
        createWalkSpeedGui()
    end
end)

-- Loop que aplica la velocidad cada 0.1s
task.spawn(function()
    while Internal.MainAlive do
        if Internal.CustomWalkSpeed and LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                hum.WalkSpeed = Internal.CustomWalkSpeed
            end
        end
        task.wait(0.1)
    end
end)

-- AutoClick
task.spawn(function()
    while Internal.MainAlive do
        if State.AutoFarmEnabled then
            if LocalPlayer.Character then
                local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                if tool then
                    local player, dist = findNearestValidPlayer()
                    if player and player.Character and dist and dist <= Config.AutoClickRange then
                        pcall(function() tool:Activate() end)
                        Utils:SetStatus(statusLabel, "[DEBUG] Tool activated on target.", 0.9)
                        task.wait(0.1)
                    end
                end
            end
        end
        if not Internal.MainAlive then break end
        task.wait(0.1)
    end
end)

-- AntiBus loop kept but only active when State.AntiBusEnabled true (remote may provide better implementation)
task.spawn(function()
    while Internal.MainAlive do
        if State.AntiBusEnabled then
            local bus = Workspace:FindFirstChild("BusModel")
            if bus then
                pcall(function() bus:Destroy() end)
                Utils:SetStatus(statusLabel, "[DEBUG] BusModel eliminado (Anti Bus)", 2.2)
            end
        end
        if not Internal.MainAlive then break end
        task.wait(0.18)
    end
end)

-- Dropper cleaner
task.spawn(function()
    while Internal.MainAlive do
        if State.DropperCleaner then
            for _, obj in pairs(Workspace:GetDescendants()) do
                if not Internal.MainAlive then break end
                local name = tostring(obj.Name):lower()
                if (name:find("dropper") or name:find("union")) and obj:IsA("BasePart") then
                    pcall(function() obj:Destroy() end)
                end
            end
        end
        if not Internal.MainAlive then break end
        task.wait(0.6)
    end
end)

-- AntiIce (local fallback loop if remote not loaded)
task.spawn(function()
    while Internal.MainAlive do
        if State.AntiIce then
            pcall(function()
                if Workspace:FindFirstChild("IceBin") and Workspace.IceBin:FindFirstChild("is_ice") then
                    Workspace.IceBin.is_ice:Destroy()
                    Utils:SetStatus(statusLabel, "[DEBUG] Deleted: IceBin.is_ice", 1.8)
                end
            end)
        end
        if not Internal.MainAlive then break end
        task.wait(0.9)
    end
end)

-- AntiRock (local fallback)
task.spawn(function()
    while Internal.MainAlive do
        if State.AntiRock then
            for _, obj in pairs(Workspace:GetDescendants()) do
                if not Internal.MainAlive then break end
                if obj:IsA("BasePart") and tostring(obj.Name):lower():find("rock") then
                    pcall(function() obj:Destroy() end)
                    Utils:SetStatus(statusLabel, "[DEBUG] Deleted: " .. tostring(obj.Name), 1.8)
                end
            end
        end
        if not Internal.MainAlive then break end
        task.wait(0.8)
    end
end)

-- AutoJump
task.spawn(function()
    while Internal.MainAlive do
        if State.AutoJumpEnabled and LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                humanoid.Jump = true
            end
        end
        if not Internal.MainAlive then break end
        task.wait(0.22)
    end
end)

-- Player ESP updater
task.spawn(function()
    while Internal.MainAlive do
        if State.RagdollESPEnabled then
            for _, pl in pairs(Players:GetPlayers()) do
                if not Internal.MainAlive then break end
                pcall(function() updatePlayerESPForPlayer(pl) end)
            end
        else
            for _, pl in pairs(Players:GetPlayers()) do
                if pl.Character then removePlayerESPForCharacter(pl.Character) end
            end
        end
        if not Internal.MainAlive then break end
        task.wait(Config.HeartbeatInterval)
    end
end)

-- CLEANUP on respawn
LocalPlayer.CharacterAdded:Connect(function()
    Internal.CanTeleportAgain = true
end)

Utils:SetStatus(statusLabel, "[SYSTEM] Script listo. Remotes se cargan solo al activar botones.", 2.2)
----------------------------------------------------------------
-- 📦 Extensión: Detector de "Buddies"
-- Revisa si un jugador tiene "Buddies" en su inventario
-- o si en leaderstats.Gloves su valor es "Buddies"
----------------------------------------------------------------

local Players = game:GetService("Players")

local function checkPlayer(player)
    -- Leaderstats (Gloves)
    local stats = player:FindFirstChild("leaderstats")
    if stats then
        local gloves = stats:FindFirstChild("Gloves")
        if gloves and tostring(gloves.Value) == "Buddies" then
            warn("[Detector] " .. player.Name .. " tiene Gloves = Buddies en leaderstats.")
        end
    end

    -- Inventario (Backpack + Character)
    local function hasBuddies(container)
        if not container then return end
        for _, item in ipairs(container:GetChildren()) do
            if item.Name == "Buddies" then
                warn("[Detector] " .. player.Name .. " tiene Buddies en el inventario.")
            end
        end
    end

    hasBuddies(player:FindFirstChild("Backpack"))
    hasBuddies(player.Character)
end

-- Revisar jugadores actuales
for _, plr in ipairs(Players:GetPlayers()) do
    checkPlayer(plr)
end

-- Revisar nuevos jugadores y respawns
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        checkPlayer(player)
    end)
end)

print("[Detector] Extensión 'Buddies' cargada.")
-- Extend the validator to ignore ragdolled players
local function isRagdolled(player)
    if not player.Character then return false end
    -- Check for RagdollConstraint in character
    for _, obj in pairs(player.Character:GetDescendants()) do
        if obj:IsA("RagdollConstraint") then
            return true
        end
    end
    -- Optional: check for custom attribute if your game sets one
    if player.Character:FindFirstChild("Ragdolled") then
        return true
    end
    return false
end

-- Wrap the original isValidTarget
local isValidTarget_original2 = isValidTarget
isValidTarget = function(player)
    if isRagdolled(player) then return false end
    return isValidTarget_original2(player)
end
