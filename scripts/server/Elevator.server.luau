local floors: {number} = {-66.793, -37.393, -7.593}
local bottom: number = 1
local top: number = 3
local carCall: {number} = {}
local hallUp: {number} = {}
local hallDown: {number} = {}

local direction: string = "idle" -- up/down/idle
local currentFloor: number = 1
local moving: boolean = false
local doorsOpen: boolean = false
local holdOpen: boolean = false
local doorBusy: boolean = false
local blinkTick: number = 0
local floor2HallDir: string = "" -- "" / "up" / "down": which 2F hall call summoned the car
local target: number = currentFloor

local car: Model = script.Parent:WaitChild("Car")
local initialPosition: Vector3 = car.Position
local carDoor: Model = car:WaitChild("Doors")

local Doors: {Model} = {}
Doors[1] = script.Parent:WaitChild("1F"):WaitChild("Doors")
Doors[2] = script.Parent:WaitChild("2F"):WaitChild("Doors")
Doors[3] = script.Parent:WaitChild("3F"):WaitChild("Doors")

local b1Up = script.Parent:WaitChild("1F"):WaitChild("Up"):WaitChild("Hitbox")
local b2Up = script.Parent:WaitChild("2F"):WaitChild("Up"):WaitChild("Hitbox")
local b2Down = script.Parent:WaitChild("2F"):WaitChild("Down"):WaitChild("Hitbox")
local b3Down = script.Parent:WaitChild("3F"):WaitChild("Down"):WaitChild("Hitbox")
local bCar1 = car:WaitChild("Buttons"):WaitChild("1")
local bCar2 = car:WaitChild("Buttons"):WaitChild("2")
local bCar3 = car:WaitChild("Buttons"):WaitChild("3")
local openButton = car:WaitChild("Buttons"):WaitChild("Open")
local closeButton = car:WaitChild("Buttons"):WaitChild("Close")

local YELLOW      = Color.FromHex("FFD400")
local WHITE       = Color.FromHex("FFFFFF")
local LANTERN_OFF = Color.FromHex("1E1E1E")
local CALL_OFF    = Color.FromHex("877F55")
local CALL_ON     = Color.FromHex("E0D38A")

local lantUp = {
	[1] = script.Parent:WaitChild("1F"):WaitChild("LanternUp"),
	[2] = script.Parent:WaitChild("2F"):WaitChild("LanternUp"),
	[3] = script.Parent:WaitChild("3F"):WaitChild("LanternUp"),
}
local lantDown = {
	[1] = script.Parent:WaitChild("1F"):WaitChild("LanternDown"),
	[2] = script.Parent:WaitChild("2F"):WaitChild("LanternDown"),
	[3] = script.Parent:WaitChild("3F"):WaitChild("LanternDown"),
}

local callLightUp = {
	[1] = b1Up.Parent:WaitChild("Light"),
	[2] = b2Up.Parent:WaitChild("Light"),
}
local callLightDown = {
	[2] = b2Down.Parent:WaitChild("Light"),
	[3] = b3Down.Parent:WaitChild("Light"),
}

local carText = {
	[1] = bCar1:WaitChild("Text3D"),
	[2] = bCar2:WaitChild("Text3D"),
	[3] = bCar3:WaitChild("Text3D"),
}
local openText  = openButton:WaitChild("Text3D")
local closeText = closeButton:WaitChild("Text3D")

-- In-car floor indicator Text3Ds (direct children of the car)
local carFloorText = {
	[1] = car:WaitChild("1"),
	[2] = car:WaitChild("2"),
	[3] = car:WaitChild("3"),
}
local poweredObj = script.Parent:FindChild("Powered")
local function powered(): boolean return poweredObj ~= nil and poweredObj.Value end
local arrivedSound = script.Parent:FindChild("Arrived") or car:FindChild("Arrived")

