local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ⚙️ CONFIG
local AimEnabled = true

local Mode = "LEGEND" 
-- "COMPETITIVE" = cambia rápido al más cercano
-- "TOURNAMENT" = más estable (no cambia tanto)
-- "LEGEND" = sin HUD + limpio + preciso

local MaxDistance = 200 -- 🔥 límite en studs (~metros en Roblox)
local FOV = 140
local Prediction = 0.12

local CurrentTarget = nil
local SwitchDelay = 0.15
local LastSwitch = 0

-- 🔍 VALIDAR SI ES ATACABLE (ANTI SAFE ZONE)
local function IsTargetValid(player)
    if player == LocalPlayer then return false end
    if not player.Character then return false end

    local humanoid = player.Character:FindFirstChild("Humanoid")
    local root = player.Character:FindFirstChild("HumanoidRootPart")

    if not humanoid or humanoid.Health <= 0 then return false end
    if not root then return false end

    -- distancia límite
    local distance = (Camera.CFrame.Position - root.Position).Magnitude
    if distance > MaxDistance then return false end

    -- 🔥 intentar detectar zonas seguras (básico)
    if player.Team == LocalPlayer.Team then
        return false
    end

    return true
end

-- 🎯 OBTENER MÁS CERCANO A LA MIRA
local function GetClosestPlayer()
    local closest = nil
    local shortest = FOV

    for _, player in pairs(Players:GetPlayers()) do
        if IsTargetValid(player) then
            
            local root = player.Character:FindFirstChild("HumanoidRootPart")
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

    return closest
end

-- 🎯 SISTEMA DE TARGET INTELIGENTE
local function UpdateTarget()
    local now = tick()

    if Mode == "COMPETITIVE" then
        -- cambia rápido siempre
        CurrentTarget = GetClosestPlayer()

    elseif Mode == "TOURNAMENT" then
        -- mantiene target más tiempo
        if (now - LastSwitch) > SwitchDelay then
            local newTarget = GetClosestPlayer()
            if newTarget then
                CurrentTarget = newTarget
                LastSwitch = now
            end
        end

    elseif Mode == "LEGEND" then
        -- 🔥 balance perfecto
        local newTarget = GetClosestPlayer()

        if newTarget ~= CurrentTarget then
            if (now - LastSwitch) > SwitchDelay then
                CurrentTarget = newTarget
                LastSwitch = now
            end
        end
    end
end

-- 😈 AIM LOCK REAL (SIN BUG DE CÁMARA)
RunService.RenderStepped:Connect(function()
    if not AimEnabled then return end

    UpdateTarget()

    if CurrentTarget and CurrentTarget.Character then
        local root = CurrentTarget.Character:FindFirstChild("HumanoidRootPart")

        if root then
            local velocity = root.Velocity
            local predicted = root.Position + (velocity * Prediction)

            -- 🔥 bloqueo directo (NO LERP)
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, predicted)
        end
    end
end)
