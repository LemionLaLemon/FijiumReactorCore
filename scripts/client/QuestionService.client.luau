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

local function showResponses(...)
	local responses = {...}
	local selectedResponse = 1
	local done = BindableEvent.New(script)
	local resolved = false
	local chosen

	for _, item in ipairs(QuestionsFrame:GetChildren()) do
		item:Destroy()
	end

	for i, response in ipairs(responses) do
		local responseItem = ResponseTemplate:Clone()
		responseItem.Name = tostring(i)
		responseItem.Prompt.Text = response
		responseItem.Selection.Image = (i == 1) and SelectedAsset or UnselectedAsset
		responseItem.Parent = QuestionsFrame

		responseItem.MouseEnter:Connect(function()
			local prev = QuestionsFrame:FindChild(tostring(selectedResponse))
			if prev and prev ~= responseItem then prev.Selection.Image = UnselectedAsset end
			responseItem.Selection.Image = SelectedAsset
			selectedResponse = i
		end)
		responseItem.MouseExit:Connect(function()
			responseItem.Selection.Image = UnselectedAsset
		end)
		responseItem.MouseUp:Connect(function()
			if resolved then return end
			resolved = true
			selectedResponse = i
			chosen = response
			done:Invoke()
		end)
	end

	local inputConn = Input.KeyDown:Connect(function(key, gamefocused)
		if not gamefocused then return end
		if key == Enums.KeyCode.F or key == Enums.KeyCode.R then
			local prev = QuestionsFrame:FindChild(tostring(selectedResponse))
			if prev then prev.Selection.Image = UnselectedAsset end
			selectedResponse += (key == Enums.KeyCode.F) and 1 or -1
			if selectedResponse > #responses then selectedResponse = 1 end
			if selectedResponse < 1 then selectedResponse = #responses end
			local cur = QuestionsFrame:FindChild(tostring(selectedResponse))
			if cur then cur.Selection.Image = SelectedAsset end
		elseif key == Enums.KeyCode.Enter then
			if resolved then return end
			resolved = true
			chosen = responses[selectedResponse]
			done:Invoke()
		end
	end)

	local closeConn = CloseButton.MouseUp:Connect(function()
		if resolved then return end
		resolved = true
		chosen = nil
		done:Invoke()
	end)

	QuestionGUI.Visible = true

	coroutine.wrap(function()
		wait(60)
		if resolved then return end
		resolved = true
		chosen = nil
		done:Invoke()
	end)()

	done.Invoked:Wait()

	inputConn:Disconnect()
	closeConn:Disconnect()
	done:Destroy()
	QuestionGUI.Visible = false
	for _, item in ipairs(QuestionsFrame:GetChildren()) do
		item:Destroy()
	end

	return chosen
end

QuestionRequestEvent.InvokedClient:Connect(function(msg)
	local count = msg:GetInt("count")
	local options = {}
	for i = 1, count do
		options[i] = msg:GetString("opt" .. i)
	end
	local answer = showResponses(table.unpack(options))
	local resp = NetMessage.New()
	resp:AddString("answer", answer or "")
	QuestionResponseEvent:InvokeServer(resp)
end)
