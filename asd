local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Tween = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera
local Settings = getgenv().spectra.SilentAim
local SpeedSettings = getgenv().spectra.Speed
local MiscSettings = getgenv().spectra.Misc
local ColorMap = {
    Red = Color3.fromRGB(255, 0, 0),
    Green = Color3.fromRGB(0, 255, 0),
    Blue = Color3.fromRGB(0, 0, 255),
    White = Color3.fromRGB(255, 255, 255),
    Black = Color3.fromRGB(0, 0, 0),
    Yellow = Color3.fromRGB(255, 255, 0),
    Purple = Color3.fromRGB(170, 0, 255),
    Pink = Color3.fromRGB(255, 105, 180),
    Cyan = Color3.fromRGB(0, 255, 255),
    Orange = Color3.fromRGB(255, 165, 0),
    Grey = Color3.fromRGB(128, 128, 128),
    LightGrey = Color3.fromRGB(192, 192, 192),
    DarkGrey = Color3.fromRGB(64, 64, 64),
    Brown = Color3.fromRGB(139, 69, 19),
    Maroon = Color3.fromRGB(128, 0, 0),
    Navy = Color3.fromRGB(0, 0, 128),
    Teal = Color3.fromRGB(0, 128, 128),
    Lime = Color3.fromRGB(0, 255, 0),
    Olive = Color3.fromRGB(128, 128, 0),
    Beige = Color3.fromRGB(245, 245, 220)
}

if MiscSettings.Intro then
    local Flash = Instance.new("ColorCorrectionEffect")
    local Blur = Instance.new("BlurEffect")
    Flash.Parent = Lighting
    Blur.Parent = Lighting
    Blur.Size = 0
    local Gui = Instance.new("ScreenGui")
    Gui.Name = "IntroGui"
    Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Gui.IgnoreGuiInset = true
    Gui.Parent = CoreGui
    local function CreateSnowflake()
        local flake = Instance.new("Frame")
        local size = math.random(2, 4)
        flake.Size = UDim2.new(0, size, 0, size)
        flake.BackgroundColor3 = Color3.new(1, 1, 1)
        flake.BorderSizePixel = 0
        flake.BackgroundTransparency = math.random(1, 3) / 10
        flake.Position = UDim2.new(math.random(), 0, -0.05, 0)
        flake.ZIndex = 20
        flake.Parent = Gui
        local drift = math.random(-5, 5) / 100
        local fallTime = math.random(4, 7)
        local target = UDim2.new(flake.Position.X.Scale + drift, 0, 1.1, 0)
        Tween:Create(flake, TweenInfo.new(fallTime, Enum.EasingStyle.Linear), {Position = target}):Play()
        task.delay(fallTime, function()
            if flake then flake:Destroy() end
        end)
    end
    coroutine.wrap(function()
        while Gui.Parent do
            CreateSnowflake()
            task.wait(0.05)
        end
    end)()
    local Image = Instance.new("ImageLabel")
    Image.BackgroundTransparency = 1
    Image.ImageTransparency = 1
    Image.BackgroundColor3 = Color3.new(1, 1, 1)
    Image.Size = UDim2.new(0.17, 0, 0.27, 0)
    Image.Position = UDim2.new(0.415, 0, 0.365, 0)
    Image.Image = "rbxassetid://113350638766570"
    Image.Parent = Gui
    Tween:Create(Blur, TweenInfo.new(1.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = 50}):Play()
    task.wait(1.5)
    Tween:Create(Image, TweenInfo.new(1, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {ImageTransparency = 0.2}):Play()
    task.wait(1)
    Flash.TintColor = Color3.fromRGB(223, 91, 91)
    Tween:Create(Flash, TweenInfo.new(0.7), {TintColor = Color3.fromRGB(255, 255, 255)}):Play()
    local originalPos = Image.Position
    coroutine.wrap(function()
        for i = 1, 6 do
            local offset = (i % 2 == 0) and -5 or 5
            Tween:Create(Image, TweenInfo.new(0.05), {Position = originalPos + UDim2.new(0, offset, 0, 0)}):Play()
            task.wait(0.05)
        end
        Tween:Create(Image, TweenInfo.new(0.1), {Position = originalPos}):Play()
    end)()
    task.wait(1)
    Tween:Create(Image, TweenInfo.new(3), {ImageTransparency = 1}):Play()
    Tween:Create(Blur, TweenInfo.new(3), {Size = 0}):Play()
    task.wait(3)
    Gui:Destroy()
    Flash:Destroy()
    Blur:Destroy()
end

local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = ColorMap[Settings.FOVColor] or Color3.fromRGB(255, 0, 0)
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 100
FOVCircle.Filled = false
FOVCircle.Visible = false

RunService.RenderStepped:Connect(function()
    FOVCircle.Visible = Settings.Enabled and Settings.ShowFOV
    if FOVCircle.Visible then
        local mousePos = UserInputService:GetMouseLocation()
        FOVCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
        FOVCircle.Radius = Settings.FOV
    end
end)

local function GetClosestPart(character)
    local closestPart, shortestDist = nil, math.huge
    local mousePos = UserInputService:GetMouseLocation()
    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") then
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                if dist < shortestDist then
                    closestPart = part
                    shortestDist = dist
                end
            end
        end
    end
    return closestPart
end

local function GetClosestTarget()
    local closestPlayer, shortestDistance = nil, Settings.FOV
    local mousePos = UserInputService:GetMouseLocation()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local part = Settings.ClosestPart and GetClosestPart(player.Character) or (Settings.AimPart == "Torso" and (player.Character:FindFirstChild("Torso") or player.Character:FindFirstChild("UpperTorso"))) or player.Character:FindFirstChild(Settings.AimPart)
            if part then
                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (mousePos - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                    if dist < shortestDistance then
                        if Settings.WallCheck then
                            local origin = Camera.CFrame.Position
                            local direction = (part.Position - origin).Unit * 500
                            local ray = Ray.new(origin, direction)
                            local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, Camera})
                            if hit and not hit:IsDescendantOf(player.Character) then
                                continue
                            end
                        end
                        closestPlayer = player
                        shortestDistance = dist
                    end
                end
            end
        end
    end
    return closestPlayer
