local RWPService: Folder = world:FindChild("TotallyRWPService")

local dosimeterInfoUI: UIView = script.Parent:WaitChild("DosimeterInfoUI"):WaitChild("Info")
local UIdose: UILabel = dosimeterInfoUI:WaitChild("dose")
local UIdoseAlarm: UILabel = dosimeterInfoUI:WaitChild("dosealarm")
local UIdoseRateAlarm: UILabel = dosimeterInfoUI:WaitChild("doseratealarm")
local UIrwpNumber: UILabel = dosimeterInfoUI:WaitChild("rwpnumber")
local UIrwpCoverage: UILabel = dosimeterInfoUI:WaitChild("rpcoverage")

local gatePositionUI: GUI3D = script.Parent:WaitChild("GatePositionUI")
local UIopen: UILabel = gatePositionUI:WaitChild("OPEN")
local UIclose: UILabel = gatePositionUI:WaitChild("CLOSE")

local statusUI: UIView = script.Parent:WaitChild("DosimeterInfoUI"):WaitChild("Status")
local UItime: UILabel = statusUI:WaitChild("time")
local UIbattery: UILabel = statusUI:WaitChild("battery")

local bottomUI: UIView = script.Parent:WaitChild("DosimeterInfoUI"):WaitChild("BottomStatus")
local UIstatus = bottomUI:WaitChild("Status")

local prompt: InteractionPrompt = script.Parent:WaitChild("Scan")

local LeftDoor: Model = script.Parent:WaitChild("LeftDoor")
local RightDoor: Model = script.Parent:WaitChild("RightDoor")
local LeftDoorClosedRot: Vector3 = LeftDoor.Rotation
local RightDoorClosedRot: Vector3 = RightDoor.Rotation
local busy = false

prompt.Interacted:Connect(function(player)
	if busy then return end

	local hasDosimeter = false
	if player.Inventory then
		for _, item in ipairs(player.Inventory:GetChildren()) do
			if string.find(item.Name, "Dosimeter") then
				hasDosimeter = true
				break
			end
		end
	end
	if not hasDosimeter and player.Character and player.Character:FindChild("Dosimeter") then
		hasDosimeter = true
	end
	if not hasDosimeter then return end

	busy = true

	local ok, err = pcall(function()
		UIstatus.Text = "Fetching RWP Information"
		local dosimeterDose: number = 0
		local rwpDoseAlarm: number = 1000
		local rwpDoseRateAlarm: number = 10
		local rwpNumber: number = 0
		local rwpCoverage: {string} = {"A", "B", "C"}
		local rwpCoverageString: string = "A, B, C"
		
		local RWP: Folder = RWPService and RWPService:FindChild(tostring(player.UserID))
		local dose = player:FindChild("Dose")
		
		if dose then
			dosimeterDose = dose.Value
		end
		if RWP then
			rwpDoseAlarm = RWP.DoseAlarm.Value
			rwpDoseRateAlarm = RWP.DoseRateAlarm.Value
			rwpNumber = RWP.Number.Value
			rwpCoverage = {}
			rwpCoverageString = ""
			for _, Area in ipairs(RWP.Coverage:GetChildren()) do
				table.insert(rwpCoverage, Area.Value)
			end
			rwpCoverageString = table.concat(rwpCoverage, ", ")
		end
		
		UIstatus.Text = "Waiting Gate Close"
		
		if not RWP then
			UIstatus.Text = "RWP Server Error (400)"
		end
		
		UIdose.Text = string.format("%.1f µSv", dosimeterDose)
		UIdoseAlarm.Text = string.format("%.1f µSv", rwpDoseAlarm)
		UIdoseRateAlarm.Text = string.format("%.1f µSv/h", rwpDoseRateAlarm)
		UIrwpNumber.Text = string.format("%d", rwpNumber)
		UIrwpCoverage.Text = rwpCoverageString
		UIopen.TextColor = Color.FromHex("00FF00")
		UIclose.TextColor = Color.FromHex("000000")
		
		local leftDoorTween = Tween:NewTween()
		local rightDoorTween = Tween:NewTween()
		local leftDoorRotation = LeftDoorClosedRot.Z - 30
		local RightDoorRotation = RightDoorClosedRot.Z + 30
		leftDoorTween:TweenRotation(LeftDoor, Vector3.New(LeftDoorClosedRot.X, LeftDoorClosedRot.Y, leftDoorRotation), 0.5)
		rightDoorTween:TweenRotation(RightDoor, Vector3.New(RightDoorClosedRot.X, RightDoorClosedRot.Y, RightDoorRotation), 0.5)
		wait(3)
		leftDoorTween = Tween:NewTween()
		rightDoorTween = Tween:NewTween()
		leftDoorTween:TweenRotation(LeftDoor, Vector3.New(LeftDoorClosedRot.X, LeftDoorClosedRot.Y, LeftDoorClosedRot.Z), 0.5)
		rightDoorTween:TweenRotation(RightDoor, Vector3.New(RightDoorClosedRot.X, RightDoorClosedRot.Y, RightDoorClosedRot.Z), 0.5)
		
		UIdose.Text = "-"
		UIdoseAlarm.Text = "-"
		UIdoseRateAlarm.Text = "-"
		UIrwpNumber.Text = "-"
		UIrwpCoverage.Text = "-"
		UIopen.TextColor = Color.FromHex("000000")
		UIclose.TextColor = Color.FromHex("FF0000")
		UIstatus.Text = "Awaiting Scan"
	end)

	busy = false
end)