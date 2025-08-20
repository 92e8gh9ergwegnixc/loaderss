-- Ride A Bike (V1) — Shrink-close / grow-open, responsive sizing, ON/OFF toggle, instant TP
-- Place this LocalScript in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

-- CONFIG
local CHECKPOINT_PATH = {"WorldMap", "Checkpoints", "99", "Hitbox"}
local PORTAL_PATH = {"WorldMap", "RestartPortal", "Meshes/IceysAssetPack_Cube (1)"}
local AUTO_COOLDOWN = 60
local INSTANT_DEBOUNCE = 5
local TELEPORT_OFFSET = Vector3.new(0, 3, 0)
local FLASH_DURATION = 0.28
local OPEN_TIME = 0.22
local CLOSE_TIME = 0.18
local BUTTON_SHRINK_TIME = 0.12
local TARGET_SIZE = UDim2.new(0.32, 0, 0.26, 0) -- responsive (scale-based)

-- HELPERS
local function getDescendant(root, path)
    local cur = root
    for _, name in ipairs(path) do
        if not cur then return nil end
        cur = cur:FindFirstChild(name)
    end
    return cur
end

local function getCharacterParts()
    local char = player.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    return char, humanoid, hrp
end

local function safeTeleportTo(part)
    if not part or not part:IsA("BasePart") then return false end
    local _, _, hrp = getCharacterParts()
    if not hrp then return false end
    hrp.CFrame = part.CFrame + TELEPORT_OFFSET
    return true
end

local function flashEffect()
    local _, _, hrp = getCharacterParts()
    if not hrp then return end
    local flash = Instance.new("Part")
    flash.Size = Vector3.new(0.1,0.1,0.1)
    flash.Anchored = true
    flash.CanCollide = false
    flash.Transparency = 1
    flash.CFrame = hrp.CFrame
    flash.Parent = workspace
    local light = Instance.new("PointLight", flash)
    light.Range = 12; light.Brightness = 6; light.Color = Color3.fromRGB(110,190,255)
    flash.Transparency = 0
    flash.Size = Vector3.new(0.25,0.25,0.25)
    local t = TweenService:Create(flash, TweenInfo.new(FLASH_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(6,6,6), Transparency = 1})
    t:Play()
    task.delay(FLASH_DURATION + 0.05, function() if flash and flash.Parent then flash:Destroy() end end)
end

-- BUILD GUI (scale-based so it adapts)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RideABikeGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.AnchorPoint = Vector2.new(0.5, 0)
main.Position = UDim2.new(0.7, 0, 0.14, 0)
main.Size = UDim2.new(0,0,0,0) -- start closed for open animation
main.BackgroundColor3 = Color3.fromRGB(12,14,20)
main.BorderSizePixel = 0
main.Parent = screenGui
Instance.new("UICorner", main).CornerRadius = UDim.new(0,14)
local stroke = Instance.new("UIStroke", main); stroke.Color = Color3.fromRGB(44,90,160); stroke.Transparency = 0.18; stroke.Thickness = 1
local grad = Instance.new("UIGradient", main); grad.Color = ColorSequence.new(Color3.fromRGB(10,12,18), Color3.fromRGB(14,18,24)); grad.Rotation = 90

