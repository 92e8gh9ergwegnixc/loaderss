-- ModuleScript: SimpleGuiLib (cliente, fixed + mejoras)
-- Requerir desde un LocalScript: local SimpleGui = require(game.ReplicatedStorage:WaitForChild("SimpleGuiLib"))

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local SimpleGui = {}
SimpleGui.__index = SimpleGui

-- Util: crear tween con delay y protección
local function tweenWithDelay(inst, props, tweenInfo, delay, onComplete)
	delay = delay or 0
	local function doTween()
		if not inst or not inst.Parent then
			if onComplete then pcall(onComplete) end
			return
		end
		local ok, tw = pcall(function()
			return TweenService:Create(inst, tweenInfo, props)
		end)
		if not ok or not tw then
			if onComplete then pcall(onComplete) end
			return
		end
		tw:Play()
		if onComplete then tw.Completed:Connect(onComplete) end
	end
	if delay <= 0 then
		doTween()
	else
		task.delay(delay, doTween)
	end
end

-- Util: get safe PlayerGui (timeout)
local function getPlayerGui(timeout)
	timeout = timeout or 5
	local player = Players.LocalPlayer
	if not player then
		player = Players.PlayerAdded:Wait()
	end
	local ok, pg = pcall(function() return player:WaitForChild("PlayerGui", timeout) end)
	if ok and pg then
		return player, pg
	end
	-- fallback: try to find it repeatedly for a short time
	for i = 1, 20 do
		local found = player:FindFirstChild("PlayerGui")
		if found then return player, found end
		task.wait(0.1)
	end
	warn("[SimpleGuiLib] No se encontró PlayerGui (timeout). GUI puede no cargarse correctamente.")
	return player, player:FindFirstChild("PlayerGui")
end

-- Draggable robusto (mejor manejo mobile/mouse, returns controller)
local function makeDraggable(guiObject, dragHandle)
	dragHandle = dragHandle or guiObject
	local dragging = false
	local startPos = nil
	local startInputPos = nil
	local connBegin, connChanged, connEnd

	local function onInputBegan(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startPos = guiObject.AbsolutePosition
			startInputPos = input.Position
			connChanged = UserInputService.InputChanged:Connect(function(move)
				if not dragging then return end
				if move.UserInputType ~= Enum.UserInputType.MouseMovement and move.UserInputType ~= Enum.UserInputType.Touch then return end
				local delta = Vector2.new(move.Position.X, move.Position.Y) - Vector2.new(startInputPos.X, startInputPos.Y)
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
			end)
			connEnd = UserInputService.InputEnded:Connect(function(endInput)
				if endInput == input or endInput.UserInputType == input.UserInputType then
					dragging = false
					if connChanged then connChanged:Disconnect(); connChanged = nil end
					if connEnd then connEnd:Disconnect(); connEnd = nil end
				end
			end)
		end
	end

	connBegin = dragHandle.InputBegan:Connect(onInputBegan)

	return {
		Disconnect = function()
			if connBegin then connBegin:Disconnect(); connBegin = nil end
			if connChanged then connChanged:Disconnect(); connChanged = nil end
			if connEnd then connEnd:Disconnect(); connEnd = nil end
		end
	}
end

-- Default theme
local DefaultTheme = {
	Background = Color3.fromRGB(30,30,30),
	Accent = Color3.fromRGB(70,120,220),
	Secondary = Color3.fromRGB(60,60,60),
	Text = Color3.fromRGB(255,255,255),
	Corner = 8,
}

-- Helper: create UICorner
local function addCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or DefaultTheme.Corner)
	c.Parent = parent
	return c
end

