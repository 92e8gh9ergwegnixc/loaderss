-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- Variables del script
local active = false
local cooldown = false
local cooldownTime = 0.5 -- medio segundo entre activaciones

-- Detectar todas las WinPart
local winParts = {}
for _, part in ipairs(Workspace:GetChildren()) do
    if part.Name == "WinPart" and part:IsA("BasePart") then
        part.CanCollide = false
        part.Transparency = 1
        part.Size = Vector3.new(5,5,5)
        table.insert(winParts, part)
    end
end

-- Partes del cuerpo
local bodyParts = {}
for _, part in ipairs(char:GetDescendants()) do
    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
        table.insert(bodyParts, part)
    end
end

-- Indices por WinPart
local indices = {}
for i, wp in ipairs(winParts) do
    indices[wp] = 1
end

-- Función que mueve los WinPart
local function moveWinParts()
    RunService.RenderStepped:Connect(function()
        if active then
            for _, wp in ipairs(winParts) do
                if #bodyParts > 0 then
                    local idx = indices[wp]
                    local target = bodyParts[idx]
                    if target and target.Parent then
                        wp.CFrame = target.CFrame + Vector3.new(0,0.5,0)
                    end
                    idx = idx + 1
                    if idx > #bodyParts then idx = 1 end
                    indices[wp] = idx
                end
            end
        end
    end)
end

-- Crear GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = game.CoreGui
screenGui.ResetOnSpawn = false
screenGui.Name = "WinPartController"

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0,250,0,120)
mainFrame.Position = UDim2.new(0.3,0,0.3,0)
mainFrame.BackgroundColor3 = Color3.fromRGB(20,20,25)
mainFrame.Parent = screenGui

local uicorner = Instance.new("UICorner")
uicorner.CornerRadius = UDim.new(0,15)
uicorner.Parent = mainFrame

-- Título
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-20,0,30)
title.Position = UDim2.new(0,10,0,5)
title.BackgroundTransparency = 1
title.Text = "⚡ WinPart Controller"
title.TextColor3 = Color3.fromRGB(0,200,255)
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = mainFrame

-- Cerrar GUI
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,25,0,25)
closeBtn.Position = UDim2.new(1,-30,0,5)
closeBtn.BackgroundColor3 = Color3.fromRGB(50,0,0)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255,50,50)
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = mainFrame

-- Botón ON/OFF
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0,200,0,50)
toggleBtn.Position = UDim2.new(0.5,-100,0.5,-25)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0,200,255)
toggleBtn.Text = "Activate"
toggleBtn.TextColor3 = Color3.fromRGB(0,0,0)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 16
toggleBtn.Parent = mainFrame

-- Animación de clic
local function clickEffect(btn)
    local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(btn, tweenInfo, {BackgroundTransparency = 0.5})
    tween:Play()
    tween.Completed:Connect(function() btn.BackgroundTransparency = 0 end)
end

-- ON/OFF con cooldown
toggleBtn.MouseButton1Click:Connect(function()
    if cooldown then return end
    cooldown = true
    clickEffect(toggleBtn)
    active = not active
    toggleBtn.Text = active and "Deactivate" or "Activate"
    toggleBtn.BackgroundColor3 = active and Color3.fromRGB(255,50,50) or Color3.fromRGB(0,200,255)
    task.delay(cooldownTime,function() cooldown = false end)
end)

-- Cerrar GUI
closeBtn.MouseButton1Click:Connect(function()
    clickEffect(closeBtn)
    mainFrame:TweenPosition(UDim2.new(0.5,-125,1,50), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true, function()
        screenGui:Destroy()
    end)
end)

-- Draggable suave desde el punto donde se hace clic
local dragging = false
local dragOffset = Vector2.new()

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        local mousePos = UserInputService:GetMouseLocation()
        local framePos = mainFrame.AbsolutePosition
        dragOffset = mousePos - Vector2.new(framePos.X, framePos.Y)
    end
end)

mainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

RunService.RenderStepped:Connect(function()
    if dragging then
        local mousePos = UserInputService:GetMouseLocation()
        local targetPos = mousePos - dragOffset
        -- Lerp para suavizado rápido
        mainFrame.Position = mainFrame.Position:Lerp(
            UDim2.new(0, targetPos.X, 0, targetPos.Y),
            0.2 -- cuanto más cerca de 1, más rápido sigue el mouse
        )
    end
end)

-- Iniciar movimiento de WinParts
moveWinParts()
