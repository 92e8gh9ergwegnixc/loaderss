-- ModuleScript: SimpleGuiLib
-- Requerir desde un LocalScript: local SimpleGui = require(path.to.SimpleGuiLib)

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local SimpleGui = {}
SimpleGui.__index = SimpleGui

-- Helper: crear Tween con delay
local function tweenWithDelay(inst, props, tweenInfo, delay, onComplete)
	delay = delay or 0
	if delay <= 0 then
		local tw = TweenService:Create(inst, tweenInfo, props)
		tw:Play()
		if onComplete then tw.Completed:Connect(onComplete) end
	else
		task.delay(delay, function()
			local tw = TweenService:Create(inst, tweenInfo, props)
			tw:Play()
			if onComplete then tw.Completed:Connect(onComplete) end
		end)
	end
end

-- Helper: make draggable (mouse + touch)
local function makeDraggable(guiObject, dragHandle)
	dragHandle = dragHandle or guiObject
	local dragging = false
	local startPos
	local startMousePos
	local connectionInput, connectionMove, connectionRelease

	local function onInputBegan(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startPos = guiObject.AbsolutePosition
			startMousePos = Vector2.new(input.Position.X, input.Position.Y)
			connectionMove = UserInputService.InputChanged:Connect(function(move)
				if dragging and (move.UserInputType == Enum.UserInputType.MouseMovement or move.UserInputType == Enum.UserInputType.Touch) then
					local delta = Vector2.new(move.Position.X, move.Position.Y) - startMousePos
					-- Convert AbsolutePosition -> Position proportionally relative to parent's size
					local parent = guiObject.Parent
					if parent and parent:IsA("GuiObject") then
						local newAbs = startPos + delta
						local parentSize = parent.AbsoluteSize
						if parentSize.X > 0 and parentSize.Y > 0 then
							local newPos = UDim2.new(0, math.clamp(newAbs.X, 0, parentSize.X - guiObject.AbsoluteSize.X),
								0, math.clamp(newAbs.Y, 0, parentSize.Y - guiObject.AbsoluteSize.Y))
							guiObject.Position = newPos
						end
					else
						guiObject.Position = UDim2.new(0, startPos.X + delta.X, 0, startPos.Y + delta.Y)
					end
				end
			end)
			connectionRelease = UserInputService.InputEnded:Connect(function(endInput)
				if endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
					dragging = false
					if connectionMove then connectionMove:Disconnect(); connectionMove = nil end
					if connectionRelease then connectionRelease:Disconnect(); connectionRelease = nil end
				end
			end)
		end
	end

	connectionInput = dragHandle.InputBegan:Connect(onInputBegan)

	-- Return a simple controller to disconnect when needed
	return {
		Disconnect = function()
			if connectionInput then connectionInput:Disconnect() end
			if connectionMove then connectionMove:Disconnect() end
			if connectionRelease then connectionRelease:Disconnect() end
		end
	}
end

-- Create a window with a title and optional parent (defaults to PlayerGui)
function SimpleGui.newWindow(opts)
	opts = opts or {}
	local player = game.Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local parent = opts.Parent or playerGui
	local name = opts.Name or "SimpleWindow"
	local size = opts.Size or UDim2.new(0, 300, 0, 180)
	local position = opts.Position or UDim2.new(0.5, -150, 0.5, -90)

	-- ScreenGui container
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = name
	screenGui.ResetOnSpawn = false
	screenGui.Parent = parent

	-- Main frame
	local frame = Instance.new("Frame")
	frame.Name = "Window"
	frame.Size = size
	frame.Position = position
	frame.AnchorPoint = Vector2.new(0,0)
	frame.BackgroundColor3 = opts.BackgroundColor or Color3.fromRGB(30, 30, 30)
	frame.BorderSizePixel = 0
	frame.Parent = screenGui
	frame.Visible = false -- start closed

	-- UI styling
	local corner = Instance.new("UICorner", frame)
	corner.CornerRadius = UDim.new(0, 8)

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 28)
	titleBar.Position = UDim2.new(0, 0, 0, 0)
	titleBar.BackgroundTransparency = 1
	titleBar.Parent = frame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -60, 1, 0)
	titleLabel.Position = UDim2.new(0, 8, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = opts.Title or "Simple GUI"
	titleLabel.TextColor3 = Color3.fromRGB(255,255,255)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Font = Enum.Font.GothamSemibold
	titleLabel.TextSize = 14
	titleLabel.Parent = titleBar

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "Close"
	closeBtn.Size = UDim2.new(0, 48, 1, -6)
	closeBtn.Position = UDim2.new(1, -52, 0, 3)
	closeBtn.AnchorPoint = Vector2.new(0,0)
	closeBtn.Text = "Cerrar"
	closeBtn.Font = Enum.Font.Gotham
	closeBtn.TextSize = 12
	closeBtn.BackgroundColor3 = Color3.fromRGB(200,60,60)
	closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
	closeBtn.AutoButtonColor = true
	closeBtn.Parent = titleBar
	local closeCorner = Instance.new("UICorner", closeBtn)
	closeCorner.CornerRadius = UDim.new(0,6)

	-- Content area
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Position = UDim2.new(0, 8, 0, 36)
	content.Size = UDim2.new(1, -16, 1, -44)
	content.BackgroundTransparency = 1
	content.Parent = frame

	-- Mini cube toggle: small draggable button to open/close
	local miniCube = Instance.new("TextButton")
	miniCube.Name = "MiniCube"
	miniCube.Size = UDim2.new(0, 36, 0, 36)
	miniCube.Position = UDim2.new(0, 8, 0, 8)
	miniCube.BackgroundColor3 = opts.MiniColor or Color3.fromRGB(45, 45, 45)
	miniCube.Text = "+"
	miniCube.Font = Enum.Font.GothamBold
	miniCube.TextSize = 20
	miniCube.TextColor3 = Color3.fromRGB(255,255,255)
	miniCube.Parent = screenGui
	local miniCorner = Instance.new("UICorner", miniCube)
	miniCorner.CornerRadius = UDim.new(0,6)
	miniCube.ZIndex = 10

	-- Draggables
	local windowDragController = makeDraggable(frame, titleBar)
	local miniDragController = makeDraggable(miniCube, miniCube)

	-- Container for buttons created by user
	local buttonFolder = Instance.new("Folder", content)
	buttonFolder.Name = "Buttons"

	-- Default tween info
	local openTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local closeTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local clickTweenInfo = TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

	-- Internal state
	local self = setmetatable({
		ScreenGui = screenGui,
		Frame = frame,
		Content = content,
		CloseBtn = closeBtn,
		MiniCube = miniCube,
		OpenTweenInfo = openTweenInfo,
		CloseTweenInfo = closeTweenInfo,
		ClickTweenInfo = clickTweenInfo,
		IsOpen = false,
		ButtonFolder = buttonFolder,
		WindowDragController = windowDragController,
		MiniDragController = miniDragController,
	}, SimpleGui)

	-- Functions: open/close/toggle with animations and optional delay
	function self:Open(delay)
		delay = delay or 0
		if self.IsOpen then return end
		self.IsOpen = true
		frame.Visible = true
		-- start small and fade in
		frame.Size = UDim2.new(0, 0, 0, 0)
		frame.Position = position -- keep target position
		frame.BackgroundTransparency = 1
		-- animate open with delay support
		tweenWithDelay(frame, {Size = size, BackgroundTransparency = 0}, self.OpenTweenInfo, delay, function()
			-- optional callback after open
		end)
		-- mini cube icon rotate -> becomes "-" sign
		tweenWithDelay(miniCube, {Rotation = 180}, self.OpenTweenInfo, delay, function()
			miniCube.Text = "-"
			miniCube.Rotation = 0
		end)
	end

	function self:Close(delay)
		delay = delay or 0
		if not self.IsOpen then return end
		self.IsOpen = false
		-- animate close (shrink + fade)
		tweenWithDelay(frame, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1}, self.CloseTweenInfo, delay, function()
			frame.Visible = false
			-- restore size for next open
			frame.Size = size
		end)
		-- mini cube animation: pulse
		tweenWithDelay(miniCube, {Size = UDim2.new(0, 44, 0, 44)}, self.CloseTweenInfo, delay, function()
			tweenWithDelay(miniCube, {Size = UDim2.new(0, 36, 0, 36)}, self.CloseTweenInfo, 0)
		end)
	end

	function self:Toggle()
		if self.IsOpen then
			self:Close()
		else
			self:Open()
		end
	end

	-- Clicking behaviors
	closeBtn.MouseButton1Click:Connect(function()
		-- click animation
		tweenWithDelay(closeBtn, {Size = UDim2.new(closeBtn.Size.X.Scale, closeBtn.Size.X.Offset - 6, closeBtn.Size.Y.Scale, closeBtn.Size.Y.Offset - 2)}, clickTweenInfo, 0, function()
			tweenWithDelay(closeBtn, {Size = UDim2.new(closeBtn.Size.X.Scale, closeBtn.Size.X.Offset + 6, closeBtn.Size.Y.Scale, closeBtn.Size.Y.Offset + 2)}, clickTweenInfo, 0, function()
				-- finally close
				self:Close()
			end)
		end)
	end)

	miniCube.MouseButton1Click:Connect(function()
		-- small click animation + toggle
		local originalSize = miniCube.Size
		tweenWithDelay(miniCube, {Size = UDim2.new(0, originalSize.X.Offset - 6, 0, originalSize.Y.Offset - 6)}, clickTweenInfo, 0, function()
			tweenWithDelay(miniCube, {Size = originalSize}, clickTweenInfo, 0)
		end)
		self:Toggle()
	end)

	-- Helper to add a button to the window with click animation & callback
	function self:AddButton(labelText, callback, options)
		options = options or {}
		local btn = Instance.new("TextButton")
		btn.Size = options.Size or UDim2.new(1, 0, 0, 32)
		btn.Position = UDim2.new(0, 0, 0, #self.ButtonFolder:GetChildren() * 36)
		btn.BackgroundColor3 = options.Color or Color3.fromRGB(60, 60, 60)
		btn.Text = labelText or "Button"
		btn.TextColor3 = options.TextColor or Color3.fromRGB(255,255,255)
		btn.Font = options.Font or Enum.Font.Gotham
		btn.TextSize = options.TextSize or 14
		btn.Parent = self.ButtonFolder
		local corner = Instance.new("UICorner", btn)
		corner.CornerRadius = UDim.new(0,6)
		-- click animation
		btn.MouseButton1Click:Connect(function()
			local orig = btn.Size
			tweenWithDelay(btn, {Size = UDim2.new(orig.X.Scale, orig.X.Offset - 6, orig.Y.Scale, orig.Y.Offset - 2)}, self.ClickTweenInfo, 0, function()
				tweenWithDelay(btn, {Size = orig}, self.ClickTweenInfo, 0)
			end)
			if callback then
				-- Execute callback safely
				local ok, err = pcall(function() callback() end)
				if not ok then
					warn("SimpleGuiLib button callback error:", err)
				end
			end
		end)
		return btn
	end

	-- Optional: function to destroy/cleanup
	function self:Destroy()
		if self.WindowDragController then self.WindowDragController:Disconnect() end
		if self.MiniDragController then self.MiniDragController:Disconnect() end
		screenGui:Destroy()
	end

	-- Expose some small config functions
	function self:SetOpenTweenInfo(ti) self.OpenTweenInfo = ti end
	function self:SetCloseTweenInfo(ti) self.CloseTweenInfo = ti
	function self:SetClickTweenInfo(ti) self.ClickTweenInfo = ti

	return self
end

return SimpleGui
