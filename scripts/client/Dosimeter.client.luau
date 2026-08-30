local doseLimit = 1000

local Dosimeter: Model = script.Parent
local alarm: Sound = Dosimeter.Alarm
local Screen: GUI3D = Dosimeter.Model.Screen
local unit: UILabel = Screen.unit
local value: UILabel = Screen.value
local mode: UILabel = Screen.mode
local alarmmode: UILabel = Screen.alarm
local muted: UIImage = Screen.muted
local unmuted: UIImage = Screen.unmuted

local Tooltip = PlayerGUI:WaitChild("Tooltip").CurrentTool

local doseRateMode: boolean = false
local hasPlayer: boolean = false
local mute: boolean = false

local updateConnection: PTSignalConnection

local function fitScreen(v: number): string
  if v < 0 then v = 0 end
  if v >= 100000 then return "Ol." end
	
  local s
  if v >= 10000 then s = string.format("%d",   v)
  elseif v >= 1000 then s = string.format("%.1f", v)
  elseif v >= 100 then s = string.format("%.2f", v)
  elseif v >= 10 then s = string.format("%.3f", v)
  else s = string.format("%.4f", v) end
  if #s > 6 then return "Ol." end
	
  return s
end

Dosimeter.Equipped:Connect(function()
	hasPlayer = true
	Tooltip.Text = "LMB: Change Mode\nQ: Toggle Mute"
	local dose = Players.LocalPlayer:WaitChild("Dose")
	local doseRate = Players.LocalPlayer:WaitChild("DoseRate")
	updateConnection = dose.Changed:Connect(function()
		value.Text = fitScreen(doseRateMode and (doseRate.Value * 3600) or dose.Value)
	end)
end)

Dosimeter.Unequipped:Connect(function()
	Tooltip.Text = ""
	if updateConnection then
		updateConnection:Disconnect()
	end
end)

Dosimeter.Activated:Connect(function()
	local dose = Players.LocalPlayer:WaitChild("Dose")
	local doseRate = Players.LocalPlayer:WaitChild("DoseRate")
	doseRateMode = not doseRateMode
	mode.Text = doseRateMode and "RATE" or "DOSE"
	value.Text = fitScreen(doseRateMode and (doseRate.Value * 3600) or dose.Value)
	unit.Text  = doseRateMode and "µSv/h" or "µSv"
end)

Input.KeyDown:Connect(function(key: KeyCodeEnum)
	if key == Enums.KeyCode.Q then
		mute = not mute
		muted.Visible = mute
		unmuted.Visible = not mute
	end
end)

function _Update()
	alarm.Position = Players.LocalPlayer.Position
end

while true do
	if hasPlayer then
		local dose = Players.LocalPlayer:WaitChild("Dose")
		local doseRate = Players.LocalPlayer:WaitChild("DoseRate")
		local doseAlarm = false
		local doseRateAlarm = false
		if dose.Value >= doseLimit then
			doseAlarm = true
		else
			doseAlarm = false
		end
		--todo: add detection for doseRateAlarm
		
		mode.Visible = not mode.Visible
		local showAlarm = (doseRateMode and doseRateAlarm) or (not doseRateMode and doseAlarm)
		alarmmode.Visible = showAlarm and not mode.Visible
		
		if dose.Value and dose.Value ~= nil then
			if doseAlarm and not mute then
				alarm:Play()
			end
		end
	end
	wait(0.5)
end