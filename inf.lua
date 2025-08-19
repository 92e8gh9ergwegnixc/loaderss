--// Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

--// Character refs
local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")

local checkpoints = Workspace:WaitForChild("Checkpoints")
local rebirthEvent = ReplicatedStorage:WaitForChild("RebirthEvent", 9e9)

--// Script state
getgenv().StopMyScript = true
local conn

--// UI
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "FuturisticUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 220, 0, 120)
MainFrame.Position = UDim2.new(0.35, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.Active = true

local UIStroke = Instance.new("UIStroke", MainFrame)
UIStroke.Color = Color3.fromRGB(0, 200, 255)
UIStroke.Thickness = 2

local UICorner = Instance.new("UICorner", MainFrame)
UICorner.CornerRadius = UDim.new(0, 15)

--// Title
local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -30, 0, 30)
Title.Position = UDim2.new(0, 10, 0, 5)
Title.BackgroundTransparency = 1
Title.Text = "⚡ Plate Controller"
Title.TextColor3 = Color3.fromRGB(0, 200, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left

--// Buttons
local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -30, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
CloseBtn.TextSize = 16
CloseBtn.Font = Enum.Font.GothamBold

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0, 180, 0, 40)
ToggleBtn.Position = UDim2.new(0.5, -90, 0.5, -20)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
ToggleBtn.Text = "Activate Plates"
ToggleBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
ToggleBtn.TextSize = 16
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.AutoButtonColor = false

--// Tween settings per frame
local function frameTween(part, goalPos)
    local tweenInfo = TweenInfo.new(0.016, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local goal = {CFrame = CFrame.new(goalPos)}
    TweenService:Create(part, tweenInfo, goal):Play()
end

-- Y range
local minY, maxY = -3, 5
local step = 0

--// Store original positions
local originalPositions = {}
for i, part in ipairs(checkpoints:GetChildren()) do
    if part:IsA("BasePart") then
        originalPositions[part.Name] = part.CFrame
    end
end

--// Plate effect
local function startEffect()
    if conn then conn:Disconnect() end
    getgenv().StopMyScript = false

    local duplicates = {}
    for _, part in ipairs(checkpoints:GetChildren()) do
        if part:IsA("BasePart") then
            part.Transparency = 1
            part.CanCollide = false

            local clone = part:Clone()
            clone.Transparency = 0
            clone.CanCollide = false
            clone.Parent = checkpoints
            clone.CFrame = originalPositions[part.Name]
            duplicates[part.Name] = clone
        end
    end

    step = 0
    conn = RunService.Heartbeat:Connect(function(dt)
        if getgenv().StopMyScript then
            conn:Disconnect()
            return
        end

        step += dt * 40
        for _, part in ipairs(checkpoints:GetChildren()) do
            if part:IsA("BasePart") and part.Transparency == 1 then
                local index = tonumber(part.Name) or 0
                local yOffset = math.sin(step + index * 0.25) * ((maxY - minY) / 2)
                frameTween(part, root.Position + Vector3.new(0, yOffset, 0))
            end
        end

        rebirthEvent:FireServer()
    end)
end

local function stopEffect()
    getgenv().StopMyScript = true
    if conn then conn:Disconnect() end

    for _, part in ipairs(checkpoints:GetChildren()) do
        if part:IsA("BasePart") then
            part.Transparency = 1
            part.CanCollide = false
            if not originalPositions[part.Name] then
                part:Destroy()
            end
        end
    end
end

--// Smooth draggable effect (click-relative)
local dragging = false
local dragOffset = Vector2.new()

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        local mousePos = UserInputService:GetMouseLocation()
        dragOffset = mousePos - Vector2.new(MainFrame.AbsolutePosition.X, MainFrame.AbsolutePosition.Y)
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

RunService.RenderStepped:Connect(function()
    if dragging then
        local mousePos = UserInputService:GetMouseLocation()
        local targetPos = mousePos - dragOffset
        MainFrame.Position = MainFrame.Position:Lerp(
            UDim2.new(0, targetPos.X, 0, targetPos.Y),
            0.15 -- velocidad de seguimiento
        )
    end
end)

--// Button click effects
local function clickEffect(btn)
    local original = btn.BackgroundColor3
    TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundColor3 = original:Lerp(Color3.fromRGB(255, 255, 255), 0.5)}):Play()
    task.delay(0.1, function()
        TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = original}):Play()
    end)
end

ToggleBtn.MouseButton1Click:Connect(function()
    clickEffect(ToggleBtn)
    if getgenv().StopMyScript then
        startEffect()
        ToggleBtn.Text = "Deactivate Plates"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    else
        stopEffect()
        ToggleBtn.Text = "Activate Plates"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    clickEffect(CloseBtn)
    stopEffect()
    TweenService:Create(ScreenGui, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {DisplayOrder = -1}):Play()
    task.delay(0.25, function()
        ScreenGui:Destroy()
    end)
end)

--// Open animation
MainFrame.Position = MainFrame.Position - UDim2.new(0,0,0,50)
TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    {Position = MainFrame.Position + UDim2.new(0,0,0,50)}):Play()
