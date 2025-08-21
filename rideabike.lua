-- Ride A Bike V1
-- Teleport every cooldown cycle, with grow/open and shrink/close child-first animation
-- Added: COOLDOWN = 60 and Instant TP button (doesn't affect auto timer)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

-- === SETTINGS ===
local CHECKPOINT_PATH = {"WorldMap", "Checkpoints", "99", "Hitbox"}
local PORTAL_PATH = {"WorldMap", "RestartPortal", "Meshes/IceysAssetPack_Cube (1)"}
local WAIT_AFTER_CHECKPOINT = 0.1
local COOLDOWN = 66 -- seconds per cycle (updated to 60s)
local INSTANT_DEBOUNCE = 5 -- seconds between Instant TP presses

-- === HELPERS ===
local function getDescendant(root, pathArray)
	for _, name in ipairs(pathArray) do
		root = root:FindFirstChild(name)
		if not root then return nil end
	end
	return root
end

local function teleportTo(part)
	local char = player.Character or player.CharacterAdded:Wait()
	local hrp = char:WaitForChild("HumanoidRootPart")
	if part and part:IsA("BasePart") then
		hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
	end
end

-- === GUI CREATION (responsive/scaled) ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RideABikeV1"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- target scale size for responsive layout
local TARGET_SIZE = UDim2.new(0.30, 0, 0.23, 0) -- 30% width, 23% height of screen
local CENTER_POS = UDim2.new(0.7, 0, 0.18, 0)

local main = Instance.new("Frame")
main.AnchorPoint = Vector2.new(0.5, 0)
main.Position = CENTER_POS
main.Size = UDim2.new(0, 0, 0, 0) -- start closed for open animation
main.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
main.BorderSizePixel = 0
main.Parent = screenGui
local mainCorner = Instance.new("UICorner", main); mainCorner.CornerRadius = UDim.new(0, 12)
local mainStroke = Instance.new("UIStroke", main); mainStroke.Color = Color3.fromRGB(44,90,160); mainStroke.Transparency = 0.18; mainStroke.Thickness = 1

-- Header (14% of frame height)
local header = Instance.new("Frame", main)
header.Size = UDim2.new(1, 0, 0.14, 0)
header.Position = UDim2.new(0, 0, 0, 0)
header.BackgroundTransparency = 1

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(0.62, 0, 1, 0)
title.Position = UDim2.new(0.04, 0, 0, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Text = "🚲 Ride A Bike  |  V1"
title.TextColor3 = Color3.fromRGB(150,200,255)
title.TextXAlignment = Enum.TextXAlignment.Left

local close = Instance.new("TextButton", header)
close.Size = UDim2.new(0.08, 0, 0.7, 0)
close.Position = UDim2.new(0.88, 0, 0.15, 0)
close.BackgroundColor3 = Color3.fromRGB(26, 24, 28)
close.BorderSizePixel = 0
close.Text = "X"
close.Font = Enum.Font.GothamBold
close.TextSize = 16
close.TextColor3 = Color3.fromRGB(230,100,100)
local closeCorner = Instance.new("UICorner", close); closeCorner.CornerRadius = UDim.new(0, 8)
local closeStroke = Instance.new("UIStroke", close); closeStroke.Color = Color3.fromRGB(60,110,200); closeStroke.Transparency = 0.45; closeStroke.Thickness = 1

-- Content area (remaining height)
local content = Instance.new("Frame", main)
content.Size = UDim2.new(1, 0, 0.86, 0)
content.Position = UDim2.new(0, 0, 0.14, 0)
content.BackgroundTransparency = 1

-- Buttons layout: two side-by-side buttons (toggle + instant)
local toggle = Instance.new("TextButton", content)
toggle.Size = UDim2.new(0.48, 0, 0.32, 0)
toggle.Position = UDim2.new(0.02, 0, 0.06, 0)
toggle.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
toggle.Text = "Start Auto Teleport"
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 16
toggle.TextColor3 = Color3.fromRGB(255,255,255)
local toggleCorner = Instance.new("UICorner", toggle); toggleCorner.CornerRadius = UDim.new(0, 8)
local toggleStroke = Instance.new("UIStroke", toggle); toggleStroke.Color = Color3.fromRGB(60,130,200); toggleStroke.Transparency = 0.4

local instantBtn = Instance.new("TextButton", content)
instantBtn.Size = UDim2.new(0.48, 0, 0.32, 0)
instantBtn.Position = UDim2.new(0.5, 0, 0.06, 0)
instantBtn.BackgroundColor3 = Color3.fromRGB(90,200,255)
instantBtn.Text = "INSTANT TP"
instantBtn.Font = Enum.Font.GothamBold
instantBtn.TextSize = 16
instantBtn.TextColor3 = Color3.fromRGB(18,18,20)
local instCorner = Instance.new("UICorner", instantBtn); instCorner.CornerRadius = UDim.new(0, 8)
local instStroke = Instance.new("UIStroke", instantBtn); instStroke.Color = Color3.fromRGB(50,120,180); instStroke.Transparency = 0.35

-- cooldown bar back and fill (scale based)
local barBack = Instance.new("Frame", content)
barBack.Size = UDim2.new(0.96, 0, 0.18, 0)
barBack.Position = UDim2.new(0.02, 0, 0.56, 0)
barBack.BackgroundColor3 = Color3.fromRGB(32,32,48)
barBack.BorderSizePixel = 0
Instance.new("UICorner", barBack).CornerRadius = UDim.new(0, 8)

local barFill = Instance.new("Frame", barBack)
barFill.Size = UDim2.new(0, 0, 1, 0) -- start empty, fills to the right
barFill.Position = UDim2.new(0, 0, 0, 0)
barFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
barFill.BorderSizePixel = 0
Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, 8)

-- compact label for cooldown (small)
local cdLabel = Instance.new("TextLabel", content)
cdLabel.Size = UDim2.new(0.96, 0, 0.16, 0)
cdLabel.Position = UDim2.new(0.02, 0, 0.76, 0)
cdLabel.BackgroundTransparency = 1
cdLabel.Font = Enum.Font.Gotham
cdLabel.TextSize = 13
cdLabel.TextColor3 = Color3.fromRGB(140,170,200)
cdLabel.TextXAlignment = Enum.TextXAlignment.Left
cdLabel.Text = ("Cooldown: %ds"):format(0)

-- collect children for shrink/grow animation
local childTargets = {
	toggle,
	instantBtn,
	barBack,
	cdLabel,
	close,
	title
}

-- simple draggable inertia using mouse (keeps UI responsive)
local dragging = false
local dragStart = Vector2.new()
local startPos = main.Position
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

-- === ANIMATIONS ===
local OPEN_TIME = 0.28
local CHILD_GROW_TIME = 0.22
local CHILD_SHRINK_TIME = 0.14
local CLOSE_TIME = 0.18

local function animateOpen()
	-- start collapsed
	main.Size = UDim2.new(0,0,0,0)
	for _,obj in ipairs(childTargets) do
		if obj and obj:IsA("GuiObject") then
			pcall(function() obj.Size = UDim2.new(0,0,0,0) end)
		end
	end
	barFill.Size = UDim2.new(0,0,1,0)
	cdLabel.Text = ("Cooldown: %ds"):format(0)

	-- grow main
	local tMain = TweenService:Create(main, TweenInfo.new(OPEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = TARGET_SIZE})
	tMain:Play()
	tMain.Completed:Wait()

	-- grow children to intended sizes (scale-based)
	local tweens = {}
	table.insert(tweens, TweenService:Create(toggle, TweenInfo.new(CHILD_GROW_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0.48, 0, 0.32, 0)}))
	table.insert(tweens, TweenService:Create(instantBtn, TweenInfo.new(CHILD_GROW_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0.48, 0, 0.32, 0)}))
	table.insert(tweens, TweenService:Create(barBack, TweenInfo.new(CHILD_GROW_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0.96, 0, 0.18, 0)}))
	table.insert(tweens, TweenService:Create(cdLabel, TweenInfo.new(CHILD_GROW_TIME*0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0.96, 0, 0.16, 0)}))
	table.insert(tweens, TweenService:Create(title, TweenInfo.new(CHILD_GROW_TIME*0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0.62, 0, 1, 0)}))
	table.insert(tweens, TweenService:Create(close, TweenInfo.new(CHILD_GROW_TIME*0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0.08, 0, 0.7, 0)}))
	for _,t in ipairs(tweens) do t:Play() end
	task.wait(CHILD_GROW_TIME * 0.98)
