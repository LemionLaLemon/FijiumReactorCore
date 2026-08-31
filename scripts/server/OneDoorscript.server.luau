local DoorModel: Model = script.Parent
local Door: Model = DoorModel:WaitChild("Door")
local Hitbox: Part = DoorModel:WaitChild("Hitbox")
local DoorClosedRotY: number = Door.Rotation.Y
local Open: boolean = false

local OpenSound = world.TotallyAudioService:WaitChild("OpenSound"):Clone()
OpenSound.Position = Door.Position
OpenSound.Parent = DoorModel

local CloseSound = world.TotallyAudioService:WaitChild("CloseSound"):Clone()
CloseSound.Position = Door.Position
CloseSound.Parent = DoorModel

local function SetDoor(open: boolean)
  local Rotation = DoorClosedRotY
	
  if open then 
		Rotation += 90 
	end
	
  local doorTween = Tween:NewTween()
	
  doorTween:TweenRotation(Door, Vector3.New(Door.Rotation.X, Rotation, Door.Rotation.Z), 0.5)
end

local players = {}
local closeGen = 0

Players.PlayerRemoved:Connect(function(player)
	players[player] = nil
end)

local function playerInside()
  for _ in pairs(players) do return true end
  return false
end

Hitbox.Touched:Connect(function(object: Physical)
  if not object:IsA("Player") then return end
  players[object] = true
  closeGen += 1
  if not Open then
		OpenSound:Play()
    Open = true
    SetDoor(true)
  end
end)

Hitbox.TouchEnded:Connect(function(object: Physical)
  if not object:IsA("Player") then return end
  players[object] = nil
  if playerInside() then return end

  local myGen = closeGen
  spawn(function()
    wait(1)
    if myGen == closeGen and Open and not playerInside() then
			CloseSound:Play()
      Open = false
      SetDoor(false)
    end
  end)
end)