-- ========== PUBLIC: newWindow ==========
function SimpleGui.newWindow(opts)
	opts = opts or {}
	-- get player & playerGui safely
	local player, playerGui = getPlayerGui(5)
	if not playerGui then
		warn("[SimpleGuiLib] Abortando newWindow: PlayerGui no disponible.")
		return nil
	end

	-- params
	local parent = opts.Parent or playerGui
	local name = opts.Name or "SimpleWindow"
	local size = opts.Size or UDim2.new(0, 340, 0, 220)
	local position = opts.Position or UDim2.new(0.5, -170, 0.5, -110)
	local theme = opts.Theme or DefaultTheme

	-- create screen gui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = name
	screenGui.ResetOnSpawn = false
	screenGui.Parent = parent
	screenGui.DisplayOrder = opts.DisplayOrder or 50

	-- Main window frame
	local frame = Instance.new("Frame")
	frame.Name = "Window"
	frame.Size = size
	frame.Position = position
	frame.AnchorPoint = Vector2.new(0,0)
	frame.BackgroundColor3 = theme.Background
	frame.BorderSizePixel = 0
	frame.Parent = screenGui
	frame.Visible = false
	addCorner(frame, theme.Corner)

	-- Shadow container (optional)
	local shadow = Instance.new("Frame")
	shadow.Name = "Shadow"
	shadow.Size = UDim2.new(1, 6, 1, 6)
	shadow.Position = UDim2.new(0, -3, 0, -3)
	shadow.BackgroundTransparency = 0.85
	shadow.BackgroundColor3 = Color3.fromRGB(0,0,0)
	shadow.BorderSizePixel = 0
	shadow.ZIndex = frame.ZIndex - 1
	shadow.Parent = frame
	addCorner(shadow, theme.Corner + 2)

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 30)
	titleBar.Position = UDim2.new(0, 0, 0, 0)
	titleBar.BackgroundTransparency = 1
	titleBar.Parent = frame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -120, 1, 0)
	titleLabel.Position = UDim2.new(0, 12, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = opts.Title or "Simple GUI"
	titleLabel.TextColor3 = theme.Text
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Font = Enum.Font.GothamSemibold
	titleLabel.TextSize = 15
	titleLabel.Parent = titleBar

	-- Tab bar (left side of title area)
	local tabBar = Instance.new("Frame")
	tabBar.Name = "TabBar"
	tabBar.Size = UDim2.new(1, -120, 1, 0)
	tabBar.Position = UDim2.new(0, 12, 0, 0)
	tabBar.BackgroundTransparency = 1
	tabBar.Parent = titleBar

	-- Controls: close button and mini toggle
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "Close"
	closeBtn.Size = UDim2.new(0, 60, 0, 22)
	closeBtn.Position = UDim2.new(1, -70, 0, 4)
	closeBtn.AnchorPoint = Vector2.new(0,0)
	closeBtn.Text = "Cerrar"
	closeBtn.Font = Enum.Font.Gotham
	closeBtn.TextSize = 12
	closeBtn.BackgroundColor3 = Color3.fromRGB(200,60,60)
	closeBtn.TextColor3 = theme.Text
	closeBtn.Parent = titleBar
	addCorner(closeBtn, 6)

	local miniCube = Instance.new("TextButton")
	miniCube.Name = "MiniCube"
	miniCube.Size = UDim2.new(0, 28, 0, 28)
	miniCube.Position = UDim2.new(1, -34, 0, 1)
	miniCube.AnchorPoint = Vector2.new(0,0)
	miniCube.Text = "+"
	miniCube.Font = Enum.Font.GothamBold
	miniCube.TextSize = 18
	miniCube.BackgroundColor3 = theme.Accent
	miniCube.TextColor3 = theme.Text
	miniCube.Parent = titleBar
	addCorner(miniCube, 6)
	miniCube.ZIndex = frame.ZIndex + 2

	-- Content area: use ScrollingFrame so many buttons become scrollables
	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "ContentHolder"
	contentFrame.Position = UDim2.new(0, 8, 0, 36)
	contentFrame.Size = UDim2.new(1, -16, 1, -44)
	contentFrame.BackgroundTransparency = 1
	contentFrame.Parent = frame
	addCorner(contentFrame, theme.Corner - 2)

	local pagesFolder = Instance.new("Folder", contentFrame)
	pagesFolder.Name = "Pages"

	-- Tab selector area (below title) to show tab buttons
	local tabsHolder = Instance.new("Frame")
	tabsHolder.Name = "TabsHolder"
	tabsHolder.Size = UDim2.new(1, 0, 0, 28)
	tabsHolder.Position = UDim2.new(0, 8, 0, 32)
	tabsHolder.BackgroundTransparency = 1
	tabsHolder.Parent = contentFrame

	local tabsLayout = Instance.new("UIListLayout", tabsHolder)
	tabsLayout.FillDirection = Enum.FillDirection.Horizontal
	tabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabsLayout.Padding = UDim.new(0, 6)

	-- Container to hold actual page frames (stacked)
	local pageContainer = Instance.new("Frame")
	pageContainer.Name = "PageContainer"
	pageContainer.Size = UDim2.new(1, -16, 1, -64)
	pageContainer.Position = UDim2.new(0, 8, 0, 64)
	pageContainer.BackgroundTransparency = 1
	pageContainer.Parent = contentFrame

	-- Internal state
	local self = setmetatable({
		ScreenGui = screenGui,
		Frame = frame,
		ContentHolder = contentFrame,
		PageContainer = pageContainer,
		Pages = {}, -- {name = {TabBtn =..., ScrollingFrame =...}}
		ActivePage = nil,
		WindowDragController = nil,
		MiniDragController = nil,
		IsOpen = false,
		Theme = theme,
		Connections = {},
	}, SimpleGui)

	-- Create a new page (tab)
	function self:AddTab(tabName)
		if not tabName then tabName = "Tab"..(#self.Pages + 1) end
		-- Tab button
		local tabBtn = Instance.new("TextButton")
		tabBtn.Size = UDim2.new(0, 90, 1, 0)
		tabBtn.BackgroundColor3 = self.Theme.Secondary
		tabBtn.Text = tabName
		tabBtn.TextColor3 = self.Theme.Text
		tabBtn.Font = Enum.Font.Gotham
		tabBtn.TextSize = 13
		tabBtn.Parent = tabsHolder
		addCorner(tabBtn, 6)

		-- Page scrolling frame
		local page = Instance.new("ScrollingFrame")
		page.Size = UDim2.new(1, 0, 1, 0)
		page.Position = UDim2.new(0,0,0,0)
		page.ScrollBarThickness = 6
		page.CanvasSize = UDim2.new(0, 0, 0, 0)
		page.BackgroundTransparency = 1
		page.Parent = pageContainer

		-- content frame inside scrolling to pad
		local inner = Instance.new("Frame")
		inner.Size = UDim2.new(1, -12, 0, 0)
		inner.Position = UDim2.new(0, 6, 0, 6)
		inner.BackgroundTransparency = 1
		inner.Parent = page

		local layout = Instance.new("UIListLayout", inner)
		layout.Padding = UDim.new(0, 8)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Left

		-- Auto-resize canvas
		local function updateCanvas()
			page.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 16)
		end
		local conn = layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
		table.insert(self.Connections, conn)
		updateCanvas()

		-- store
		self.Pages[tabName] = {
			TabBtn = tabBtn,
			Page = page,
			Inner = inner,
			Layout = layout,
		}

		-- click to switch
		tabBtn.MouseButton1Click:Connect(function()
			self:SwitchToTab(tabName)
		end)

		-- if first tab, activate
		if not self.ActivePage then
			self:SwitchToTab(tabName)
		end

		return tabName
	end

	-- switch page
	function self:SwitchToTab(tabName)
		local p = self.Pages[tabName]
		if not p then return end
		for name, info in pairs(self.Pages) do
			info.Page.Visible = (name == tabName)
			-- visual indicator for tab button
			info.TabBtn.BackgroundColor3 = (name == tabName) and self.Theme.Accent or self.Theme.Secondary
		end
		self.ActivePage = tabName
	end

	-- Add a generic label to active tab
	function self:AddLabel(text)
		if not self.ActivePage then self:AddTab("Main") end
		local page = self.Pages[self.ActivePage]
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 0, 22)
		lbl.BackgroundTransparency = 1
		lbl.Text = text or ""
		lbl.TextColor3 = self.Theme.Text
		lbl.Font = Enum.Font.Gotham
		lbl.TextSize = 14
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Parent = page.Inner
		return lbl
	end

	-- AddButton to active or specified tab
	function self:AddButton(labelText, callback, options)
		options = options or {}
		local tab = options.Tab or self.ActivePage
		if not tab then tab = self:AddTab("Main") end
		local page = self.Pages[tab]
		if not page then return end

		local btn = Instance.new("TextButton")
		btn.Size = options.Size or UDim2.new(1, -6, 0, 36)
		btn.BackgroundColor3 = options.Color or self.Theme.Secondary
		btn.Text = labelText or "Button"
		btn.TextColor3 = options.TextColor or self.Theme.Text
		btn.Font = options.Font or Enum.Font.Gotham
		btn.TextSize = options.TextSize or 14
		btn.Parent = page.Inner
		addCorner(btn, 6)

		-- click animation
		btn.MouseButton1Click:Connect(function()
			local orig = btn.Size
			local clickTween = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			tweenWithDelay(btn, {Size = UDim2.new(orig.X.Scale, orig.X.Offset - 6, orig.Y.Scale, orig.Y.Offset - 2)}, clickTween, 0, function()
				tweenWithDelay(btn, {Size = orig}, clickTween, 0)
			end)
			if callback then
				local ok, err = pcall(function() callback() end)
				if not ok then warn("SimpleGuiLib button callback error:", err) end
			end
		end)

		return btn
	end

	-- AddToggle (boolean)
	function self:AddToggle(labelText, default, callback, options)
		options = options or {}
		local tab = options.Tab or self.ActivePage or self:AddTab("Main")
		local page = self.Pages[tab]
		if not page then return end

		local container = Instance.new("Frame")
		container.Size = UDim2.new(1, -6, 0, 36)
		container.BackgroundTransparency = 1
		container.Parent = page.Inner

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -60, 1, 0)
		lbl.Position = UDim2.new(0, 4, 0, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = labelText or "Toggle"
		lbl.TextColor3 = self.Theme.Text
		lbl.Font = Enum.Font.Gotham
		lbl.TextSize = 14
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Parent = container

		local toggleBtn = Instance.new("TextButton")
		toggleBtn.Size = UDim2.new(0, 40, 0, 24)
		toggleBtn.Position = UDim2.new(1, -46, 0.5, -12)
		toggleBtn.BackgroundColor3 = default and self.Theme.Accent or self.Theme.Secondary
		toggleBtn.Text = default and "ON" or "OFF"
		toggleBtn.TextColor3 = self.Theme.Text
		toggleBtn.Font = Enum.Font.Gotham
		toggleBtn.TextSize = 12
		toggleBtn.Parent = container
		addCorner(toggleBtn, 6)

		local state = default and true or false
		toggleBtn.MouseButton1Click:Connect(function()
			state = not state
			toggleBtn.BackgroundColor3 = state and self.Theme.Accent or self.Theme.Secondary
			toggleBtn.Text = state and "ON" or "OFF"
			if callback then
				local ok, err = pcall(function() callback(state) end)
				if not ok then warn("SimpleGuiLib toggle callback error:", err) end
			end
		end)

		return {
			Container = container,
			Get = function() return state end,
			Set = function(v)
				state = not not v
				toggleBtn.BackgroundColor3 = state and self.Theme.Accent or self.Theme.Secondary
				toggleBtn.Text = state and "ON" or "OFF"
			end
		}
	end

	-- AddSlider (simple horizontal)
	function self:AddSlider(labelText, min, max, default, callback, options)
		options = options or {}
		local tab = options.Tab or self.ActivePage or self:AddTab("Main")
		local page = self.Pages[tab]
		if not page then return end

		min = min or 0
		max = max or 100
		default = default or min

		local container = Instance.new("Frame")
		container.Size = UDim2.new(1, -6, 0, 48)
		container.BackgroundTransparency = 1
		container.Parent = page.Inner

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 0, 18)
		lbl.BackgroundTransparency = 1
		lbl.Text = (labelText or "Slider") .. " : " .. tostring(default)
		lbl.TextColor3 = self.Theme.Text
		lbl.Font = Enum.Font.Gotham
		lbl.TextSize = 13
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Parent = container

		local track = Instance.new("Frame")
		track.Size = UDim2.new(1, -12, 0, 14)
		track.Position = UDim2.new(0, 6, 0, 26)
		track.BackgroundColor3 = self.Theme.Secondary
		track.Parent = container
		addCorner(track, 6)

		local fill = Instance.new("Frame")
		fill.Size = UDim2.new( (default - min) / math.max(1, max - min), 0, 1, 0)
		fill.BackgroundColor3 = self.Theme.Accent
		fill.Parent = track
		addCorner(fill, 6)

		local knob = Instance.new("ImageButton")
		knob.Size = UDim2.new(0, 18, 0, 18)
		knob.Position = UDim2.new(fill.Size.X.Scale, -9, 0.5, -9)
		knob.AnchorPoint = Vector2.new(0,0)
		knob.Image = ""
		knob.BackgroundColor3 = Color3.fromRGB(240,240,240)
		knob.Parent = track
		addCorner(knob, 10)

		local dragging = false
		local function setValueFromX(x)
			local r = math.clamp(x / track.AbsoluteSize.X, 0, 1)
			local val = min + (max - min) * r
			fill.Size = UDim2.new(r, 0, 1, 0)
			knob.Position = UDim2.new(r, -9, 0.5, -9)
			lbl.Text = (labelText or "Slider") .. " : " .. string.format("%.2f", val)
			if callback then
				pcall(callback, val)
			end
		end

		knob.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
			end
		end)
		knob.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local relX = input.Position.X - track.AbsolutePosition.X
				setValueFromX(relX)
			end
		end)

		-- click on track to set
		track.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				local relX = input.Position.X - track.AbsolutePosition.X
				setValueFromX(relX)
			end
		end)

		-- init value
		setValueFromX( (default - min) / math.max(1, max-min) * track.AbsoluteSize.X )

		return {
			Container = container,
			Set = function(v)
				local r = math.clamp((v - min) / math.max(1, max-min), 0, 1)
				fill.Size = UDim2.new(r,0,1,0)
				knob.Position = UDim2.new(r, -9, 0.5, -9)
			end
		}
	end

	-- Open / Close / Toggle with animations
	local openTweenInfo = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local closeTweenInfo = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local clickTweenInfo = TweenInfo.new(0.10, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

	function self:Open(delay)
		delay = delay or 0
		if self.IsOpen then return end
		self.IsOpen = true
		frame.Visible = true
		frame.Size = UDim2.new(0, 0, 0, 0)
		frame.BackgroundTransparency = 1
		tweenWithDelay(frame, {Size = size, BackgroundTransparency = 0}, openTweenInfo, delay)
		-- mini visual
		tweenWithDelay(miniCube, {Rotation = 180}, openTweenInfo, delay, function()
			miniCube.Text = "-"
			miniCube.Rotation = 0
		end)
	end

	function self:Close(delay)
		delay = delay or 0
		if not self.IsOpen then return end
		self.IsOpen = false
		tweenWithDelay(frame, {Size = UDim2.new(0,0,0,0), BackgroundTransparency = 1}, closeTweenInfo, delay, function()
			frame.Visible = false
			frame.Size = size
		end)
		tweenWithDelay(miniCube, {Size = UDim2.new(0, 34, 0, 34)}, closeTweenInfo, delay, function()
			tweenWithDelay(miniCube, {Size = UDim2.new(0, 28, 0, 28)}, closeTweenInfo, 0)
		end)
	end

	function self:Toggle()
		if self.IsOpen then self:Close() else self:Open() end
	end

	-- Close button behavior
	closeBtn.MouseButton1Click:Connect(function()
		tweenWithDelay(closeBtn, {Size = UDim2.new(closeBtn.Size.X.Scale, closeBtn.Size.X.Offset - 6, closeBtn.Size.Y.Scale, closeBtn.Size.Y.Offset - 2)}, clickTweenInfo, 0, function()
			tweenWithDelay(closeBtn, {Size = UDim2.new(closeBtn.Size.X.Scale, closeBtn.Size.X.Offset + 6, closeBtn.Size.Y.Scale, closeBtn.Size.Y.Offset + 2)}, clickTweenInfo, 0, function()
				self:Close()
			end)
		end)
	end)

	-- Mini cube toggle & draggable
	miniCube.MouseButton1Click:Connect(function()
		local originalSize = miniCube.Size
		tweenWithDelay(miniCube, {Size = UDim2.new(0, originalSize.X.Offset - 6, 0, originalSize.Y.Offset - 6)}, clickTweenInfo, 0, function()
			tweenWithDelay(miniCube, {Size = originalSize}, clickTweenInfo, 0)
		end)
		self:Toggle()
	end)

	-- Draggables
	self.WindowDragController = makeDraggable(frame, titleBar)
	self.MiniDragController = makeDraggable(miniCube, miniCube)

	-- Cleanup / Destroy
	function self:Destroy()
		-- disconnect stored conns
		for _, c in ipairs(self.Connections) do
			if c and typeof(c) == "RBXScriptConnection" then
				pcall(function() c:Disconnect() end)
			end
		end
		if self.WindowDragController then pcall(function() self.WindowDragController:Disconnect() end) end
		if self.MiniDragController then pcall(function() self.MiniDragController:Disconnect() end) end
		if self.ScreenGui and self.ScreenGui.Parent then
			self.ScreenGui:Destroy()
		end
		-- clear table
		for k in pairs(self) do self[k] = nil end
	end

	-- Theme setter
	function self:SetTheme(t)
		self.Theme = t or self.Theme
		-- TODO: refresh visuals (basic)
		frame.BackgroundColor3 = self.Theme.Background
		miniCube.BackgroundColor3 = self.Theme.Accent
	end

	-- Expose some convenience setters
	function self:SetOpenTweenInfo(ti) openTweenInfo = ti end
	function self:SetCloseTweenInfo(ti) closeTweenInfo = ti end
	function self:SetClickTweenInfo(ti) clickTweenInfo = ti end

	-- Return controller
	return self
end

return SimpleGui
