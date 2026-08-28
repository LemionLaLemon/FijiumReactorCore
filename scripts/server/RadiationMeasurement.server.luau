local function attachDose(player: Player)
	local DoseInstance = Instance.New("NumberValue", player)
	DoseInstance.Name = "Dose"
	DoseInstance.Value = 0
	local DoseRateInstance = Instance.New("NumberValue", player)
	DoseRateInstance.Name = "DoseRate"
	DoseRateInstance.Value = 0
	local AccumulatedDoseInstance = Instance.New("NumberValue", player)
	AccumulatedDoseInstance.Name = "AccumulatedDose"
	AccumulatedDoseInstance.Value = 0
end

Players.PlayerAdded:Connect(attachDose)

for _, player in ipairs(Players:GetPlayers()) do
	attachDose(player)
end

local dt = 3
local sources

local function sampleRate(position: Vector3)
	local doseTotal = 0
	
	for _, source in ipairs(sources) do
		local radioactivity = source:FindChild("Radioactivity")
		if radioactivity then
			local distance = (source.Position - position).Magnitude
			doseTotal += radioactivity.Value / math.max(distance * distance, 1)
		end
	end
	
	return doseTotal
end

Players.PlayerAdded:Connect(function(player)
    player.Respawned:Connect(function()
        player:FindChild("DoseRate").Value = 0
				player:FindChild("Dose").Value = 0
    end)
end)

while true do
	sources = world:GetDescendantsWithTag("Radioactive")
	for _, player in ipairs(Players:GetPlayers()) do
		local doseRate = player:FindChild("DoseRate")
		local dose = player:FindChild("Dose")
		local accumulatedDose = player:FindChild("AccumulatedDose")
		
		if doseRate and dose then
			local rate = sampleRate(player.Position)
			doseRate.Value = rate
			dose.Value = dose.Value + rate * dt
			accumulatedDose.Value = accumulatedDose.Value + rate * dt
		end
	end
	wait(dt)
end