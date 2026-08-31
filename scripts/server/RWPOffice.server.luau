local RWPService = require(ScriptService.RWPService)
local RWPTemplates = require(ScriptService.RWPService.RWPTemplates)
local RWPFolder: Folder = world:WaitChild("TotallyRWPService")
local RWPID = {
	["D"] = 237539,
	["E"] = 237540,
	["F"] = 237541
}
local RWPBottomOffset = 50
local RWPTopOffset = -450

local function makeImage(id)
	local a = PTImageAsset.New(script)
	a.ImageID = id
	a.ImageType = Enums.ImageType.Asset
	return a
end

-- Build each zone's image once and reuse it, instead of constructing a
-- brand new PTImageAsset (parented to `script`, never destroyed) every
-- single time a permit is checked or issued. Previously that leaked one
-- orphaned asset per interaction, forever.
local RWPImages = {}
for zone, id in pairs(RWPID) do
	RWPImages[zone] = makeImage(id)
end

local Bell: Model = script.Parent.Bell
local Ding: Sound = Bell.Ding
local RPCRT: Model = script.Parent.RPCRT.GUI3D
local EmployeeCRT: Model = script.Parent.EmployeeCRT.GUI3D
local Voicebox: VoiceBox = script.Parent.NPC.VoiceBox

local QuestionService = require(ScriptService.QuestionService)

local busy = false
local hello = {"Hello", "Hi man"}
local help = {"How can I help?", "What do you need?", "What can I help with"}
local currentpermit = {"Current permit? Got it", "Lets see if you even have a permit", "Alright", "Sure", "Ok"}
local newpermit = {"Issue a permit? Alright", "If the computer would work then sure", "Alright", "Sure", "Ok"}
local currentpermitdone = {"Alright it's up on screen, tell me when you're done", "It's up on the screen", "Check the screen, it should be there"}
local exit = {"Alright, thanks for stopping by", "Awesome, goodbye", "Bye", "Alright"}
local whicharea = {"Which zone do you need a permit for?", "Do you know which zone you need a permit for?", "Which zone?"}
local subarea = {"Which area do you need it for?", "Which area?", "Where are you doing work?"}
local comebacklater = {"Come back when you know which area you need a permit for", "Ask around for which area you need a permit for and then come back"}

local function sayRandomOf(array: {string})
	Voicebox:Speak(array[math.random(1, #array)])
end

Bell.Hitbox.Clicked:Connect(function(player)
	Ding:PlayOneShot()
	if busy then return end
	busy = true

	local function finish()
		busy = false
	end

	sayRandomOf(hello)
	wait(0.4)
	sayRandomOf(help)

	local action = QuestionService.Ask(player, "Check current permit", "Issue new permit")
	if not action then return finish() end

	if action == "Check current permit" then
		wait(0.2)
		sayRandomOf(currentpermit)
		local rwpData = RWPService.getRWP(player.UserID)
		local RWPUI = EmployeeCRT:WaitChild("RWP")
		RWPUI.Visible = true
		local RWPNumber = RWPUI:WaitChild("Number")
		if rwpData then
			RWPNumber.Text = tostring(rwpData.Number.Value)
			local coverage = rwpData:FindChild("Coverage")
			local zone = "D"
			for _, z in ipairs({"F", "E", "D"}) do
				if coverage and coverage:FindChild(z) then zone = z; break end
			end
			RWPUI.Image = RWPImages[zone]
		else
			RWPNumber.Text = "NO PERMIT"
		end
		RWPUI.PositionOffset = Vector2.New(RWPUI.PositionOffset.X, RWPBottomOffset)
		sayRandomOf(currentpermitdone)
		while true do
			local choice = QuestionService.Ask(player, "Scroll up", "Scroll down", "All done")
			if not choice or choice == "All done" then break end
			if choice == "Scroll down" then
				RWPUI.PositionOffset = Vector2.New(RWPUI.PositionOffset.X, RWPTopOffset)
			elseif choice == "Scroll up" then
				RWPUI.PositionOffset = Vector2.New(RWPUI.PositionOffset.X, RWPBottomOffset)
			end
		end
		RWPUI.Visible = false
		wait(0.2)
		sayRandomOf(exit)
		return finish()
	else
		wait(0.2)
		sayRandomOf(newpermit)
		sayRandomOf(whicharea)
		local area = QuestionService.Ask(player, "E", "F", "I don't know")
		if not area then return finish() end
		local zone
		if area == "E" then
			zone = "E"
		elseif area == "F" then
			zone = "F"
		else
			sayRandomOf(subarea)
			local sub = QuestionService.Ask(player, "Turbine hall", "Reactor hall", "I give up")
			if not sub then return finish() end
			if sub == "Turbine hall" then
				zone = "E"
			elseif sub == "Reactor hall" then
				zone = "F"
			else
				wait(0.2)
				sayRandomOf(comebacklater)
				return finish()
			end
		end
		RWPService.issueRWP(player.UserID, zone)
		local rwpData = RWPService.getRWP(player.UserID)
		local RWPUI = EmployeeCRT:WaitChild("RWP")
		RWPUI.Visible = true
		local RWPNumber = RWPUI:WaitChild("Number")
		if rwpData then
			RWPNumber.Text = tostring(rwpData.Number.Value)
			local coverage = rwpData:FindChild("Coverage")
			local topZone = "D"
			for _, z in ipairs({"F", "E", "D"}) do
				if coverage and coverage:FindChild(z) then topZone = z; break end
			end
			RWPUI.Image = RWPImages[topZone]
		else
			RWPNumber.Text = "NO PERMIT"
		end
		RWPUI.PositionOffset = Vector2.New(RWPUI.PositionOffset.X, RWPBottomOffset)
		local doseLimit = rwpData and rwpData.DoseLimit and rwpData.DoseLimit.Value or 0
		local doseRateLimit = rwpData and rwpData.DoseRateLimit and rwpData.DoseRateLimit.Value or 0
		sayRandomOf({string.format("Alright, your dose limit is %d µSv and your dose rate limit is %d µSv/h, review your permit and tell me when you're done.", doseLimit, doseRateLimit)})
		while true do
			local choice = QuestionService.Ask(player, "Scroll up", "Scroll down", "All done")
			if not choice or choice == "All done" then break end
			if choice == "Scroll down" then
				RWPUI.PositionOffset = Vector2.New(RWPUI.PositionOffset.X, RWPTopOffset)
			elseif choice == "Scroll up" then
				RWPUI.PositionOffset = Vector2.New(RWPUI.PositionOffset.X, RWPBottomOffset)
			end
		end
		RWPUI.Visible = false
		wait(0.2)
		sayRandomOf(exit)
		return finish()
	end
end)