local function updateIndicators()
	if not powered() then
		for f = bottom, top do
			if lantUp[f]   then lantUp[f].Color   = LANTERN_OFF end
			if lantDown[f] then lantDown[f].Color = LANTERN_OFF end
			if carFloorText[f] then carFloorText[f].Color = LANTERN_OFF end
		end
		for _, light in pairs(callLightUp)   do light.Color = CALL_OFF end
		for _, light in pairs(callLightDown) do light.Color = CALL_OFF end
		for _, t in pairs(carText) do t.Color = WHITE end
		openText.Color = WHITE
		closeText.Color = WHITE
		return
	end

	local blink = (blinkTick % 6) < 3
	for f = bottom, top do
		local up: boolean = false
		local down: boolean = false
		if direction == "idle" then
			up = hallUp[f] == true
			down = hallDown[f] == true
		elseif direction == "up" then
			up = currentFloor <= f and f <= target
		else
			down = currentFloor >= f and f >= target
		end
		if lantUp[f]   then lantUp[f].Color   = up   and YELLOW or LANTERN_OFF end
		if lantDown[f] then lantDown[f].Color = down and YELLOW or LANTERN_OFF end
		local c = carFloorText[f]
		if c then
			if f == currentFloor then
				c.Color = YELLOW
			elseif f == target and target ~= currentFloor then
				c.Color = blink and YELLOW or LANTERN_OFF
			else
				c.Color = LANTERN_OFF
			end
		end
	end
	for f, light in pairs(callLightUp) do
		light.Color = hallUp[f] and CALL_ON or CALL_OFF
	end
	for f, light in pairs(callLightDown) do
		light.Color = hallDown[f] and CALL_ON or CALL_OFF
	end
	for f, t in pairs(carText) do
		t.Color = carCall[f] and YELLOW or WHITE
	end
	openText.Color = holdOpen and YELLOW or WHITE
end

updateIndicators()

local function requestedAt(floor: number): boolean
	return carCall[floor] or hallUp[floor] or hallDown[floor]
end

local function nextStopLOOK(): number
	if direction == "idle" then
		for floor = currentFloor + 1, top do
			if requestedAt(floor) then
				return floor
			end
		end
		direction = "down"
		for floor = currentFloor - 1, bottom, -1 do
			if requestedAt(floor) then
				return floor
			end
		end
	else
		if direction == "up" then
			for floor = currentFloor + 1, top do
				if requestedAt(floor) then
					return floor
				end
			end
			direction = "down"
			for floor = top, bottom, -1 do
				if requestedAt(floor) then
					return floor
				end
			end
		else
			for floor = currentFloor - 1, bottom, -1 do
				if requestedAt(floor) then
					return floor
				end
			end
			direction = "up"
			for floor = bottom, top do
				if requestedAt(floor) then
					return floor
				end
			end
		end
	end
	direction = "idle"
	return currentFloor
end

local function serviceStop(floor: number)
	carCall[floor] = nil
	if direction == "up" then
		hallUp[floor] = nil
	elseif direction == "down" then
		hallDown[floor] = nil
	else
		hallUp[floor] = nil
		hallDown[floor] = nil
	end
end

local function makeDoor(parent: Instance, name: string, offsetFn: (BasePart) -> number)
	local part = parent:WaitChild(name)
	return { part = part, homeX = part.Position.X, openX = offsetFn(part) }
end

local function slide(d: any, open: boolean, dur: number)
	local pos = d.part.Position
	local x = open and (d.homeX - d.openX) or d.homeX
	local tween = Tween:NewTween()
	tween:TweenPosition(d.part, Vector3.New(x, pos.Y, pos.Z), dur)
	return tween
end

local function await(tweens: {any})
	for _, t in ipairs(tweens) do
		pcall(function()
			if t and t.Finished then
				t.Finished:Wait()
			end
		end)
	end
end

local carDoors = {
	Out = makeDoor(carDoor, "Out", function(p) return p.Size.Z end),
	In = makeDoor(carDoor, "In",  function(p) return p.Size.Z * 2 + 0.1 end),
}

local floorDoors = {}
for f = bottom, top do
	local d = Doors[f]
	floorDoors[f] = {
		Out = makeDoor(d, "Out", function(p) return p.Size.Z end),
		In = makeDoor(d, "In",  function(p) return p.Size.Z * 2 + 0.1 end),
	}
end

local function setDoors(floor: number, open: boolean): {any}
	local t = {
		slide(carDoors.Out, open, 1),
		slide(carDoors.In,  open, 1),
	}
	local fd = floorDoors[floor]
	table.insert(t, slide(fd.Out, open, 1))
	table.insert(t, slide(fd.In,  open, 1))
	return t
end

local function openDoor(floor: number)
	if doorBusy then while doorBusy do wait(0.05) end end
	doorBusy = true
	await(setDoors(floor, true))
	doorsOpen = true
	doorBusy = false
end

