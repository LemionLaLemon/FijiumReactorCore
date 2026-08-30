local Door: Model = script.Parent
local Left: Model = Door:WaitChild("Left")
local Right: Model = Door:WaitChild("Right")
local Hitbox: Part = Door:WaitChild("Hitbox")
local LeftClosedRotY: number = Left.Rotation.Y
local RightClosedRotY: number = Right.Rotation.Y
local Open: boolean = false

local OpenSound = world.TotallyAudioService:WaitChild("OpenSound"):Clone()
OpenSound.Position = Door.Position
OpenSound.Parent = Door

local CloseSound = world.TotallyAudioService:WaitChild("CloseSound"):Clone()
CloseSound.Position = Door.Position
CloseSound.Parent = Door

local function SetDoor(open: boolean)
  local leftRotation, rightRotation = LeftClosedRotY, RightClosedRotY
	
  if open then 
		leftRotation -= 90
		rightRotation += 90 
	end
	
  local leftTween, rightTween = Tween:NewTween(), Tween:NewTween()
	
  leftTween:TweenRotation(Left, Vector3.New(0, leftRotation, 0), 0.5)
  rightTween:TweenRotation(Right, Vector3.New(0, rightRotation, 0), 0.5)
end

local players = {} 
local closeGen = 0

Players.PlayerRemoved:Connect(function(player)
	players[player] = nil
end)

local function playerInside()
  for _ in pairs(players) do 
		return true 
	end
  return false
end

Hitbox.Touched:Connect(function(object: Physical)
  if not object:IsA("Player") then return end
  players[object] = true
  closeGen += 1
  if not Open then
	  OpenSound.Pitch = math.random(0.9, 1.1)
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
      CloseSound.Pitch = math.random(0.9, 1.1)
      CloseSound:Play()
      Open = false
      SetDoor(false)
    end
  end)
end)