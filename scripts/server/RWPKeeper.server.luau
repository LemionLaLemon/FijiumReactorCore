local RWPService = require(ScriptService.RWPService)
require(ScriptService.QuestionService)
local RWPFolder = world:WaitChild("TotallyRWPService")

local active: {[number]: boolean} = {}

Players.PlayerAdded:Connect(function(player)
	active[player.UserID] = true
	if RWPService.getRWP(player.UserID) then return end
	--todo: implement dunce detection and apply Zone A RWP
	RWPService.issueRWP(player.UserID, "D")
end)

Players.PlayerRemoved:Connect(function(player)
	active[player.UserID] = nil
	local folder = RWPFolder:FindChild(tostring(player.UserID))
	if folder then folder:Destroy() end
end)

for _, player in ipairs(Players:GetPlayers()) do
	active[player.UserID] = true
	if not RWPService.getRWP(player.UserID) then
		RWPService.issueRWP(player.UserID, "D")
	end
end

while true do
	local currentTime = os.time()
	--todo: implement dunce detection and reversion to Zone A RWP
	for _, RWP in ipairs(RWPFolder:GetChildren()) do
		local playerID = tonumber(RWP.Name)
		if playerID and not active[playerID] then
			RWP:Destroy()
		elseif RWP.EndDate.Value < currentTime then
			RWPService.issueRWP(playerID, "D")
		end
	end
	wait(5)
end