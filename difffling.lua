-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

-- GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SkipTweenGUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 320, 0, 160)
mainFrame.Position = UDim2.new(0.5, -160, 0.5, -80)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.BackgroundTransparency = 1
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -20, 0, 35)
titleLabel.Position = UDim2.new(0, 10, 0, 10)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Auto Farm Controls"
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 22
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = mainFrame

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 35, 0, 35)
closeBtn.Position = UDim2.new(1, -45, 0, 10)
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
closeBtn.BorderSizePixel = 0
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 28
closeBtn.Parent = mainFrame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

-- Auto Farm Button
local function createButton(text, posY, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -40, 0, 45)
    btn.Position = UDim2.new(0, 20, 0, posY)
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 20
    btn.AutoButtonColor = false
    btn.Parent = mainFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    return btn
end

local autoFarmButton = createButton("Auto Farm: OFF", 60, Color3.fromRGB(85, 170, 255))

-- Click effect
local function clickEffect(btn, callback)
    if btn:GetAttribute("ClickInProgress") then return end
    btn:SetAttribute("ClickInProgress", true)
    local origSize = btn.Size
    local smallSize = UDim2.new(origSize.X.Scale, origSize.X.Offset - 6, origSize.Y.Scale, origSize.Y.Offset - 3)
    local offsetX = (origSize.X.Offset - smallSize.X.Offset)/2
    local offsetY = (origSize.Y.Offset - smallSize.Y.Offset)/2
    local origPos = btn.Position
    local smallPos = UDim2.new(origPos.X.Scale, origPos.X.Offset + offsetX, origPos.Y.Scale, origPos.Y.Offset + offsetY)
    TweenService:Create(btn, TweenInfo.new(0.07), {Size = smallSize, Position = smallPos}):Play()
    task.delay(0.1, function()
        TweenService:Create(btn, TweenInfo.new(0.1), {Size = origSize, Position = origPos}):Play()
        task.delay(0.12, function()
            btn:SetAttribute("ClickInProgress", false)
            if callback then callback() end
        end)
    end)
end

-- Auto Farm Logic
local autoFarmActive = false
local buttonsFolder = Workspace:WaitForChild("CashGemsButtons_Folder")
local targetButton = buttonsFolder:WaitForChild("CashGemsButton_500") -- Direct target

local function tweenToTarget(rootPart)
    if rootPart and targetButton and targetButton:IsA("BasePart") then
        local tweenInfo = TweenInfo.new(8.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out) -- 7.5s tween
        local goal = {CFrame = targetButton.CFrame + Vector3.new(0, 3, 0)}
        local tween = TweenService:Create(rootPart, tweenInfo, goal)
        tween:Play()
        tween.Completed:Wait()
    end
end

local function runAutoFarm()
    while autoFarmActive do
        -- Espera a que el personaje exista y tenga HumanoidRootPart y Humanoid
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:WaitForChild("HumanoidRootPart")
        local humanoid = character:WaitForChild("Humanoid")
        
        -- Tween al botón
        tweenToTarget(rootPart)

        -- Mata al jugador
        if humanoid then
            humanoid.Health = 0
        end

        -- Espera 1 segundo antes de reiniciar el loop
        task.wait(0.6)

        -- Espera hasta que respawnee
        repeat
            character = player.Character
            humanoid = character and character:FindFirstChild("Humanoid")
            rootPart = character and character:FindFirstChild("HumanoidRootPart")
            task.wait(0.1)
        until humanoid and rootPart
    end
end

autoFarmButton.MouseButton1Click:Connect(function()
    clickEffect(autoFarmButton, function()
        autoFarmActive = not autoFarmActive
        autoFarmButton.Text = autoFarmActive and "Auto Farm: ON" or "Auto Farm: OFF"
        autoFarmButton.BackgroundColor3 = autoFarmActive and Color3.fromRGB(0,170,255) or Color3.fromRGB(85,170,255)
        if autoFarmActive then
            task.spawn(runAutoFarm)
        end
    end)
end)

-- Close GUI with animation
closeBtn.MouseButton1Click:Connect(function()
    clickEffect(closeBtn, function()
        autoFarmActive = false
        local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(mainFrame, tweenInfo, {Position = UDim2.new(0.5, -160, 1.5, 0), BackgroundTransparency = 1}):Play()
        task.delay(0.5, function()
            screenGui:Destroy()
        end)
    end)
end)

-- Dragging
local dragging = false
local dragOffset = Vector2.new()
titleLabel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragOffset = Vector2.new(input.Position.X - mainFrame.AbsolutePosition.X, input.Position.Y - mainFrame.AbsolutePosition.Y)
    end
end)

titleLabel.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

RunService.RenderStepped:Connect(function()
    if dragging then
        local mousePos = UserInputService:GetMouseLocation()
        mainFrame.Position = mainFrame.Position:Lerp(UDim2.new(0, mousePos.X - dragOffset.X, 0, mousePos.Y - dragOffset.Y), 0.05)
    end
end)

-- Open animation
TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {BackgroundTransparency = 0}):Play()
