-- Ride A Bike V2 (Final)
-- Teleports: Highest checkpoint -> wait 0.7s -> Portal
-- Cooldown = 64s, starts after pressing Start
-- GUI open/close animates entire frame (0x0 → full, full → 0x0)
-- Text/buttons fade in/out with GUI
-- Draggable everywhere with smooth delay

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- === SETTINGS ===
local PORTAL_PATH = {"WorldMap", "RestartPortal", "Meshes/IceysAssetPack_Cube (1)"}
local WAIT_AFTER_CHECKPOINT = 0.7
local COOLDOWN = 64
local INSTANT_DEBOUNCE = 5

-- === HELPERS ===
local function getDescendant(root, pathArray)
	for _, name in ipairs(pathArray) do
		root = root:FindFirstChild(name)
		if not root then return nil end
	end
	return root
end

-- Find highest-numbered checkpoint
local function getHighestCheckpoint()
	local checkpointsFolder = getDescendant(Workspace, {"WorldMap", "Checkpoints"})
	if not checkpointsFolder then return nil end

	local highest = nil
	local maxNum = -math.huge

	for _, child in ipairs(checkpointsFolder:GetChildren()) do
		if tonumber(child.Name) then
			local num = tonumber(child.Name)
			if num > maxNum then
				maxNum = num
				highest = child:FindFirstChild("Hitbox")
			end
		end
	end

	return highest
end

local function teleportTo(part)
	local char = player.Character or player.CharacterAdded:Wait()
	local hrp = char:WaitForChild("HumanoidRootPart")
	if part and part:IsA("BasePart") then
		hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
	end
end

-- === GUI CREATION ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RideABikeV2"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local TARGET_SIZE = UDim2.new(0.30, 0, 0.23, 0)
local CENTER_POS = UDim2.new(0.7, 0, 0.18, 0)

local main = Instance.new("Frame")
main.AnchorPoint = Vector2.new(0.5, 0)
main.Position = CENTER_POS
main.Size = UDim2.new(0, 0, 0, 0)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
main.BorderSizePixel = 0
main.Parent = screenGui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", main).Color = Color3.fromRGB(44,90,160)

-- Header
local header = Instance.new("Frame", main)
header.Size = UDim2.new(1, 0, 0.14, 0)
header.BackgroundTransparency = 1

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(0.7, 0, 1, 0)
title.Position = UDim2.new(0.04, 0, 0, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Text = "Ride A Bike  |  V2"
title.TextColor3 = Color3.fromRGB(150,200,255)
title.TextXAlignment = Enum.TextXAlignment.Left

local close = Instance.new("TextButton", header)
close.Size = UDim2.new(0.1, 0, 0.7, 0)
close.Position = UDim2.new(0.88, 0, 0.15, 0)
close.BackgroundColor3 = Color3.fromRGB(26, 24, 28)
close.BorderSizePixel = 0
close.Text = "X"
close.Font = Enum.Font.GothamBold
close.TextSize = 16
close.TextColor3 = Color3.fromRGB(230,100,100)
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 8)

-- Content
local content = Instance.new("Frame", main)
content.Size = UDim2.new(1, 0, 0.86, 0)
content.Position = UDim2.new(0, 0, 0.14, 0)
content.BackgroundTransparency = 1

local toggle = Instance.new("TextButton", content)
toggle.Size = UDim2.new(0.48, 0, 0.32, 0)
toggle.Position = UDim2.new(0.02, 0, 0.06, 0)
toggle.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
toggle.Text = "Start Auto Teleport"
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 16
toggle.TextColor3 = Color3.fromRGB(255,255,255)
Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 8)

local instantBtn = Instance.new("TextButton", content)
instantBtn.Size = UDim2.new(0.48, 0, 0.32, 0)
instantBtn.Position = UDim2.new(0.5, 0, 0.06, 0)
instantBtn.BackgroundColor3 = Color3.fromRGB(90,200,255)
instantBtn.Text = "INSTANT TP"
instantBtn.Font = Enum.Font.GothamBold
instantBtn.TextSize = 16
instantBtn.TextColor3 = Color3.fromRGB(18,18,20)
Instance.new("UICorner", instantBtn).CornerRadius = UDim.new(0, 8)

