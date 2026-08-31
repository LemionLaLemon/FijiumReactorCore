--[[
	QuestionService

	Lets a server script ask a player a multiple-choice question and get
	their answer back, synchronously from the calling script's point of
	view (i.e. `local answer = QuestionService.Ask(player, "Yes", "No")`
	just blocks until they respond).

	Design notes / why it's built this way:

	- `pending[userID]` tracks at most one in-flight question per player.
	  `resolvePending` is the ONLY function allowed to invoke/destroy a
	  pending BindableEvent, so there's exactly one code path that can
	  ever resolve a question — no risk of a second call silently
	  overwriting `pending[userID]` and leaking the first BindableEvent
	  (and permanently stranding the coroutine waiting on it).

	- Resolving a pending question is deferred one tick (`wait(0)`)
	  inside a freshly spawned coroutine, instead of invoking the
	  BindableEvent synchronously from inside the network response
	  handler. A script like RWPOffice can chain many Ask() calls back
	  to back in one long conversation; if each resolution resumes the
	  waiting coroutine synchronously nested inside the handler that's
	  currently resolving it, a long enough back-and-forth can build up
	  native call-stack depth with every turn instead of releasing it.
	  Deferring to a fresh tick means every resolution starts from a
	  clean stack instead of piling onto the last one.

	- Everything that touches a BindableEvent is pcall-wrapped. This
	  service is shared by every player; one player's pending question
	  hitting a weird engine-level error shouldn't be able to take down
	  the response handler for everyone else.
]]

local QuestionService = {}

-- === Setup: shared Folder + NetworkEvents (created once, reused) ===

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

-- userID -> BindableEvent currently being waited on by an Ask() call
local pending = {}

-- === Core resolution logic ===

-- Resolves and cleans up whatever question is currently pending for a
-- player, if any. See the header comment above for why this is the only
-- place allowed to touch a pending BindableEvent, and why it defers.
local function resolvePending(userID, answer)
	local b = pending[userID]
	if not b then return end
	pending[userID] = nil

	coroutine.wrap(function()
		wait(0) -- start this resolution on a fresh stack, see header notes
		pcall(function()
			b:Invoke(answer)
		end)
		pcall(function()
			b:Destroy()
		end)
	end)()
end

-- === Listeners ===

Players.PlayerRemoved:Connect(function(player)
	resolvePending(player.UserID, nil)
end)

responseEvent.InvokedServer:Connect(function(player, msg)
	if not pending[player.UserID] then return end
	local answer = msg:GetString("answer")
	resolvePending(player.UserID, answer ~= "" and answer or nil)
end)

-- === Public API ===

-- Asks `player` to choose between `...` options. Blocks the calling
-- coroutine until they respond (or disconnect, or the question is
-- otherwise cancelled), then returns their chosen option as a string,
-- or nil if no answer was given.
function QuestionService.Ask(player, ...)
	-- Defensive: if this player somehow already has a question pending
	-- (re-entrant Ask call, leftover state, etc), cancel it cleanly
	-- first instead of silently overwriting pending[player.UserID] and
	-- leaking the old BindableEvent + stranding its coroutine forever.
	resolvePending(player.UserID, nil)

	local b = BindableEvent.New(script)
	pending[player.UserID] = b

	local options = {...}
	local msg = NetMessage.New()
	msg:AddInt("count", #options)
	for i, option in ipairs(options) do
		msg:AddString("opt" .. i, option)
	end
	requestEvent:InvokeClient(msg, player)

	local answer = b.Invoked:Wait()

	-- Normally resolvePending already cleared this and destroyed b by
	-- the time we resume. This is just a safety net in case Wait() ever
	-- returns some other way.
	if pending[player.UserID] == b then
		pending[player.UserID] = nil
	end

	return answer
end

return QuestionService
