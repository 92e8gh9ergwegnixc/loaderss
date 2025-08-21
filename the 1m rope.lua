--// Script: Lag Server + Infinite Money GUI (click version)
--// LocalScript in StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local heliRemote = ReplicatedStorage:WaitForChild("Heli_Remotes"):WaitForChild("Equip")
local giveRewardRemote = ReplicatedStorage:WaitForChild("CratesUtilities"):WaitForChild("Remotes"):WaitForChild("GiveReward")

-- GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LagServerGUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 260, 0, 200)
frame.Position = UDim2.new(0.5, -130, 0.7, -100)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1,0,0,35)
titleBar.BackgroundColor3 = Color3.fromRGB(35,35,35)
titleBar.BorderSizePixel = 0
titleBar.Parent = frame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0,12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Lag Server"
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(255,255,255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

-- Close button
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0,35,0,35)
closeButton.Position = UDim2.new(1, -40, 0.5, -17)
closeButton.Text = "×"
closeButton.TextColor3 = Color3.new(1,1,1)
closeButton.BackgroundColor3 = Color3.fromRGB(180,50,50)
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 28
closeButton.Parent = titleBar
Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0,8)

-- Lag Server Toggle
local lagButton = Instance.new("TextButton")
lagButton.Size = UDim2.new(1, -40, 0, 50)
lagButton.Position = UDim2.new(0,20,0,50)
lagButton.Text = "Lag Server: OFF"
lagButton.BackgroundColor3 = Color3.fromRGB(70,70,70)
lagButton.TextColor3 = Color3.new(1,1,1)
lagButton.Font = Enum.Font.GothamBold
lagButton.TextSize = 20
lagButton.AutoButtonColor = false
lagButton.Parent = frame
Instance.new("UICorner", lagButton).CornerRadius = UDim.new(0,10)

local lagEnabled = false
lagButton.MouseButton1Click:Connect(function()
    lagEnabled = not lagEnabled
    lagButton.Text = lagEnabled and "Lag Server: ON" or "Lag Server: OFF"
    TweenService:Create(lagButton, TweenInfo.new(0.2), {
        BackgroundColor3 = lagEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(70,70,70)
    }):Play()
end)

-- Infinite Money Click Button
local moneyButton = Instance.new("TextButton")
moneyButton.Size = UDim2.new(1, -40, 0, 50)
moneyButton.Position = UDim2.new(0,20,0,120)
moneyButton.Text = "Infinite Money"
moneyButton.BackgroundColor3 = Color3.fromRGB(70,70,70)
moneyButton.TextColor3 = Color3.new(1,1,1)
moneyButton.Font = Enum.Font.GothamBold
moneyButton.TextSize = 20
moneyButton.AutoButtonColor = false
moneyButton.Parent = frame
Instance.new("UICorner", moneyButton).CornerRadius = UDim.new(0,10)

moneyButton.MouseButton1Click:Connect(function()
    local args = {
        "50000000500000000000000000000000000000000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
    }
    giveRewardRemote:FireServer(unpack(args))
end)

-- Lag Server loops
task.spawn(function()
    while true do
        if lagEnabled then
            heliRemote:FireServer()
        end
        task.wait(0.01)
    end
end)

task.spawn(function()
    while true do
        if lagEnabled then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj.Name:lower() == "helicopter" then
                    obj:Destroy()
                end
            end
        end
        task.wait(0.001)
    end
end)

-- Close button logic
closeButton.MouseButton1Click:Connect(function()
    TweenService:Create(frame, TweenInfo.new(0.4), {
        Position = UDim2.new(0.5,-130,1.5,0)
    }):Play()
    task.delay(0.4, function()
        screenGui:Destroy()
    end)
end)

-- Drag frame
local dragging, dragOffset
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragOffset = Vector2.new(input.Position.X - frame.AbsolutePosition.X, input.Position.Y - frame.AbsolutePosition.Y)
    end
end)

titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

RunService.RenderStepped:Connect(function()
    if dragging then
        local mouse = UserInputService:GetMouseLocation()
        local target = UDim2.new(0, mouse.X - dragOffset.X, 0, mouse.Y - dragOffset.Y)
        frame.Position = frame.Position:Lerp(target, 0.15)
    end
end)
