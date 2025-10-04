n", {
                    Title = "Friend System",
                    Text = "Player with name similar to '" .. targetName .. "' not found!",
                    Duration = 3
                })
            end
        elseif args[2] == "remove" and args[3] then
            local targetName = args[3]
            local targetPlayer = findPlayerByPartialName(targetName)
            if targetPlayer then
                local friendIndex = table.find(friendsList, targetPlayer.Name)
                if friendIndex then
                    table.remove(friendsList, friendIndex)
                    Players.LocalPlayer:WaitForChild("StarterGui"):SetCore("SendNotification", {
                        Title = "Friend System",
                        Text = targetPlayer.Name .. " removed from friends!",
                        Duration = 3
                    })
                else
                    Players.LocalPlayer:WaitForChild("StarterGui"):SetCore("SendNotification", {
                        Title = "Friend System",
                        Text = targetPlayer.Name .. " is not in your friends list!",
                        Duration = 3
                    })
                end
            else
                Players.LocalPlayer:WaitForChild("StarterGui"):SetCore("SendNotification", {
                    Title = "Friend System",
                    Text = "Player with name similar to '" .. targetName .. "' not found!",
                    Duration = 3
                })
            end
        end
    end
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        playerSpawnTimes[player] = tick()
        if espEnabled and player ~= Players.LocalPlayer then
            local espHighlight = Instance.new("Highlight")
            espHighlight.FillColor = isFriend(player) and Color3.fromRGB(0, 255, 255) or Color3.fromRGB(255, 0, 0)
            espHighlight.OutlineColor = Color3.fromRGB(0, 0, 0)
            espHighlight.Parent = character
            espHighlights[player] = espHighlight
        end
    end)
    player.AncestryChanged:Connect(function()
        if espHighlights[player] then
            espHighlights[player]:Destroy()
            espHighlights[player] = nil
        end
        playerSpawnTimes[player] = nil
    end)
end)

local function updateESP()
    for player, highlight in pairs(espHighlights) do
        if highlight and highlight.Parent then
            highlight.FillColor = isFriend(player) and Color3.fromRGB(0, 255, 255) or Color3.fromRGB(255, 0, 0)
        end
    end
end

local function canHitTarget(player, target)
    local character = player.Character
    if not character then return false end
    
    local tool = character:FindFirstChildOfClass("Tool")
    local handle = tool and tool:FindFirstChild("Handle")
    if not handle then return false end

    local targetRoot = target.Parent:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return false end

    local distance = (handle.Position - targetRoot.Position).Magnitude
    local swordReach = 6.5

    local rayOrigin = handle.Position
    local rayDirection = (targetRoot.Position - rayOrigin).Unit * distance
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    local raycastResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    if raycastResult and not raycastResult.Instance:IsDescendantOf(target.Parent) then
        return false
    end

    return distance <= swordReach
end

local function getClosestTargetForAimbot()
    local player = Players.LocalPlayer
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    local rootPart = character.HumanoidRootPart
    local closestTarget = nil
    local minDistance = aimbotRange

    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player and not isFriend(otherPlayer) and otherPlayer.Character then
            local targetRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
            local targetHumanoid = otherPlayer.Character:FindFirstChild("Humanoid")
            if targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
                local distance = (rootPart.Position - targetRoot.Position).Magnitude
                local spawnTime = playerSpawnTimes[otherPlayer] or 0
                local timeSinceSpawn = tick() - spawnTime
                if distance <= minDistance and timeSinceSpawn > spawnProtectionTime then
                    local rayOrigin = rootPart.Position
                    local rayDirection = (targetRoot.Position - rayOrigin).Unit * distance
                    local raycastParams = RaycastParams.new()
                    raycastParams.FilterDescendantsInstances = {character}
                    raycastParams.FilterType = Enum.Ra