
--not a full on ui library

local TServ = game:GetService("TweenService")
local displaySortsTInfo = TweenInfo.new()
local decalViewer = {}

function decalViewer.newUi(optionsTab)
	local window, uiList, optionsTab = {}, {}, optionsTab or {}
	
	--thank god gui2lua plugin exists (still a bit of a messy plugin but meh)
	local Gui = Instance.new("ScreenGui")
	local UiHider = Instance.new("TextButton")
	local SorterUi = Instance.new("TextLabel")
	local DecalsFrame = Instance.new("ScrollingFrame")
	
	do
		Gui.Name = "Gui"
		Gui.Enabled = optionsTab.Visible or true
		DecalsFrame.Name = "DecalsFrame"
		UiHider.Name = "UiHider"
		SorterUi.Name = "SorterUi"
		UiHider.BackgroundColor3 = Color3.fromRGB(255, 196, 196)
		UiHider.BorderColor3 = Color3.fromRGB(105, 0, 0)
		UiHider.BorderSizePixel = 3
		UiHider.Position = UDim2.new(0, 0, 0, 0)
		UiHider.Size = UDim2.new(0.65, 0, 0, 35)
		UiHider.ZIndex = 5
		UiHider.AutoButtonColor = false
		UiHider.Text = "Hide Ui"
		UiHider.TextColor3 = Color3.fromRGB(255, 255, 255)
		UiHider.TextScaled = true
		
		SorterUi.BackgroundColor3 = Color3.fromRGB(255, 196, 196)
		SorterUi.BorderColor3 = Color3.fromRGB(105, 0, 0)
		SorterUi.BorderSizePixel = 3
		SorterUi.Position = UDim2.new(0.65, UiHider.BorderSizePixel, 0, 0)
		SorterUi.Size = UDim2.new(0.35, -UiHider.BorderSizePixel, 0, 35)
		SorterUi.ZIndex = 5
		SorterUi.Text = "Sort Decals"
		SorterUi.TextColor3 = Color3.fromRGB(255, 255, 255)
		SorterUi.TextScaled = true
		
		DecalsFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		DecalsFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		DecalsFrame.BackgroundTransparency = 0.8
		DecalsFrame.BorderSizePixel = 0
		DecalsFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
		DecalsFrame.Size = UDim2.new(0.6, 0, 0.6, 0)
		DecalsFrame.SizeConstraint = Enum.SizeConstraint.RelativeYY
		DecalsFrame.AutomaticCanvasSize = Enum.AutomaticSize.XY
		DecalsFrame.CanvasSize = UDim2.new(0, 0, 1, 0)
		DecalsFrame.ScrollBarThickness = 7
		
		UiHider.Parent = DecalsFrame
		SorterUi.Parent = DecalsFrame
		DecalsFrame.Parent = Gui
		
		pcall(function()
			if syn then syn.protect_gui(Gui) end
			Gui.Parent = game:GetService("CoreGui")
		end)
		
		task.wait()
		if Gui.Parent ~= game:GetService("CoreGui") then
			Gui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
		end
	end

	local itemsPerWait = 150
	local decalScaleSize = optionsTab.DecalSize or optionsTab.DecalScaleSize or 0.1
	local uiPerRow = 1/decalScaleSize	

	local visibleTween = TServ:Create(DecalsFrame, TweenInfo.new(0.7, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
		["Size"] = DecalsFrame.Size
	})
	local notVisibleTween = TServ:Create(DecalsFrame, TweenInfo.new(0.7, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {
		["Size"] = UDim2.new(DecalsFrame.Size.X.Scale, DecalsFrame.Size.X.Offset, 0, DecalsFrame.Size.Y.Offset) 
	})
		
	
	local function deepGet(tab, index)
		local tab2 = {}

		for i, v in pairs(uiList[index]) do
			if type(v) == 'table' and v ~= tab and #v ~= 0 then
				v = deepGet(v, 1)
			end
			tab2[i] = v
		end
		return tab2
	end
	
	local function getColumnAndRow(uiNumber)
		local divided = uiNumber/uiPerRow
		local column = divided%1
		local row = math.floor(divided)*decalScaleSize
		return column, row
	end

	function window.arrangeDecals(propertyName, flipOrder)
		local propertyName = propertyName or window.sortedProperty or "InsertTime"
		if type(uiList[1][propertyName]) ~= "number" then warn("Sorting only works with numbers, remove the", propertyName,"property to fix the issue.\nDetails: Number expected, got", typeof(uiList[1][propertyName])) return end
		window.sortedProperty = propertyName
		window.flipSortOrder = flipOrder or window.flipSortOrder
		
		local orderFunction = function(val1, val2)
			return val1[propertyName] > val2[propertyName]
		end
		if window.flipSortOrder then 
			orderFunction = function(val1, val2)
				return val1[propertyName] < val2[propertyName]
			end
		end

		table.sort(uiList, orderFunction)

		for i = 1, #uiList do
			local columnPos, rowPos = getColumnAndRow(i-1)
			local decalGui = uiList[i].decalGui
			decalGui.Position = UDim2.new(columnPos, 0, rowPos, UiHider.Size.Y.Offset + UiHider.BorderSizePixel)
		end
	end
	
	function window.newDecal(infoList, uiProperties)
		infoList = infoList or {}
		local decalGui, uiProperties, otherProperties = Instance.new("ImageButton"), uiProperties or {}, infoList or {}
		if uiProperties.Image and string.sub(uiProperties.Image, 1, 13) ~= "rbxassetid://" then warn("Image must be an asset id (rbxassetid://[IDNumberHere])") return end
		
		decalGui.Name = "decalGui"decalGui.AutoLocalize = false
		decalGui.AutoButtonColor = false
		decalGui.BackgroundColor3 = uiProperties.BackgroundColor3 or Color3.new(0.8, 0.8, 0.8)
		decalGui.BorderMode = Enum.BorderMode.Inset
		decalGui.BorderSizePixel = 1
		decalGui.BorderColor3 = Color3.new(decalGui.BackgroundColor3.R*0.9, decalGui.BackgroundColor3.G*0.9, decalGui.BackgroundColor3.B*0.9)
		decalGui.Size = UDim2.new(decalScaleSize, 0, decalScaleSize, 0)
		decalGui.SizeConstraint = Enum.SizeConstraint.RelativeXX
		
		decalGui.Image = uiProperties.Image or ""
		
		local nextIndex = #uiList + 1
		uiList[nextIndex] = {}
		uiList[nextIndex].decalGui = decalGui
		uiList[nextIndex].decalGuiProperties = uiProperties
		otherProperties["InsertTime"] = DateTime.now().UnixTimestampMillis
		for i, v in pairs(otherProperties) do --put other important properties here
			uiList[nextIndex][i] = v
		end
		for i, v in pairs(uiProperties) do
			decalGui[i] = v
		end

		local columnPos, rowPos = getColumnAndRow(nextIndex-1)

		if window.sortNewDecals == false then
			decalGui.Position = UDim2.new(columnPos, 0, rowPos, UiHider.Size.Y.Offset + UiHider.BorderSizePixel)
		else
			window.arrangeDecals()
		end
		
		--[[ screw canvas resize, just gonna hope roblox auto resize isnt too garbage
		local decalsCanvasSizeY = math.floor(DecalsFrame.AbsoluteCanvasSize.Y*10)*0.1
		if rowPos*decalGui.AbsoluteSize.Y > decalsCanvasSizeY then
			print(rowPos, decalsCanvasSizeY)
			DecalsFrame.CanvasSize = UDim2.new(0,0,1,(rowPos*DecalsFrame.AbsoluteSize.Y*decalScaleSize) + rowPos*DecalsFrame.AbsoluteSize.Y)
		end
		]]
		
		columnPos, rowPos = nil
		decalGui.Parent = DecalsFrame
		
		local decalFuncs = {}
		decalFuncs.__mode = "kv"
		
		function decalFuncs.getListIndex()
			local newListIndex
			for i = 1, #uiList do
				if i%itemsPerWait == 0 then task.wait() end
				if uiList[i].decalGui == decalFuncs.Gui then
					newListIndex = i
					break
				end
			end
			return newListIndex
		end
		
		function decalFuncs:Destroy()
			local newListIndex = self.getListIndex()
			self = nil
			if decalFuncs.Gui then decalFuncs.Gui:Destroy() end
			if decalFuncs.clickEvent then decalFuncs.clickEvent:Disconnect() end
			if decalFuncs.clickEvent2 then decalFuncs.clickEvent2:Disconnect() end
			if not newListIndex then return end
			
			table.remove(uiList, newListIndex)
		end
		
		if window.callback1 then
			decalFuncs.clickEvent = decalGui.MouseButton1Up:Connect(function(x, y)
				window.callback1(otherProperties, x, y)
			end)
		end
		if window.callback2 then
			decalFuncs.clickEvent2 = decalGui.MouseButton2Up:Connect(function(x, y)
				window.callback2(otherProperties, x, y)
			end)
		end
		
		decalFuncs.Gui, decalGui, uiProperties = decalGui, nil, nil
		
		return decalFuncs
	end
	
	function window.findDuplicateDecal(assetId)
		for i = 1, #uiList do
			if uiList[i].decalGui.Image == assetId then
				return i
			end
		end
	end
	
	function window.toggleVisible(bool) --no bool will cause it to toggle to the opposite state
		bool = bool or not window.Visible
		
		local tweenToPlay = notVisibleTween
		if bool == true then tweenToPlay = visibleTween Gui.Enabled = true end
		
		tweenToPlay:Play()
		tweenToPlay.Completed:Wait()
		task.wait()
		
		Gui.Enabled, window.Visible = bool, bool
	end

	function window.getGui()
		return Gui
	end
	
	function window.getRawList() --i kno, i wil use httpservice to make it a json later (the pain of converting userdatas D:)
		local data = {}
		
		for i = 1, #uiList do
			data[i] = deepGet(uiList, i)
			data[i].decalGui = nil
		end
		return data
	end
	window.getList = window.getRawList
	
	do
		local list = optionsTab.RawList or optionsTab.List or {}
		
		for i = 1, #list do
			if i%itemsPerWait == 0 then task.wait() end
			local uiProps = {}
			for i, v in pairs(list[i].decalGuiProperties) do
				uiProps[i] = v
			end
			list[i].decalGuiProperties = nil
			print("loading", list[i], uiProps)
			window.newDecal(list[i], uiProps)
		end
		
		UiHider.MouseButton1Up:Connect(function()
			window.toggleVisible()
		end)
		
		
		local buttons = {}
		local sortDirectionBtn = Instance.new("TextButton")
		sortDirectionBtn.BackgroundColor3 = Color3.new(1, 1, 1)
		sortDirectionBtn.BorderSizePixel = 0
		sortDirectionBtn.Size = UDim2.new(1, 0, 1, 0)
		sortDirectionBtn.Position = UDim2.new(0, 0, 1, 0)
		sortDirectionBtn.ZIndex = 5
		sortDirectionBtn.TextScaled = true
		sortDirectionBtn.Text = "Flip Ui Order (Current: Ascending)"
		
		sortDirectionBtn:SetAttribute("flipOrder", true)
		if optionsTab.SortableProperties then
			local btn = Instance.new("TextButton")
			btn.BorderSizePixel = 0
			btn.Transparency = 0.4
			btn.BackgroundColor3 = Color3.new(0.95, 0.9, 0.9)
			btn.Size = UDim2.new(1, 0, 1, 0)
			btn.Position = UDim2.new(0, 0, #buttons+1, 0)
			btn.Text = "Stop auto sorting"
			btn.TextColor3 = Color3.new(1, 0.5, 0.5) 
			btn.TextScaled = true
			btn.ZIndex = 5
			btn.Visible = false
			buttons[#buttons + 1] = btn
			btn.Parent = SorterUi

			btn.MouseButton1Up:Connect(function()
				window.sortNewDecals = false
			end)
			for i = 1, #optionsTab.SortableProperties do
				local btn = Instance.new("TextButton")
				btn.BorderSizePixel = 0
				btn.Transparency = 0.4
				btn.BackgroundColor3 = Color3.new(0.95, 0.9, 0.9)
				btn.Size = UDim2.new(1, 0, 1, 0)
				btn.Position = UDim2.new(0, 0, i+1, 0)
				btn.Text = "By "..optionsTab.SortableProperties[i]
				btn.TextScaled = true
				btn.ZIndex = 5
				btn.Visible = false
				buttons[#buttons + 1] = btn
				btn.Parent = SorterUi

				btn.MouseButton1Up:Connect(function()
					window.sortedProperty = string.sub(btn.Text, 4, string.len(btn.Text))
					window.arrangeDecals()
				end)
			end
			sortDirectionBtn.Position = UDim2.new(0, 0, #buttons+1, 0)
			sortDirectionBtn.Size = UDim2.new(1, 0, 0.8, 0)
			buttons[#buttons + 1] = sortDirectionBtn
		else
			
			local btn = Instance.new("TextButton")
			btn.BorderSizePixel = 0
			btn.Transparency = 0.4
			btn.BackgroundColor3 = Color3.new(0.95, 0.9, 0.9)
			btn.Size = UDim2.new(1, 0, 1, 0)
			btn.Position = UDim2.new(0, 0, 1, 0)
			btn.Text = "Stop Sorting"
			btn.TextScaled = true
			btn.ZIndex = 5
			btn.Visible = false
			buttons[1] = btn
			btn.Parent = SorterUi
			
			buttons[2] = sortDirectionBtn
		end

		sortDirectionBtn.MouseButton1Up:Connect(function()
			local newState = not sortDirectionBtn:GetAttribute("flipOrder")
			sortDirectionBtn:SetAttribute("flipOrder", newState)
			window.flipSortOrder, window.sortNewDecals = newState, not newState
			
			window.arrangeDecals()
			sortDirectionBtn.Text = "Flip Ui Order (Current: "..(newState == true and "Ascending)") or "Decending)"
		end)
		sortDirectionBtn.Visible = false
		sortDirectionBtn.Parent = SorterUi
		
		local isHovering = false
		SorterUi.InputBegan:Connect(function(inputObj)
			if isHovering or inputObj.UserInputType ~= Enum.UserInputType.MouseMovement then return end
			isHovering = true
			for i = 1, #buttons do
				buttons[i].Visible = true
			end
			task.wait(0.2)
			
			local mouse = game.Players.LocalPlayer:GetMouse()
			local absPos1 = SorterUi.AbsolutePosition
			local absPos2 = Vector2.new(buttons[#buttons].AbsoluteSize.X + buttons[#buttons].AbsolutePosition.X, buttons[#buttons].AbsolutePosition.Y + buttons[#buttons].AbsoluteSize.Y)
			--abspos1 is upper left corner, abspos2 is bottom right corner
		
			repeat
				task.wait(0.15)
			until ((mouse.X > absPos1.X and mouse.X < absPos2.X) and (mouse.Y < absPos2.Y and mouse.Y > absPos1.Y)) == false--bruh why does roblox flix Y axis for guis
			absPos1, absPos2, mouse = nil
			
			for i = 1, #buttons do
				buttons[i].Visible = false
			end
			isHovering = false
		end)
	end
	window.Visible, window.uiList, window.sortNewDecals, window.sortedProperty, window.flipSortOrder, window.callback1, window.callback2 = Gui.Enabled, uiList, optionsTab.SortNewDecals or false, optionsTab.SortedProperty or nil, optionsTab.FlipSortOrder or optionsTab.FlipOrder or false, optionsTab.Callback1, optionsTab.Callback2
	optionsTab = nil
	
	return window
end


return decalViewer
