local prompt: InteractionPrompt = script.Parent
local template: Tool = Hidden:WaitChild("Dosimeter")

local function hasDosimeter(player: Player)
	for _, item in ipairs(player.Inventory:GetChildren()) do
		if item.Name == "Dosimeter" then 
			return true
		end
		if player.Character and player.Character:FindChild("Dosimeter") then
			return true
		end
		return false
	end
end

prompt.Interacted:Connect(function(player: Player)
	if hasDosimeter(player) then return end
	local dosimeter = template:Clone()
	dosimeter.Parent = player.Inventory
	prompt:HideFor(player)
end)

Players.PlayerAdded:Connect(function(player)
    player.Respawned:Connect(function()
        prompt:ShowFor(player)
    end)
end)