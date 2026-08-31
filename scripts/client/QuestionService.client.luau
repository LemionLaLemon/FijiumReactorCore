local QuestionGUI = script.Parent
local ResponseTemplate = QuestionGUI:WaitChild("Template"):WaitChild("Question")
local CloseButton = QuestionGUI:WaitChild("CloseHitbox")
local QuestionsFrame = QuestionGUI:WaitChild("Scrollframe"):WaitChild("Questions")
local QuestionRequestEvent: NetworkEvent = world:WaitChild("TotallyQuestionService"):WaitChild("QuestionRequest")
local QuestionResponseEvent: NetworkEvent = world:WaitChild("TotallyQuestionService"):WaitChild("QuestionResponse")

local function makeImage(id)
	local a = PTImageAsset.New(script)
	a.ImageID = id
	a.ImageType = Enums.ImageType.Asset
	return a
end
local SelectedAsset = makeImage(237562)
local UnselectedAsset = makeImage(237561)

-- Client-side concurrency control
local currentQuestionId = 0
local activeDoneEvent = nil

local function showResponses(questionId, responses)
	-- Cancel previous pending dialog if any
	if activeDoneEvent then
		pcall(function() activeDoneEvent:Invoke(nil) end)
	end

	local done = BindableEvent.New(script)
	activeDoneEvent = done
	local selectedResponse = 1
	local resolved = false
	local chosen = nil

	-- Clean up previous buttons
	for _, item in ipairs(QuestionsFrame:GetChildren()) do
		item:Destroy()
	end

	-- Instantiate new response options
	for i, response in ipairs(responses) do
		local responseItem = ResponseTemplate:Clone()
		responseItem.Name = tostring(i)
		responseItem.Prompt.Text = response
		responseItem.Selection.Image = (i == 1) and SelectedAsset or UnselectedAsset
		responseItem.Parent = QuestionsFrame

		responseItem.MouseEnter:Connect(function()
			if resolved or currentQuestionId ~= questionId then return end
			local prev = QuestionsFrame:FindChild(tostring(selectedResponse))
			if prev and prev ~= responseItem then prev.Selection.Image = UnselectedAsset end
			responseItem.Selection.Image = SelectedAsset
			selectedResponse = i
		end)

		responseItem.MouseExit:Connect(function()
			if resolved or currentQuestionId ~= questionId then return end
			responseItem.Selection.Image = UnselectedAsset
		end)

		responseItem.MouseUp:Connect(function()
			if resolved or currentQuestionId ~= questionId then return end
			resolved = true
			chosen = response
			done:Invoke(chosen)
		end)
	end

	-- Key navigation (R, F, Enter)
	local inputConn
	inputConn = Input.KeyDown:Connect(function(key, gamefocused)
		if not gamefocused or resolved or currentQuestionId ~= questionId then return end
		if key == Enums.KeyCode.F or key == Enums.KeyCode.R then
			local prev = QuestionsFrame:FindChild(tostring(selectedResponse))
			if prev then prev.Selection.Image = UnselectedAsset end
			selectedResponse += (key == Enums.KeyCode.F) and 1 or -1
			if selectedResponse > #responses then selectedResponse = 1 end
			if selectedResponse < 1 then selectedResponse = #responses end
			local cur = QuestionsFrame:FindChild(tostring(selectedResponse))
			if cur then cur.Selection.Image = SelectedAsset end
		elseif key == Enums.KeyCode.Enter then
			resolved = true
			chosen = responses[selectedResponse]
			done:Invoke(chosen)
		end
	end)

	-- Close button listener
	local closeConn
	closeConn = CloseButton.MouseUp:Connect(function()
		if resolved or currentQuestionId ~= questionId then return end
		resolved = true
		chosen = nil
		done:Invoke(nil)
	end)

	QuestionGUI.Visible = true

	-- Safety timeout (30 seconds)
	coroutine.wrap(function()
		wait(30)
		if not resolved and currentQuestionId == questionId then
			resolved = true
			done:Invoke(nil)
		end
	end)()

	-- Wait for resolution
	local answer = done.Invoked:Wait()

	-- Clean up connections and BindableEvent safely
	if inputConn then inputConn:Disconnect() end
	if closeConn then closeConn:Disconnect() end
	pcall(function() done:Destroy() end)
	if activeDoneEvent == done then activeDoneEvent = nil end

	-- Only hide UI if this question is still the active one
	if currentQuestionId == questionId then
		QuestionGUI.Visible = false
		for _, item in ipairs(QuestionsFrame:GetChildren()) do
			item:Destroy()
		end
	end

	return answer
end

QuestionRequestEvent.InvokedClient:Connect(function(msg)
	currentQuestionId += 1
	local myQId = currentQuestionId
	local count = msg:GetInt("count")
	local options = {}
	for i = 1, count do
		options[i] = msg:GetString("opt" .. i)
	end

	local answer = showResponses(myQId, options)

	-- Only send answer if this question was not superseded
	if currentQuestionId == myQId then
		local resp = NetMessage.New()
		resp:AddInt("qid", myQId)
		resp:AddString("answer", answer or "")
		QuestionResponseEvent:InvokeServer(resp)
	end
end)
