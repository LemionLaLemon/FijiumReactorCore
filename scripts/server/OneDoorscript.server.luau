local DoorModel: Model = script.Parent
local Door: Model = DoorModel:WaitChild("Door")
local Hitbox: Part = DoorModel:WaitChild("Hitbox")
local DoorClosedRotY: number = Door.Rotation.Y
local Open: boolean = false

local function SetDoor(open: boolean)
    local Rotation = DoorClosedRotY

    if open then
        Rotation += 90
    end
		
    local doorTween = Tween:NewTween()

    doorTween:TweenRotation(Door, Vector3.New(0, Rotation, 0), 0.5)
end

Hitbox.Touched:Connect(function(object: Physical)
    if Open then return end

    if object:IsA("Player") then
        Open = true
        SetDoor(true)
    end
end)

Hitbox.TouchEnded:Connect(function(object: Physical)
    if not Open then return end

    if object:IsA("Player") then
        Open = false
        SetDoor(false)
    end
end)