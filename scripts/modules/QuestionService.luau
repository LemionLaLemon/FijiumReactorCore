local QuestionService = {}

-- === Setup: shared Folder + NetworkEvents ===

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

-- userID -> { event: BindableEvent, qid: number }
local pending = {}
local userSequence = {}

local function resolvePending(userID, answer)
	local entry = pending[userID]
	if not entry then return end
	pending[userID] = nil

	pcall(function()
		entry.event:Invoke(answer)
		entry.event:Destroy()
	end)
end

-- === Listeners ===

Players.PlayerRemoved:Connect(function(player)
	resolvePending(player.UserID, nil)
	userSequence[player.UserID] = nil
end)

responseEvent.InvokedServer:Connect(function(player, msg)
	local entry = pending[player.UserID]
	if not entry then return end

	local qid = msg:GetInt("qid")
	-- Reject responses intended for previous question instances
	if qid and qid ~= entry.qid then return end

	local answer = msg:GetString("answer")
	resolvePending(player.UserID, (answer ~= "" and answer or nil))
end)

-- === Public API ===

function QuestionService.Ask(player, ...)
	-- Clean up any active question for this player first
	resolvePending(player.UserID, nil)

	local nextQId = (userSequence[player.UserID] or 0) + 1
	userSequence[player.UserID] = nextQId

	local b = BindableEvent.New(script)
	pending[player.UserID] = { event = b, qid = nextQId }

	local options = {...}
	local msg = NetMessage.New()
	msg:AddInt("qid", nextQId)
	msg:AddInt("count", #options)
	for i, option in ipairs(options) do
		msg:AddString("opt" .. i, option)
	end
	requestEvent:InvokeClient(msg, player)

	local answer = b.Invoked:Wait()

	if pending[player.UserID] and pending[player.UserID].event == b then
		pending[player.UserID] = nil
	end

	return answer
end

return QuestionService
