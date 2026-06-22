local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

-- ⚙️ CONFIG
local AimEnabled = true
local TeamCheck = false
local VisibilityCheck = false
local Smoothness = 0.12
local FOV = 180
local Prediction = 0.12

-- 🧠 FUNCIÓN: jugador más cercano al centro
local function GetClosestPlayer()
    local closest = nil
    local shortest = FOV

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            
            if TeamCheck and player.Team == LocalPlayer.Team then
                continue
            end

            local root = player.Character.HumanoidRootPart
            local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)

            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                
                if dist < shortest then
                    if VisibilityCheck then
                        local ray = Ray.new(Camera.CFrame.Position, (root.Position - Camera.CFrame.Position).Unit * 500)
                        local part = workspace:FindPartOnRay(ray, LocalPlayer.Character)

                        if part and not part:IsDescendantOf(player.Character) then
                            continue
                        end
                    end

                    shortest = dist
                    closest = player
                end
            end
        end
    end

    return closest
end

-- 🔥 LOOP PRINCIPAL
RunService.RenderStepped:Connect(function()
    if not AimEnabled then return end

    local target = GetClosestPlayer()

    if target and target.Character then
        local root = target.Character:FindFirstChild("HumanoidRootPart")

        if root then
            local predicted = root.Position + (root.Velocity * Prediction)

            local aimCF = CFrame.new(Camera.CFrame.Position, predicted)
            Camera.CFrame = Camera.CFrame:Lerp(aimCF, Smoothness)
        end
    end
end)
