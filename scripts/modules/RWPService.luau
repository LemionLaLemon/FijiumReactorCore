local RWPTemplates = require(script.RWPTemplates)
local RWPService: Folder = world:WaitChild("TotallyRWPService")

local function getRWP(playerID: number)
	return RWPService:FindChild(tostring(playerID))
end

local function issueRWP(playerID: number, zone: string)
	if not RWPTemplates[zone] then return "Invalid Zone" end
	local RWP: Folder = getRWP(playerID)
	if not RWP then
		RWP = Instance.New("Folder", RWPService)
		RWP.Name = tostring(playerID)
		
		Instance.New("NumberValue", RWP).Name = "Number"
		Instance.New("NumberValue", RWP).Name = "DoseAlarm"
		Instance.New("NumberValue", RWP).Name = "DoseRateAlarm"
		Instance.New("NumberValue", RWP).Name = "EndDate"
		Instance.New("NumberValue", RWP).Name = "StartDate"
		Instance.New("Folder", RWP).Name = "Coverage"
	end
	
	local RWPNumber: number = math.random(0, 9999999)
	RWP.Number.Value = RWPNumber
	RWP.DoseAlarm.Value = RWPTemplates[zone].DoseAlarm
	RWP.DoseRateAlarm.Value = RWPTemplates[zone].DoseRateAlarm
	if not RWP:FindChild("DoseLimit") then Instance.New("NumberValue", RWP).Name = "DoseLimit" end
	if not RWP:FindChild("DoseRateLimit") then Instance.New("NumberValue", RWP).Name = "DoseRateLimit" end
	RWP.DoseLimit.Value = RWPTemplates[zone].DoseLimit
	RWP.DoseRateLimit.Value = RWPTemplates[zone].DoseRateLimit
	for _, item in ipairs(RWP.Coverage:GetChildren()) do
		item:Destroy()
	end
	for _, zone in ipairs(RWPTemplates[zone].Coverage) do
		local zoneValue = Instance.New("StringValue", RWP.Coverage)
		zoneValue.Name = zone
		zoneValue.Value = zone
	end
	local currentTime: number = os.time()
	RWP.StartDate.Value = currentTime
	RWP.EndDate.Value = currentTime + 24 * 60 * 60
end

return { getRWP = getRWP, issueRWP = issueRWP }