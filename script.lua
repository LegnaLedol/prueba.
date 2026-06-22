local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ⚙️ CONFIG
local AimEnabled = true

local Mode = "LEGEND"

local MaxDistance = 800
local FOV = 160
local Prediction = 0.10

local AimPart = "Head"
local Smoothness = 0.18

local CurrentTarget = nil
local SwitchDelay = 0.12
local LastSwitch = 0

-- 👻 GUI BASE
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)

-- 👻 BOTÓN INVISIBLE ARRIBA
local Button = Instance.new("TextButton", ScreenGui)
Button.Size = UDim2.new(0,25,0,25)
Button.Position = UDim2.new(1,-25,0,0)
Button.BackgroundTransparency = 1
Button.Text = ""

-- 🔔 INDICADOR
local Indicator = Instance.new("TextLabel", ScreenGui)
Indicator.Size = UDim2.new(0,40,0,40)
Indicator.Position = UDim2.new(1,-50,0,30)
Indicator.BackgroundTransparency = 1
Indicator.TextScaled = true
Indicator.Text = ""
Indicator.Visible = false
Indicator.Font = Enum.Font.GothamBold

local function ShowIndicator(state)
    Indicator.Visible = true
    
    if state then
        Indicator.Text = "✔️"
        Indicator.TextColor3 = Color3.fromRGB(0,255,0)
    else
        Indicator.Text = "✖️"
        Indicator.TextColor3 = Color3.fromRGB(255,0,0)
    end

    task.delay(2, function()
        Indicator.Visible = false
    end)
end

Button.MouseButton1Click:Connect(function()
    AimEnabled = not AimEnabled
    ShowIndicator(AimEnabled)
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

-- 😈 AIM SYSTEM
RunService.RenderStepped:Connect(function()
    if not AimEnabled then return end

    UpdateTarget()

    if CurrentTarget and CurrentTarget.Character then
        local part = CurrentTarget.Character:FindFirstChild(AimPart)

        if part then
            local velocity = part.Velocity
            local predicted = part.Position + (velocity * Prediction)

            local aimCF = CFrame.new(Camera.CFrame.Position, predicted)

            Camera.CFrame = Camera.CFrame:Lerp(aimCF, Smoothness)
        end
    end
end) 