-- Header
local header = Instance.new("Frame", main)
header.Size = UDim2.new(1, 0, 0.14, 0)
header.Position = UDim2.new(0,0,0,0)
header.BackgroundTransparency = 1

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(0.6, 0, 1, 0)
title.Position = UDim2.new(0.03, 0, 0, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Text = "Ride A Bike"
title.TextColor3 = Color3.fromRGB(150,200,255)
title.TextXAlignment = Enum.TextXAlignment.Left

local verLabel = Instance.new("TextLabel", header)
verLabel.Size = UDim2.new(0.12, 0, 1, 0)
verLabel.Position = UDim2.new(0.75, 0, 0, 0)
verLabel.BackgroundTransparency = 1
verLabel.Font = Enum.Font.Gotham
verLabel.TextSize = 12
verLabel.Text = "V1"
verLabel.TextColor3 = Color3.fromRGB(120,150,200)
verLabel.TextXAlignment = Enum.TextXAlignment.Right

local closeBtn = Instance.new("TextButton", header)
closeBtn.Size = UDim2.new(0.08, 0, 0.68, 0)
closeBtn.Position = UDim2.new(0.88, 0, 0.16, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(26,24,28)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.TextColor3 = Color3.fromRGB(230,100,100)
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,8)
local closeStroke = Instance.new("UIStroke", closeBtn); closeStroke.Color = Color3.fromRGB(60,110,200); closeStroke.Transparency = 0.45; closeStroke.Thickness = 1

-- Content area
local content = Instance.new("Frame", main)
content.Size = UDim2.new(1, -0, 0.86, 0)
content.Position = UDim2.new(0, 0, 0.14, 0)
content.BackgroundTransparency = 1

-- Buttons (use scale sizes so they adapt)
local autoBtn = Instance.new("TextButton", content)
autoBtn.Size = UDim2.new(0.48, 0, 0.32, 0)
autoBtn.Position = UDim2.new(0.02, 0, 0.06, 0)
autoBtn.Font = Enum.Font.GothamBold
autoBtn.TextSize = 15
autoBtn.Text = "Auto: OFF"
autoBtn.TextColor3 = Color3.fromRGB(220,230,255)
autoBtn.BackgroundColor3 = Color3.fromRGB(22,40,70)
Instance.new("UICorner", autoBtn).CornerRadius = UDim.new(0,8)
local autoStroke = Instance.new("UIStroke", autoBtn); autoStroke.Color = Color3.fromRGB(70,130,210); autoStroke.Transparency = 0.45; autoStroke.Thickness = 1

local instantBtn = Instance.new("TextButton", content)
instantBtn.Size = UDim2.new(0.48, 0, 0.32, 0)
instantBtn.Position = UDim2.new(0.5, 0, 0.06, 0)
instantBtn.Font = Enum.Font.GothamBold
instantBtn.TextSize = 15
instantBtn.Text = "INSTANT TP"
instantBtn.TextColor3 = Color3.fromRGB(18,18,20)
instantBtn.BackgroundColor3 = Color3.fromRGB(90,200,255)
Instance.new("UICorner", instantBtn).CornerRadius = UDim.new(0,8)
local instStroke = Instance.new("UIStroke", instantBtn); instStroke.Color = Color3.fromRGB(50,120,180); instStroke.Transparency = 0.35; instStroke.Thickness = 1

-- Cooldown label and bar (scale-based)
local cdLabel = Instance.new("TextLabel", content)
cdLabel.Size = UDim2.new(0.6, 0, 0.12, 0)
cdLabel.Position = UDim2.new(0.02, 0, 0.48, 0)
cdLabel.BackgroundTransparency = 1
cdLabel.Font = Enum.Font.Gotham
cdLabel.TextSize = 13
cdLabel.Text = "Cooldown: " .. tostring(AUTO_COOLDOWN) .. "s"
cdLabel.TextColor3 = Color3.fromRGB(120,160,200)
cdLabel.TextXAlignment = Enum.TextXAlignment.Left

local barOuter = Instance.new("Frame", content)
barOuter.Size = UDim2.new(0.96, 0, 0.12, 0)
barOuter.Position = UDim2.new(0.02, 0, 0.64, 0)
barOuter.BackgroundColor3 = Color3.fromRGB(18,20,28)
Instance.new("UICorner", barOuter).CornerRadius = UDim.new(0,8)
local barInner = Instance.new("Frame", barOuter)
barInner.Size = UDim2.new(0, 0, 1, 0)
barInner.Position = UDim2.new(0, 0, 0, 0)
barInner.BackgroundColor3 = Color3.fromRGB(60,150,255)
Instance.new("UICorner", barInner).CornerRadius = UDim.new(0,8)

-- Collect shrink targets (elements that shrink first)
local shrinkTargets = {
    autoBtn, instantBtn, cdLabel, barInner, barOuter, title, verLabel, closeBtn
}

-- Drag + inertia (same behaviour)
local dragging = false
local dragStart = Vector2.new()
local startPos = UDim2.new()
local targetPos = main.Position
local velocity = Vector2.new(0,0)
local lastMouse = nil
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = Vector2.new(input.Position.X, input.Position.Y)
        startPos = main.Position
        lastMouse = dragStart
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
RunService.RenderStepped:Connect(function(dt)
    if dragging then
        local m = player:GetMouse()
        if m then
            local mousePos = Vector2.new(m.X, m.Y)
            local delta = mousePos - dragStart
            targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            if lastMouse then velocity = mousePos - lastMouse end
            lastMouse = mousePos
        end
    else
        if velocity.Magnitude > 0.5 then
            targetPos = UDim2.new(startPos.X.Scale, main.Position.X.Offset + velocity.X * 0.6, startPos.Y.Scale, main.Position.Y.Offset + velocity.Y * 0.6)
            velocity = velocity * 0.86
        else
            velocity = Vector2.new(0,0)
        end
        lastMouse = nil
    end
    local cur = main.Position
    local lerpAlpha = math.clamp(dt * 12, 0, 1)
    local newX = cur.X.Offset + (targetPos.X.Offset - cur.X.Offset) * lerpAlpha
    local newY = cur.Y.Offset + (targetPos.Y.Offset - cur.Y.Offset) * lerpAlpha
    main.Position = UDim2.new(cur.X.Scale, newX, cur.Y.Scale, newY)
end)

-- OPEN / CLOSE animations (shrink children first on close; grow children after panel open)
local function animateOpen()
    -- prepare children shrunk
    main.Size = UDim2.new(0,0,0,0)
    for _, obj in ipairs(shrinkTargets) do
        if obj and obj:IsA("GuiObject") then
            pcall(function() obj.Size = UDim2.new(0,0,0,0) end)
        end
    end
    barInner.Size = UDim2.new(0,0,1,0)

    -- expand panel
    local tMain = TweenService:Create(main, TweenInfo.new(OPEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = TARGET_SIZE})
    tMain:Play()
    task.wait(OPEN_TIME * 1.02)

    -- grow children to their target sizes (targets defined relative to parent)
    local childrenTweens = {}
    table.insert(childrenTweens, TweenService:Create(autoBtn, TweenInfo.new(OPEN_TIME*0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0.48,0,0.32,0), BackgroundTransparency = 0}))
    table.insert(childrenTweens, TweenService:Create(instantBtn, TweenInfo.new(OPEN_TIME*0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0.48,0,0.32,0), BackgroundTransparency = 0}))
    table.insert(childrenTweens, TweenService:Create(cdLabel, TweenInfo.new(OPEN_TIME*0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0.6,0,0.12,0)}))
    table.insert(childrenTweens, TweenService:Create(barOuter, TweenInfo.new(OPEN_TIME*0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0.96,0,0.12,0)}))
    table.insert(childrenTweens, TweenService:Create(title, TweenInfo.new(OPEN_TIME*0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0.6,0,1,0)}))
    table.insert(childrenTweens, TweenService:Create(verLabel, TweenInfo.new(OPEN_TIME*0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0.12,0,1,0)}))
    table.insert(childrenTweens, TweenService:Create(closeBtn, TweenInfo.new(OPEN_TIME*0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0.08,0,0.68,0)}))
    for _, t in ipairs(childrenTweens) do t:Play() end
    task.wait(OPEN_TIME * 0.95)
