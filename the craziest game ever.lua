--// Script: Interfaz moderna Skip & Tween con animaciones mejoradas
--// Colocar en StarterPlayerScripts como LocalScript

local Jugadores = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UsuarioInput = game:GetService("UserInputService")

local jugador = Jugadores.LocalPlayer
local personaje = jugador.Character or jugador.CharacterAdded:Wait()
local raizHumanoide = personaje:WaitForChild("HumanoidRootPart")

-- GUI principal
local pantallaGui = Instance.new("ScreenGui")
pantallaGui.Name = "SkipTweenGUI"
pantallaGui.ResetOnSpawn = false
pantallaGui.IgnoreGuiInset = true
pantallaGui.Parent = jugador:WaitForChild("PlayerGui")

local marcoPrincipal = Instance.new("Frame")
marcoPrincipal.Name = "MarcoPrincipal"
marcoPrincipal.Size = UDim2.new(0, 320, 0, 180)
marcoPrincipal.Position = UDim2.new(0.5, -160, 1.2, 0)
marcoPrincipal.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
marcoPrincipal.BorderSizePixel = 0
marcoPrincipal.Active = true
marcoPrincipal.Parent = pantallaGui

Instance.new("UICorner", marcoPrincipal).CornerRadius = UDim.new(0, 12)

-- Barra de título
local barraTitulo = Instance.new("Frame")
barraTitulo.Size = UDim2.new(1, 0, 0, 35)
barraTitulo.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
barraTitulo.BorderSizePixel = 0
barraTitulo.Parent = marcoPrincipal
Instance.new("UICorner", barraTitulo).CornerRadius = UDim.new(0, 12)

local titulo = Instance.new("TextLabel")
titulo.Size = UDim2.new(1, -40, 1, 0)
titulo.Position = UDim2.new(0, 10, 0, 0)
titulo.BackgroundTransparency = 1
titulo.Text = "The Craziest Game Ever"
titulo.Font = Enum.Font.GothamBold
titulo.TextSize = 22
titulo.TextColor3 = Color3.fromRGB(255, 255, 255)
titulo.TextXAlignment = Enum.TextXAlignment.Left
titulo.Parent = barraTitulo

local botonCerrar = Instance.new("TextButton")
botonCerrar.Size = UDim2.new(0, 35, 0, 35)
botonCerrar.Position = UDim2.new(1, -40, 0.5, -17)
botonCerrar.Text = "×"
botonCerrar.TextColor3 = Color3.new(1, 1, 1)
botonCerrar.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
botonCerrar.BorderSizePixel = 0
botonCerrar.Font = Enum.Font.GothamBold
botonCerrar.TextSize = 28
botonCerrar.Parent = barraTitulo
Instance.new("UICorner", botonCerrar).CornerRadius = UDim.new(0, 8)

-- Función para crear botones
local function crearBoton(texto, posicionY, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -40, 0, 45)
    btn.Position = UDim2.new(0, 20, 0, posicionY)
    btn.Text = texto
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 20
    btn.AutoButtonColor = false
    btn.Parent = marcoPrincipal
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    return btn
end

local botonSkip = crearBoton("Saltar Nivel", 50, Color3.fromRGB(255, 85, 85))
local botonAuto = crearBoton("Auto: OFF", 110, Color3.fromRGB(70, 70, 70))

-- Tween genérico
local function tween(obj, props, tiempo, estilo, direccion)
    local info = TweenInfo.new(tiempo or 0.3, estilo or Enum.EasingStyle.Quad, direccion or Enum.EasingDirection.Out)
    TweenService:Create(obj, info, props):Play()
end

-- Animación entrada
tween(marcoPrincipal, {Position = UDim2.new(0.5, -160, 0.7, -90)}, 0.6, Enum.EasingStyle.Back)

-- Efecto de clic (achicar desde centro) con bloqueo anti-spam
local function efectoClic(boton, callback)
    if boton:GetAttribute("ClickEnCurso") then return end
    boton:SetAttribute("ClickEnCurso", true)

    local tamanoOriginal = boton.Size
    local tamanoPeque = UDim2.new(tamanoOriginal.X.Scale, tamanoOriginal.X.Offset - 6,
                                  tamanoOriginal.Y.Scale, tamanoOriginal.Y.Offset - 3)

    local offsetX = (tamanoOriginal.X.Offset - tamanoPeque.X.Offset) / 2
    local offsetY = (tamanoOriginal.Y.Offset - tamanoPeque.Y.Offset) / 2

    local posOriginal = boton.Position
    local posPeque = UDim2.new(posOriginal.X.Scale, posOriginal.X.Offset + offsetX,
                               posOriginal.Y.Scale, posOriginal.Y.Offset + offsetY)

    tween(boton, {Size = tamanoPeque, Position = posPeque}, 0.07, Enum.EasingStyle.Quad)
    task.delay(0.1, function()
        tween(boton, {Size = tamanoOriginal, Position = posOriginal}, 0.1)
        task.delay(0.12, function()
            boton:SetAttribute("ClickEnCurso", false)
            if callback then callback() end
        end)
    end)
end

-- Funciones skip
local function tweenParteA(parte, cframeObjetivo)
    tween(parte, {CFrame = cframeObjetivo}, 0.1, Enum.EasingStyle.Linear)
end

local function eliminarPuntos()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "Dot" then
            obj:Destroy()
        end
    end
end

local function tweenMonedas()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "CoinDot" then
            tweenParteA(obj, raizHumanoide.CFrame)
        end
    end
end

local function tweenCheckpointFinal()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "FinalCheckpoint" then
            tweenParteA(obj, raizHumanoide.CFrame)
            break
        end
    end
end

local function ejecutarSkip()
    eliminarPuntos()
    tweenMonedas()
    tweenCheckpointFinal()
end

-- Botones
botonCerrar.MouseButton1Click:Connect(function()
    efectoClic(botonCerrar, function()
        tween(marcoPrincipal, {Position = UDim2.new(0.5, -160, 1.5, 0)}, 0.5)
        task.delay(0.5, function()
            pantallaGui:Destroy()
        end)
    end)
end)

botonSkip.MouseButton1Click:Connect(function()
    efectoClic(botonSkip, function()
        ejecutarSkip()
    end)
end)

local autoActivado = false

botonAuto.MouseButton1Click:Connect(function()
    efectoClic(botonAuto, function()
        autoActivado = not autoActivado
        botonAuto.Text = autoActivado and "Auto: ON" or "Auto: OFF"
        tween(botonAuto, {
            BackgroundColor3 = autoActivado and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(70, 70, 70)
        }, 0.2)
    end)
end)

-- Bucle auto
RunService.RenderStepped:Connect(function()
    if autoActivado then
        ejecutarSkip()
    end
end)

-- Drag con inercia (más lento que el ratón)
local arrastrando = false
local offset = Vector2.new()

barraTitulo.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        arrastrando = true
        offset = Vector2.new(input.Position.X - marcoPrincipal.AbsolutePosition.X,
                             input.Position.Y - marcoPrincipal.AbsolutePosition.Y)
    end
end)

barraTitulo.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        arrastrando = false
    end
end)

RunService.RenderStepped:Connect(function()
    if arrastrando then
        local mouse = UsuarioInput:GetMouseLocation()
        local objetivo = UDim2.new(0, mouse.X - offset.X, 0, mouse.Y - offset.Y)
        marcoPrincipal.Position = marcoPrincipal.Position:Lerp(objetivo, 0.05)
    end
end)
