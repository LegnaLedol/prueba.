local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ⚙️ CONFIG
local AimEnabled = true

local Mode = "LEGEND" -- "COMPETITIVE", "TOURNAMENT", "LEGEND"

local MaxDistance = 800
local FOV = 160
local Prediction = 0.10 -- 📱 estable en móvil

local AimPart = "Head" -- "Head" o "HumanoidRootPart"

local Smoothness = 0.18 -- 📱 menos temblor

local CurrentTarget = nil
local SwitchDelay = 0.12
local LastSwitch = 0

-- 📱 BOTÓN INVISIBLE
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)

local Button = Instance.new("TextButton", ScreenGui)
Button.Size = UDim2.new(0,25,0,25)
Button.Position = UDim2.new(1,-30,1,-30)
Button.BackgroundTransparency = 0.85 -- casi invisible
Button.BackgroundColor3 = Color3.fromRGB(255,255,255)
Button.Text = ""

Button.MouseButton1Click:Connect(function()
    AimEnabled = not AimEnabled
end)

-- 🔍 VALIDAR TARGET
local function IsTargetValid(player)
    if player == LocalPlayer then return false end
    if not player.Character then return false end

    local humanoid = player.Character:FindFirstChild("Humanoid")
    local root = player.Character:FindFirstChild("HumanoidRootPart")

    if not humanoid or humanoid.Health <= 0 then return false end
    if not root then return false end

    local distance = (Camera.CFrame.Position - root.Position).Magnitude
    if distance > MaxDistance then return false end

    -- evitar team (safe zone básico)
    if player.Team == LocalPlayer.Team then
        return false
    end

    return true
end

-- 🎯 OBTENER TARGET
local function GetClosestPlayer()
    local closest = nil
    local shortest = FOV

    for _, player in pairs(Players:GetPlayers()) do
        if IsTargetValid(player) then
            
            local part = player.Character:FindFirstChild(AimPart)
            if not part then continue end

            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)

            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - Camera.ViewportSize/2).Magnitude

                if dist < shortest then
                    shortest = dist
                    closest = player
                end
            end
        end
    end

    return closest
end

-- 🎯 CAMBIO INTELIGENTE
local function UpdateTarget()
    local now = tick()

    if Mode == "COMPETITIVE" then
        CurrentTarget = GetClosestPlayer()

    elseif Mode == "TOURNAMENT" then
        if (now - LastSwitch) > SwitchDelay then
            local newTarget = GetClosestPlayer()
            if newTarget then
                CurrentTarget = newTarget
                LastSwitch = now
            end
        end

    elseif Mode == "LEGEND" then
        local newTarget = GetClosestPlayer()

        if newTarget ~= CurrentTarget then
            if (now - LastSwitch) > SwitchDelay then
                CurrentTarget = newTarget
                LastSwitch = now
            end
        end
    end
end

-- 😈 AIM SYSTEM (OPTIMIZADO MÓVIL)
RunService.RenderStepped:Connect(function()
    if not AimEnabled then return end

    UpdateTarget()

    if CurrentTarget and CurrentTarget.Character then
        local part = CurrentTarget.Character:FindFirstChild(AimPart)

        if part then
            local velocity = part.Velocity
            local predicted = part.Position + (velocity * Prediction)

            local aimCF = CFrame.new(Camera.CFrame.Position, predicted)

            -- 🔥 suave pero firme (no vibra)
            Camera.CFrame = Camera.CFrame:Lerp(aimCF, Smoothness)
        end
    end
end)