end

local function animateCloseAndDestroy()
    -- disable buttons immediately
    autoBtn.Active = false; instantBtn.Active = false; closeBtn.Active = false
    autoBtn.AutoButtonColor = false; instantBtn.AutoButtonColor = false; closeBtn.AutoButtonColor = false

    -- shrink children to zero sizes
    for _, obj in ipairs(shrinkTargets) do
        if obj and obj:IsA("GuiObject") then
            local ok, t = pcall(function()
                return TweenService:Create(obj, TweenInfo.new(BUTTON_SHRINK_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0,0,0,0)})
            end)
            if ok and t then t:Play() end
        end
    end
    -- also shrink barInner quickly
    pcall(function()
        TweenService:Create(barInner, TweenInfo.new(BUTTON_SHRINK_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0,0,1,0)}):Play()
    end)

    task.wait(BUTTON_SHRINK_TIME + 0.02)

    -- collapse main after children gone
    local ok, tMain = pcall(function()
        return TweenService:Create(main, TweenInfo.new(CLOSE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0,0,0,0)})
    end)
    if ok and tMain then tMain:Play() end
    task.wait(CLOSE_TIME + 0.02)

    if screenGui and screenGui.Parent then screenGui:Destroy() end
end

closeBtn.Activated:Connect(function()
    animateCloseAndDestroy()
end)

-- TELEPORT LOGIC
local autoOn = false
local lastAutoAt = 0
local lastInstantAt = 0
local autoCoroutine = nil

local function doTeleportSequence(withFlash)
    local checkpoint = getDescendant(Workspace, CHECKPOINT_PATH)
    if checkpoint then
        safeTeleportTo(checkpoint)
        if withFlash then flashEffect() end
    end
    task.wait(0.1)
    local portal = getDescendant(Workspace, PORTAL_PATH)
    if portal then
        safeTeleportTo(portal)
        if withFlash then flashEffect() end
    end
    lastAutoAt = tick()
    return true
end

local function startAutoLoop()
    if autoCoroutine then return end
    autoOn = true
    autoBtn.Text = "Auto: ON"
    autoBtn.BackgroundColor3 = Color3.fromRGB(30,60,110)
    autoCoroutine = coroutine.create(function()
        while autoOn do
            if tick() - lastAutoAt >= AUTO_COOLDOWN then
                pcall(function() doTeleportSequence(true) end)
            end
            RunService.Heartbeat:Wait()
        end
        autoCoroutine = nil
    end)
    coroutine.resume(autoCoroutine)
end

local function stopAutoLoop()
    autoOn = false
    autoCoroutine = nil
    autoBtn.Text = "Auto: OFF"
    autoBtn.BackgroundColor3 = Color3.fromRGB(22,40,70)
end

autoBtn.Activated:Connect(function()
    if autoOn then stopAutoLoop() else startAutoLoop() end
end)

instantBtn.Activated:Connect(function()
    if tick() - lastInstantAt < INSTANT_DEBOUNCE then return end
    lastInstantAt = tick()
    pcall(function()
        doTeleportSequence(true)
    end)
end)

-- instant-updating cooldown bar & label (every frame)
RunService.RenderStepped:Connect(function()
    local remaining = math.max(0, lastAutoAt + AUTO_COOLDOWN - tick())
    local pct = 0
    if AUTO_COOLDOWN > 0 then
        pct = math.clamp((AUTO_COOLDOWN - remaining) / AUTO_COOLDOWN, 0, 1)
    end
    barInner.Size = UDim2.new(pct, 0, 1, 0)
    cdLabel.Text = ("Cooldown: %ds"):format(math.ceil(remaining))
end)

-- perform open animation on spawn
task.spawn(animateOpen)

-- cleanup on leave
player.CharacterRemoving:Connect(function()
    autoOn = false
    autoCoroutine = nil
end)
