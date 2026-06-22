local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ⚙️ CONFIG
local AimEnabled = true
local Smoothness = 0.08
local FOV = 180
local Prediction = 0.10
local MaxDistance = 200

local aiming = false

-- 🎮 ACTIVAR AIM SOLO AL APUNTAR
UIS.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aiming = true
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aiming = false
    end
end)

-- 🎯 UI (igual que el tuyo)
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 220, 0, 50)
Frame.Position = UDim2.new(0.5, -110, 0.1, 0)
Frame.BackgroundColor3 = Color3.fromRGB(0,0,0)
Frame.BorderSizePixel = 0

local Text = Instance.new("TextLabel", Frame)
Text.Size = UDim2.new(1,0,1,0)
Text.BackgroundTransparency = 1
Text.Text = "LEGNA FPS+ ACTIVADO"
Text.TextColor3 = Color3.fromRGB(255,255,255)
Text.TextScaled = true
Text.Font = Enum.Font.GothamBold

spawn(function()
    while Frame.Parent do
        for i = 0,255,5 do
            Frame.BackgroundColor3 = Color3.fromHSV(i/255,1,1)
            task.wait()
        end
    end
end)

task.delay(5, function()
    local tween = TweenService:Create(Frame, TweenInfo.new(1), {BackgroundTransparency = 1})
    tween:Play()
    task.wait(1)
    ScreenGui:Destroy()
end)

-- 🧠 TARGET MEJORADO
local function GetClosestPlayer()
    local closest = nil
    local shortest = FOV

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = player.Character:FindFirstChild("Humanoid")

            if root and humanoid and humanoid.Health > 0 then
                
                -- 📏 DISTANCIA REAL
                local distance = (root.Position - Camera.CFrame.Position).Magnitude
                if distance > MaxDistance then continue end

                local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)

                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - Camera.ViewportSize/2).Magnitude

                    if dist < shortest then
                        shortest = dist
                        closest = player
                    end
                end
            end
        end
    end

    return closest
end

-- 😈 AIM SKILL MEJORADO
RunService.RenderStepped:Connect(function()
    if not AimEnabled or not aiming then return end

    local target = GetClosestPlayer()

    if target and target.Character then
        local root = target.Character:FindFirstChild("HumanoidRootPart")

        if root then
            local velocity = root.Velocity
            
            -- 🎯 predicción mejorada
            local predicted = root.Position + (velocity * Prediction)

            -- 🧠 error humano más suave
            local randomOffset = Vector3.new(
                math.random(-1,1)/20,
                math.random(-1,1)/20,
                math.random(-1,1)/20
            )

            predicted += randomOffset

            local aimCF = CFrame.new(Camera.CFrame.Position, predicted)

            -- 🎥 smooth tipo skill (no roba cámara)
            Camera.CFrame = Camera.CFrame:Lerp(aimCF, Smoothness)
        end
    end
end)
