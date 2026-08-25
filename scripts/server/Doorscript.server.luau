local Door: Model = script.Parent
local Left: Model = Door:WaitChild("Left")
local Right: Model = Door:WaitChild("Right")
local Hitbox: Part = Door:WaitChild("Hitbox")
local LeftClosedRotY: number = Left.Rotation.Y
local RightClosedRotY: number = Right.Rotation.Y
local Open: boolean = false

local function SetDoor(open: boolean)
    local leftRotation = LeftClosedRotY
    local rightRotation = RightClosedRotY

    if open then
        leftRotation -= 90
        rightRotation += 90
    end

    local leftTween = Tween:NewTween()
    local rightTween = Tween:NewTween()

    leftTween:TweenRotation(Left, Vector3.New(0, leftRotation, 0), 0.5)
    rightTween:TweenRotation(Right, Vector3.New(0, rightRotation, 0), 0.5)
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