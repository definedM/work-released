
local LP = game.Players.LocalPlayer
local objMapper = {}

local function InitPos(pos1, pos2)
	pos1 = pos1 or Vector2.new(0, 0)
	pos2 = pos2 or Vector2.new(200, 200)

	local finalVec = {1, 1}
	
	if pos1.Magnitude > pos2.Magnitude then
		local posHold = pos2
		pos2 = pos1
		pos1 = posHold
	end --worldpos1 is the lesser vector

	return pos1, pos2
end

function objMapper:CreatePropertyEvent(Property, Callback)
	return {[Property] = Callback}
end

function objMapper:New(title:string, worldPos1:Vector2, worldPos2:Vector2, flipXAxis:boolean, flipYAxis:boolean) --worldPos needs to be a world Vector3 converted to Vector2
	if flipXAxis == nil then flipXAxis = false end
	if flipYAxis == nil then flipYAxis = false end
	worldPos1, worldPos2 = InitPos(worldPos1, worldPos2, flipXAxis, flipYAxis)
	
	--[[
	worldPos1 = worldPos1 or Vector2.new(0, 0)
	worldPos2 = worldPos2 or Vector2.new(200, 200)
	
	if worldPos1.Magnitude > worldPos2.Magnitude then
		local posHold = worldPos2
		worldPos2 = worldPos1
		worldPos1 = posHold
	end --worldpos1 is the lesser vector

	if flipYAxis then worldPos1, worldPos2 = Vector2.new(worldPos1.X, -worldPos1.Y), Vector2.new(worldPos2.X, -worldPos2.Y) end
	]]
	local sGui = Instance.new("ScreenGui")
	local frame = Instance.new("Frame")
	local txtLabel = Instance.new("TextLabel")
	
	frame.Name = '1'
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(140, 140, 140)
	frame.BorderSizePixel = 0
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.Size = UDim2.new(0.8, 0, 0.73, 0)

	txtLabel.AnchorPoint = Vector2.new(0.5, 0)
	txtLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	txtLabel.BorderSizePixel = 0
	txtLabel.Position = UDim2.new(0.5, 0, 0, 0)
	txtLabel.Size = UDim2.new(0.65, 0, 0.09, 0)
	txtLabel.Font = Enum.Font.SourceSans
	txtLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
	txtLabel.TextScaled = true
	txtLabel.TextSize = 14
	txtLabel.TextWrapped = true

	txtLabel.Text = title or "Sample Text"
	
	txtLabel.Parent = frame
	frame.Parent = sGui
	local s, e = pcall(function() sGui.Parent = game:WaitForChild("CoreGui", 1) end)
	if e then
		sGui.Parent = LP:WaitForChild("PlayerGui")
	end
	
	local Modify = {}
	local UIContainer = {}
	
	local function scaleTo1(A, B, C, flip) --A is input, B is low num, and C is high num
		
		local One = math.abs((A-B) / (C-B))
		if typeof(flip) == "boolean" and flip == true then One = 1-One end
		return One
	end
	
	function Modify:getParentUI()
		return frame
	end
	
	function Modify:updateWorldPos(newPos1:Vector2, newPos2:Vector2, newflipXAxis:boolean, newflipYAxis:boolean)
		if newflipXAxis == nil then newflipXAxis = flipXAxis end
		if newflipYAxis == nil then newflipYAxis = flipYAxis end
		worldPos1, worldPos2 = InitPos(worldPos1)
		
		for UI, events in pairs(UIContainer) do
			if events['Position'] then events['Position']['Callback']() end
			if events['Size'] then events['Size']['Callback']() end
			if events['Orientation'] then events['Orientation']['Callback']() end
		end
	end
	
	function Modify:newObjUI(class:string, object:Part, addEvents:table) --addEvents can be used to replace unwanted events
		local UI = Instance.new(class)
		UI.AnchorPoint = Vector2.new(0.5, 0.5)
		UI.BorderSizePixel = 0
		
		local events = {}
		
		events['Name']['Callback'] = function()
			UI.Text = object.Name
		end
		events['Position']['Callback'] = function()
			local objPos = object.Position
			UI.Position = UDim2.new(scaleTo1(objPos.X, worldPos1.X, worldPos2.X, flipXAxis), 0,
				scaleTo1(objPos.Z, worldPos1.Y, worldPos2.Y, flipYAxis), 0)
			UI.ZIndex = objPos.Y
		end
		events['Size']['Callback'] = function()
			UI.Size = UDim2.new(scaleTo1(object.Size.X, worldPos1.X, worldPos2.X), 0, 
				scaleTo1(object.Size.Z, worldPos1.X, worldPos2.X), 0)
		end
		events['Orientation']['Callback'] = function()
			UI.Rotation = object.Orientation.X
		end
		events['Color']['Callback'] = function()
			UI.BackgroundColor3 = Color3.new(object.Color)
		end
		
		events['Name']['PropertyEvent'] = object:GetPropertyChangedSignal("Name"):Connect(events['Name']['Callback'])
		events['Position']['PropertyEvent'] = object:GetPropertyChangedSignal("Position"):Connect(events['Position']['Callback'])
		events['Size']['PropertyEvent'] = object:GetPropertyChangedSignal("Size"):Connect(events['Size']['Callback'])
		events['Orientation']['PropertyEvent']= object:GetPropertyChangedSignal("Orientation"):Connect(events['Orientation']['Callback'])
		events['Color']['PropertyEvent'] = object:GetPropertyChangedSignal("Color"):Connect(events['Color']['Callback'])
		object.Destroying:Connect(function()
			for property, event in pairs(events) do
				events[property]['PropertyEvent']:Disconnect()
				events[property]['Callback'] = nil
			end
		end)
		
		if addEvents then
			for property, callback in pairs(addEvents) do
				if events[property] then events[property]['PropertyEvent']:Disconnect() end
				if callback and typeof(callback) == "function" then 
					events[property]['Callback'] = callback
					events[property]['PropertyEvent'] = object:GetPropertyChangedSignal(property):Connect(callback)
				else
					events[property] = nil
				end
			end
		end
		
		for property in pairs(events) do --load UI with the properties
			property['Callback']()
		end
		
		UIContainer[#UIContainer + 1] = {UI, events}
		return UI
	end
	function Modify:newPosUI(class:string, newWorldPos:Vector2, newWorldSize:Vector2) --its objUI but with no events and uses Position for performance
		newWorldSize = newWorldSize or Vector2.new(0.065*worldPos2.X, 0.065*worldPos2.Y)
		local UI = Instance.new(class)
		UI.AnchorPoint = Vector2.new(0.5, 0.5)
		UI.BorderSizePixel = 0
		
		UI.Position = UDim2.new(scaleTo1(newWorldPos.X, worldPos1.X, worldPos2.X, flipXAxis),
			0, scaleTo1(newWorldPos.Y, worldPos1.Y, worldPos2.Y, flipYAxis), 0)
		
		UI.Size = UDim2.new(scaleTo1(newWorldSize.X, worldPos1.X, worldPos2.X),
			0, scaleTo1(newWorldSize.Y, worldPos1.Y, worldPos2.Y), 0)
		return UI
	end
	
	return Modify
end


return objMapper