end

local function animateCloseAndDestroy()
	-- disable interactions immediately
	toggle.Active = false; toggle.AutoButtonColor = false
	instantBtn.Active = false; instantBtn.AutoButtonColor = false
	close.Active = false; close.AutoButtonColor = false

	-- shrink children first
	for _,obj in ipairs(childTargets) do
		if obj and obj:IsA("GuiObject") then
			local ok, t = pcall(function()
				return TweenService:Create(obj, TweenInfo.new(CHILD_SHRINK_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0,0,0,0)})
			end)
			if ok and t then t:Play() end
		end
	end
	-- shrink barFill too
	pcall(function()
		TweenService:Create(barFill, TweenInfo.new(CHILD_SHRINK_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0,0,1,0)}):Play()
	end)

	task.wait(CHILD_SHRINK_TIME + 0.02)

	-- then shrink the main panel
	local ok, tMain = pcall(function()
		return TweenService:Create(main, TweenInfo.new(CLOSE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0,0,0,0)})
	end)
	if ok and tMain then tMain:Play() end
	task.wait(CLOSE_TIME + 0.02)

	-- destroy gui
	if screenGui and screenGui.Parent then screenGui:Destroy() end
end

close.Activated:Connect(function()
	animateCloseAndDestroy()
end)

-- === TELEPORT / COOLDOWN LOGIC ===
local running = false
local lastTick = tick()
local lastInstant = 0

