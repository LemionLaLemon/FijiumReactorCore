local function attachDose(player: Player)
	if not player:FindChild("Dose") then
		local DoseInstance = Instance.New("NumberValue", player)
		DoseInstance.Name = "Dose"
		DoseInstance.Value = 0
	end
	if not player:FindChild("DoseRate") then
		local DoseRateInstance = Instance.New("NumberValue", player)
		DoseRateInstance.Name = "DoseRate"
		DoseRateInstance.Value = 0
	end
	if not player:FindChild("AccumulatedDose") then
		local AccumulatedDoseInstance = Instance.New("NumberValue", player)
		AccumulatedDoseInstance.Name = "AccumulatedDose"
		AccumulatedDoseInstance.Value = 0
	end
end

local function hookPlayer(player: Player)
	attachDose(player)
	player.Respawned:Connect(function()
		local d = player:FindChild("Dose")
		local dr = player:FindChild("DoseRate")
		if d then d.Value = 0 end
		if dr then dr.Value = 0 end
	end)
end

Players.PlayerAdded:Connect(hookPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	hookPlayer(player)
end

local dt = 3
local sources = world:GetDescendantsWithTag("Radioactive")
local lastSourceScan = 0

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

while true do
	if os.clock() - lastSourceScan > 30 then
		sources = world:GetDescendantsWithTag("Radioactive")
		lastSourceScan = os.clock()
	end

	for _, player in ipairs(Players:GetPlayers()) do
		local doseRate = player:FindChild("DoseRate")
		local dose = player:FindChild("Dose")
		local accumulatedDose = player:FindChild("AccumulatedDose")
		
		if doseRate and dose and accumulatedDose then
			local rate = sampleRate(player.Position)
			doseRate.Value = rate
			dose.Value = dose.Value + rate * dt
			accumulatedDose.Value = accumulatedDose.Value + rate * dt
		end
	end
	wait(dt)
end