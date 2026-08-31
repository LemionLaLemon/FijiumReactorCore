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

-- Replaces the old `while true ... wait(0.5) end` loop. Instead of a
-- separate sleeping thread, we accumulate real dt from _Update() and
-- only run the dose/alarm/blink check once we've crossed this interval.
local TICK_INTERVAL = 0.5
local tickTimer = 0

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
	hasPlayer = false
	Tooltip.Text = ""
	if updateConnection then
		updateConnection:Disconnect()
		updateConnection = nil
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

-- The periodic half-second-ish dosimeter tick: dose/alarm check + blink.
-- Pulled out of _Update() itself just to keep that function readable.
local function tick()
	local player = Players.LocalPlayer
	if not player then return end

	-- FindChild, not WaitChild: WaitChild yields indefinitely if the
	-- value isn't there yet, which would stall the whole per-frame hook.
	-- FindChild just skips this tick instead and tries again next time.
	local dose = player:FindChild("Dose")
	local doseRate = player:FindChild("DoseRate")
	if not (dose and doseRate) then return end

	local doseAlarm = dose.Value >= doseLimit
	--todo: add detection for doseRateAlarm
	local doseRateAlarm = false

	mode.Visible = not mode.Visible
	local showAlarm = (doseRateMode and doseRateAlarm) or (not doseRateMode and doseAlarm)
	alarmmode.Visible = showAlarm and not mode.Visible

	if doseAlarm and not mute then
		alarm:Play()
	end
end

local dt = 1/60
while true do
	if hasPlayer then
		local player = Players.LocalPlayer
		if player and player.Character then
			alarm.Position = player.Position

			tickTimer += dt
			if tickTimer >= TICK_INTERVAL then
				tickTimer -= TICK_INTERVAL
				tick()
			end
		end
	end
	wait(1/60)
end