local function teleportCycle()
	local checkpoint = getDescendant(Workspace, CHECKPOINT_PATH)
	local portal = getDescendant(Workspace, PORTAL_PATH)
	if checkpoint then teleportTo(checkpoint) end
	task.wait(WAIT_AFTER_CHECKPOINT)
	if portal then teleportTo(portal) end
end

-- auto loop: bar fills from 0->1 (elapsed/COOLDOWN). When hits 1, teleport and reset lastTick.
RunService.RenderStepped:Connect(function()
	if running then
		local elapsed = tick() - lastTick
		local progress = math.clamp(elapsed / COOLDOWN, 0, 1)
		barFill.Size = UDim2.new(progress, 0, 1, 0)
		cdLabel.Text = ("Cooldown: %ds"):format(math.max(0, math.ceil(COOLDOWN - elapsed)))

		if progress >= 1 then
			-- perform teleport and reset timer, keep running true
			lastTick = tick()
			pcall(function() teleportCycle() end)
		end
	else
		-- when not running show empty bar and COOLDOWN label
		barFill.Size = UDim2.new(0, 0, 1, 0)
		cdLabel.Text = ("Cooldown: %ds"):format(COOLDOWN)
	end
end)

toggle.Activated:Connect(function()
	running = not running
	if running then
		toggle.Text = "Stop Auto Teleport"
		toggle.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
		lastTick = tick()
	else
		toggle.Text = "Start Auto Teleport"
		toggle.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
	end
end)

-- Instant TP (does NOT modify lastTick / auto timer)
instantBtn.Activated:Connect(function()
	if tick() - lastInstant < INSTANT_DEBOUNCE then
		-- still cooling, ignore
		return
	end
	lastInstant = tick()
	-- run teleport immediately, but do not change lastTick so auto timer continues uninterrupted
	pcall(function() teleportCycle() end)
end)

-- run open animation on spawn
task.spawn(function()
	animateOpen()
end)