local barBack = Instance.new("Frame", content)
barBack.Size = UDim2.new(0.96, 0, 0.18, 0)
barBack.Position = UDim2.new(0.02, 0, 0.56, 0)
barBack.BackgroundColor3 = Color3.fromRGB(32,32,48)
barBack.BorderSizePixel = 0
Instance.new("UICorner", barBack).CornerRadius = UDim.new(0, 8)

local barFill = Instance.new("Frame", barBack)
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
barFill.BorderSizePixel = 0
Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, 8)

local cdLabel = Instance.new("TextLabel", content)
cdLabel.Size = UDim2.new(0.96, 0, 0.16, 0)
cdLabel.Position = UDim2.new(0.02, 0, 0.76, 0)
cdLabel.BackgroundTransparency = 1
cdLabel.Font = Enum.Font.Gotham
cdLabel.TextSize = 13
cdLabel.TextColor3 = Color3.fromRGB(140,170,200)
cdLabel.TextXAlignment = Enum.TextXAlignment.Left
cdLabel.Text = ("Cooldown: %ds"):format(COOLDOWN)

-- === OPEN/CLOSE ANIMATIONS ===
local OPEN_TIME = 0.3
local CLOSE_TIME = 0.25
local scriptActive = true

local textObjects = {title, close, toggle, instantBtn, cdLabel}
local function setTransparency(alpha)
	for _, obj in ipairs(textObjects) do
		if obj:IsA("TextLabel") or obj:IsA("TextButton") then
			obj.TextTransparency = alpha
		end
	end
end
setTransparency(1)

local function animateOpen()
	local tweenFrame = TweenService:Create(main, TweenInfo.new(OPEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = TARGET_SIZE})
	tweenFrame:Play()
	task.delay(OPEN_TIME * 0.6, function()
		for _, obj in ipairs(textObjects) do
			TweenService:Create(obj, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
		end
	end)
end

local function animateCloseAndDestroy()
	scriptActive = false
	for _, obj in ipairs(textObjects) do
		TweenService:Create(obj, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1}):Play()
	end
	local tweenFrame = TweenService:Create(main, TweenInfo.new(CLOSE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0,0,0,0)})
	tweenFrame:Play()
	tweenFrame.Completed:Wait()
	if screenGui and screenGui.Parent then
		screenGui:Destroy()
	end
end

animateOpen()
close.Activated:Connect(animateCloseAndDestroy)

-- === TELEPORT / COOLDOWN LOGIC ===
local running = false
local lastTick = tick()
local lastInstant = 0

local function teleportCycle()
	if not scriptActive then return end
	local checkpoint = getHighestCheckpoint()
	local portal = getDescendant(Workspace, PORTAL_PATH)
	if checkpoint then teleportTo(checkpoint) end
	task.wait(WAIT_AFTER_CHECKPOINT)
	if portal then teleportTo(portal) end
	lastTick = tick()
end

RunService.RenderStepped:Connect(function()
	if not scriptActive then return end
	if running then
		local elapsed = tick() - lastTick
		local progress = math.clamp(elapsed / COOLDOWN, 0, 1)
		barFill.Size = UDim2.new(progress, 0, 1, 0)
		cdLabel.Text = ("Cooldown: %ds"):format(math.max(0, math.ceil(COOLDOWN - elapsed)))
		if elapsed >= COOLDOWN then
			pcall(function() teleportCycle() end)
		end
	else
		barFill.Size = UDim2.new(0, 0, 1, 0)
		cdLabel.Text = ("Cooldown: %ds"):format(COOLDOWN)
	end
end)

toggle.Activated:Connect(function()
	running = not running
	if running then
		lastTick = tick() -- reset cooldown at start
	end
	toggle.Text = running and "Stop Auto Teleport" or "Start Auto Teleport"
end)

instantBtn.Activated:Connect(function()
	if tick() - lastInstant >= INSTANT_DEBOUNCE then
		lastInstant = tick()
		pcall(function() teleportCycle() end)
	end
end)

-- === DRAGGING WITH GLOBAL FOLLOW + TINY DELAY ===
local dragging, dragStart, startPos, targetPos

header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = main.Position
		targetPos = startPos
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
		targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

RunService.RenderStepped:Connect(function()
	if targetPos and scriptActive then
		main.Position = main.Position:Lerp(targetPos, 0.15)
	end
end)