end

local mt = getrawmetatable(game)
setreadonly(mt, false)
local oldIndex = mt.__index

mt.__index = function(self, key)
    if self == Mouse and key == "Hit" and Settings.Enabled then
        local target = GetClosestTarget()
        if target and target.Character then
            local part = Settings.ClosestPart and GetClosestPart(target.Character) or (Settings.AimPart == "Torso" and (target.Character:FindFirstChild("Torso") or target.Character:FindFirstChild("UpperTorso"))) or target.Character:FindFirstChild(Settings.AimPart)
            if part then
                return CFrame.new(part.Position + part.Velocity * Settings.Prediction)
            end
        end
    end
    return oldIndex(self, key)
end

local speedEnabled = false
local targetVelocity = Vector3.zero

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then
        if input.KeyCode == Enum.KeyCode[SpeedSettings.Keybind] then
            speedEnabled = not speedEnabled
        elseif input.KeyCode == Enum.KeyCode.Space and speedEnabled and SpeedSettings.HighJumpEnabled then
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid") then
                local humanoid = character.Humanoid
                if humanoid.FloorMaterial ~= Enum.Material.Air then
                    character.HumanoidRootPart.Velocity = Vector3.new(character.HumanoidRootPart.Velocity.X, SpeedSettings.JumpPower, character.HumanoidRootPart.Velocity.Z)
                end
            end
        end
    end
end)

local function lerpVec3(a, b, t)
    return a + (b - a) * t
end

RunService.RenderStepped:Connect(function(delta)
    if not SpeedSettings.Enabled then return end
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChild("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return end
    if speedEnabled then
        local moveDir = humanoid.MoveDirection
        if moveDir.Magnitude > 0 then
            local desiredVelocity = moveDir.Unit * SpeedSettings.Speed
            targetVelocity = lerpVec3(targetVelocity, desiredVelocity, 0.25)
            hrp.Velocity = Vector3.new(targetVelocity.X, hrp.Velocity.Y, targetVelocity.Z)
        else
            targetVelocity = Vector3.zero
        end
    else
        targetVelocity = Vector3.zero
    end
end)
