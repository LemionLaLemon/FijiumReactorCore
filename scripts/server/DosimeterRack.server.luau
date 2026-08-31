local prompt: InteractionPrompt = script.Parent
local template: Tool = Hidden:WaitChild("Dosimeter")

local function hasDosimeter(player: Player)
	if player.Inventory then
		for _, item in ipairs(player.Inventory:GetChildren()) do
			if item.Name == "Dosimeter" then 
				return true
			end
		end
	end
	if player.Character and player.Character:FindChild("Dosimeter") then
		return true
	end
	return false
end

prompt.Interacted:Connect(function(player: Player)
	if hasDosimeter(player) then return end
	local dosimeter = template:Clone()
	dosimeter.Parent = player.Inventory
	prompt:HideFor(player)
end)

local function hookRespawn(player: Player)
	player.Respawned:Connect(function()
		prompt:ShowFor(player)
	end)
end

Players.PlayerAdded:Connect(hookRespawn)
for _, player in ipairs(Players:GetPlayers()) do
	hookRespawn(player)
end