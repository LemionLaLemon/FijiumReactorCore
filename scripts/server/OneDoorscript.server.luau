local DoorModel: Model = script.Parent
local Door: Model = DoorModel:WaitChild("Door")
local Hitbox: Part = DoorModel:WaitChild("Hitbox")
local DoorClosedRotY: number = Door.Rotation.Y
local Open: boolean = false

local OpenSound = Instance.New("Sound", Door)
OpenSound.PlayInWorld = true
OpenSound.Volume = 0.7
OpenSound.Audio = PTAudioAsset.New(105227)
OpenSound.MaxDistance = 40
OpenSound.AttenuationMode = Enums.SoundAttenuationMode.Linear
OpenSound.Position = Door.Position

local CloseSound = Instance.New("Sound", Door)
CloseSound.PlayInWorld = true
CloseSound.Volume = 0.7
CloseSound.Audio = PTAudioAsset.New(97784)
CloseSound.MaxDistance = 40
CloseSound.AttenuationMode = Enums.SoundAttenuationMode.Linear
CloseSound.Position = Door.Position

local function SetDoor(open: boolean)
  local Rotation = DoorClosedRotY
	
  if open then 
		Rotation += 90 
	end
	
  local doorTween = Tween:NewTween()
	
  doorTween:TweenRotation(Door, Vector3.New(0, Rotation, 0), 0.5)
end

local players = {}
local closeGen = 0

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