local function closeDoor(floor: number)
	if doorBusy then while doorBusy do wait(0.05) end end
	if not doorsOpen then return end
	doorBusy = true
	await(setDoors(floor, false))
	doorsOpen = false
	doorBusy = false
end

local function goToFloor(floor: number)
	if floor == currentFloor then return end
	if not powered() then return end
	moving = true
	local startY = car.Position.Y
	local endY = floors[floor]
	local dur = 5 * math.abs(floor - currentFloor)
	local elapsed = 0
	local interrupted = false
	-- direct lerp so travel can be halted if power is lost mid-move.
	-- the in-car floor lights track the car's actual position while travelling:
	-- the floor the car is over shows solid, the destination keeps blinking.
	local function nearestFloor()
		local nf = bottom
		local best = math.huge
		for f = bottom, top do
			local d = math.abs(car.Position.Y - floors[f])
			if d < best then best = d; nf = f end
		end
		return nf
	end
	while elapsed < dur do
		if not powered() then interrupted = true; break end
		local t = elapsed / dur
		car.Position = Vector3.New(initialPosition.X, startY + (endY - startY) * t, initialPosition.Z)
		local nf = nearestFloor()
		if nf ~= currentFloor then currentFloor = nf end
		blinkTick = blinkTick + 1
		updateIndicators()
		wait(0.1)
		elapsed = elapsed + 0.1
	end
	if interrupted then
		-- no DC backup: snap to nearest floor and sit there
		currentFloor = nearestFloor()
		car.Position = Vector3.New(initialPosition.X, floors[currentFloor], initialPosition.Z)
	else
		car.Position = Vector3.New(initialPosition.X, endY, initialPosition.Z)
		currentFloor = floor
	end
	updateIndicators()
	moving = false
	if not interrupted and arrivedSound then pcall(function() arrivedSound:Play() end) end
end

local function connect(btn: Instance, fn: () -> ())
	if btn.Activated then btn.Activated:Connect(fn); return end
	if btn.MouseClick then btn.MouseClick:Connect(fn); return end
	if btn.Triggered then btn.Triggered:Connect(fn); return end
	btn.Clicked:Connect(function(player) fn(player) end)
end

connect(b1Up, function() hallUp[1] = true; updateIndicators() end)
connect(b2Up, function() hallUp[2] = true; updateIndicators() end)
connect(b2Down, function() hallDown[2] = true; updateIndicators() end)
connect(b3Down, function() hallDown[3] = true; updateIndicators() end)
connect(bCar1, function(player)
	carCall[1] = true
	if player and currentFloor == 2 and floor2HallDir == "up" then
		pcall(function() Achievements:AwardAsync(player.UserID, 237247) end)
	end
	updateIndicators()
end)
connect(bCar2, function() carCall[2] = true; updateIndicators() end)
connect(bCar3, function(player)
	carCall[3] = true
	if player and currentFloor == 2 and floor2HallDir == "down" then
		pcall(function() Achievements:AwardAsync(player.UserID, 237247) end)
	end
	updateIndicators()
end)
connect(openButton, function()
	if moving or holdOpen or not powered() then return end
	holdOpen = true
	updateIndicators()
	wait(3)
	holdOpen = false
	updateIndicators()
end)
connect(closeButton, function()
	if not powered() then return end
	holdOpen = false
	closeText.Color = YELLOW
	closeDoor(currentFloor)
	closeText.Color = WHITE
	updateIndicators()
end)

while true do
	target = nextStopLOOK()
	local had = requestedAt(target)
	blinkTick = blinkTick + 1
	if target == 2 and (hallUp[2] or hallDown[2]) then
		floor2HallDir = hallUp[2] and "up" or "down"
	else
		floor2HallDir = ""
	end
	updateIndicators()

	if not powered() then
		wait(0.5)
	elseif holdOpen then
		-- Open button is holding the doors: keep them open, don't move or service
		if not doorsOpen then openDoor(currentFloor) end
		wait(0.1)
	else
		if target ~= currentFloor then
			closeDoor(currentFloor)   -- interlock: doors shut before the car moves
			goToFloor(target)
			currentFloor = target
		end
		if had then
			openDoor(currentFloor)
			local waited = 0
			while waited < 3 do
				if not powered() then break end
				wait(0.1)
				waited = waited + 0.1
			end
			closeDoor(currentFloor)
			serviceStop(target)
		else
			if doorsOpen then closeDoor(currentFloor) end
			serviceStop(target)
		end
	end
	wait(0.1)
end