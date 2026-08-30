local folder = world:FindChild("TotallyQuestionService")
if not folder then
	folder = Instance.New("Folder", world)
	folder.Name = "TotallyQuestionService"
end

local requestEvent = folder:FindChild("QuestionRequest")
if not requestEvent then
	requestEvent = Instance.New("NetworkEvent", folder)
	requestEvent.Name = "QuestionRequest"
end

local responseEvent = folder:FindChild("QuestionResponse")
if not responseEvent then
	responseEvent = Instance.New("NetworkEvent", folder)
	responseEvent.Name = "QuestionResponse"
end

local pending = {}

Players.PlayerRemoved:Connect(function(player)
	local b = pending[player.UserID]
	if b then
		pending[player.UserID] = nil
		b:Invoke(nil)
		b:Destroy()
	end
end)

responseEvent.InvokedServer:Connect(function(player, msg)
	local b = pending[player.UserID]
	if b then
		pending[player.UserID] = nil
		local answer = msg:GetString("answer")
		b:Invoke(answer ~= "" and answer or nil)
		b:Destroy()
	end
end)

local function Ask(player, ...)
	local b = BindableEvent.New(script)
	pending[player.UserID] = b
	local args = {...}
	local msg = NetMessage.New()
	msg:AddInt("count", #args)
	for i, v in ipairs(args) do
		msg:AddString("opt" .. i, v)
	end
	requestEvent:InvokeClient(msg, player)
	return b.Invoked:Wait()
end

return { Ask = Ask }
