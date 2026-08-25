local Door = script.Parent["Door"]
local Hitbox = script.Parent["Hitbox"]
local Opening = false
local OpenSound = Instance.New("Sound",Door)
OpenSound.SoundID = 105227
OpenSound.PlayInWorld = true
OpenSound.Position = Door.Position
OpenSound.Volume = 0.7
local CloseSound = Instance.New("Sound",Door)
CloseSound.SoundID = 97784
CloseSound.PlayInWorld = true
CloseSound.Volume = 0.7
CloseSound.Position = Door.Position

Hitbox.Touched:Connect(function()
	if Opening then return end
	OpenSound.Pitch = math.random(0.9,1.1)
	CloseSound.Pitch = math.random(0.9,1.1)
	OpenSound.Play()
	Opening = true
	Tween:TweenRotation(
		Door,
		Vector3.New(0, 100, 270),
		2,
		TweenType.easeOutCubic
	)
	wait(3)
	Tween:TweenRotation(
		Door,
		Vector3.New(0, 180, 270),
		2,
		TweenType.easeOutCubic
	)
	Opening = false
	wait(1.2)
	CloseSound.Play()
end)