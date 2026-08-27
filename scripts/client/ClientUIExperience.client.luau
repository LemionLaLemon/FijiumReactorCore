local CursorGUI: GUI = PlayerGUI:WaitChild("CursorGUI")
local Cursor: UIView = CursorGUI:WaitChild("Cursor")
local LocalCamera: Camera = Environment.CurrentCamera
local cursorUnlocked: boolean = false

Input.KeyDown:Connect(function(keycode: KeyCodeEnum, gamefocused: boolean)
    if not LocalCamera or not LocalCamera.IsFirstPerson or not gamefocused then return end
    if keycode == Enums.KeyCode.F then
        cursorUnlocked = not cursorUnlocked
    end
end)

function _Update()
    if not LocalCamera then return end

    if not LocalCamera.IsFirstPerson then
        CursorGUI.Visible = false
        return
    end

    Input.CursorLocked = not cursorUnlocked
    Input.CursorVisible = cursorUnlocked
    CursorGUI.Visible = not cursorUnlocked
end