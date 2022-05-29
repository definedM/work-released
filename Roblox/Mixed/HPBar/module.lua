local Plrs = game:GetService("Players")
local TServ = game:GetService("TweenService")
local LP = game.Players.LocalPlayer
local refreshUis = Instance.new("BindableEvent")

local mainUi = Instance.new("ScreenGui")
local mainFrame = Instance.new("Frame")

local defaultInfo_HP = TweenInfo.new(0.8, Enum.EasingStyle.Circular)
local defaultInfo_Ui = TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

local basePos = UDim2.new(0.01, 0, 0.55, 0)
local padding = UDim2.new(0, 0, 0.02, 0)
local frame_YLength
local suffixes = {nil, "M", "B", "T", "Qd", "Qn"}

do --precreate mainUI for quicker(?) cloning
	mainUi.Name = "HPBar"
	mainUi.ResetOnSpawn = true

	local nameHolder = Instance.new("TextLabel")
	local notifyChange = Instance.new("TextLabel")
	local noHealth = Instance.new("TextLabel")
	local healthBar = Instance.new("TextLabel")
	local healthOverlay = Instance.new("TextLabel")
	local xButton = Instance.new("TextButton")

	mainFrame.BackgroundColor3 = Color3.new(0.24, 0.24, 0.24)
	mainFrame.BorderSizePixel = 0
	mainFrame.Position = UDim2.new(0.021, 0, 0.58, 0)
	mainFrame.Size = UDim2.new(0.21, 0, 0.04, 0)
	mainFrame.Visible = true

	nameHolder.Name = "nameHolder"
	nameHolder.AnchorPoint = Vector2.new(0, 1)
	nameHolder.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
	nameHolder.BorderColor3 = Color3.fromRGB(89, 89, 89)
	nameHolder.BorderMode = Enum.BorderMode.Inset
	nameHolder.BorderSizePixel = 3
	nameHolder.Size = UDim2.new(0.8, 0, 0.7, 0)
	nameHolder.ZIndex = 5
	nameHolder.Text = "Player: nil"
	nameHolder.TextColor3 = Color3.fromRGB(206, 206, 206)
	nameHolder.TextScaled = true
	
	notifyChange.Name = "notifyChange"
	notifyChange.BackgroundColor3 = Color3.new(0, 0, 0)
	notifyChange.BackgroundTransparency = 1
	notifyChange.BorderSizePixel = 0
	notifyChange.Position = UDim2.new(1.026, 0, 0, 0)
	notifyChange.Size = UDim2.new(0.158, 0, 1, 0)
	notifyChange.ZIndex = 3
	notifyChange.RichText = true
	notifyChange.Text = "<b>+0 (0%)</b>"
	notifyChange.TextColor3 = Color3.new(0.56, 0, 0) --for when hp is going down (red)
	notifyChange.TextScaled = true
	notifyChange.TextStrokeColor3 = Color3.fromRGB(250, 250, 250)
	notifyChange.TextStrokeTransparency = 0
	notifyChange.Visible = false

	noHealth.Name = "noHealth"
	noHealth.BackgroundColor3 = Color3.fromRGB(143, 52, 52)
	noHealth.BorderSizePixel = 0
	noHealth.Size = UDim2.new(1, 0, 1, 0)
	noHealth.ZIndex = 4
	noHealth.Text = ""

	healthBar.Name = "healthBar"
	healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	healthBar.BorderSizePixel = 0
	healthBar.ZIndex = 5
	healthBar.Size = UDim2.new(1, 0, 1, 0)
	healthBar.Text = ""

	local uiGrad = Instance.new("UIGradient")
	uiGrad.Name = "uiGrad"
	uiGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.new(0, 0.603922, 0)), ColorSequenceKeypoint.new(1, Color3.new(0, 1, 0))}
	uiGrad.Rotation = 270
	uiGrad.Parent = healthBar
		
	healthOverlay.Name = "healthOverlay"
	healthOverlay.BackgroundTransparency = 1
	healthOverlay.BorderSizePixel = 0
	healthOverlay.Size = UDim2.new(1, 0, 1, 0)
	healthOverlay.RichText = true
	healthOverlay.ZIndex = 6
	healthOverlay.Font = Enum.Font.TitilliumWeb
	healthOverlay.Text = "<b>Health: 0/0</b>"
	healthOverlay.TextColor3 = Color3.fromRGB(245, 245, 245)
	healthOverlay.TextScaled = true

	xButton.Name = "xButton"
	xButton.AnchorPoint = Vector2.new(0, 1)
	xButton.BackgroundColor3 = Color3.new(1, 1, 1)
	xButton.BorderColor3 = Color3.fromRGB(255, 0, 0)
	xButton.BorderMode = Enum.BorderMode.Inset
	xButton.BorderSizePixel = 3
	xButton.Position = UDim2.new(nameHolder.Size.X.Scale, 0, 0, 0)
	xButton.Size = UDim2.new(0.09, 0,nameHolder.Size.Y.Scale, 0)
	xButton.ZIndex = 5
	xButton.Text = "X"
	xButton.TextColor3 = Color3.fromRGB(207, 0, 0)
	xButton.TextScaled = true

	nameHolder.Parent = mainFrame
	notifyChange.Parent = mainFrame
	noHealth.Parent = mainFrame
	healthBar.Parent = mainFrame
	healthOverlay.Parent = mainFrame
	xButton.Parent = mainFrame

	mainFrame.Parent = nil
	frame_YLength = mainFrame.nameHolder.Size.Y.Scale*mainFrame.Size.Y.Scale + mainFrame.Size.Y.Scale + padding.Y.Scale
end

local function suffixNum(Number)
    local dps = tostring(math.floor(Number+0.5))
    if dps:len() > 6 then
		
        local viewNums = dps:len()%3
        if viewNums == 0 then viewNums = 3 end
        local places = math.floor((dps:len()-1)/3)
        local suffix = suffixes[places]

        dps = dps:sub(1, viewNums)..'.'..dps:sub(viewNums+1, viewNums+1)..suffix
    end

	return dps
end

local function getHP(humanoid:Humanoid)
	if not humanoid then return nil end
	local percent = math.floor((humanoid.Health/humanoid.MaxHealth) * 100)
	local hp, hpMax = humanoid.Health, humanoid.MaxHealth
	hp = suffixNum(hp) hpMax = suffixNum(hpMax)
	return tostring(hp).." / "..tostring(hpMax).." ("..tostring(percent).."%)", percent
end

local function getNonBypassedBars()
	local insts = 0
	for i, v in pairs(mainUi:GetChildren()) do
		if not v:IsA("Frame") or v:FindFirstChild("bypassUi") then continue end
		insts += 1
	end
	return insts
end

local HPBarModule = {}

function HPBarModule.setDefautlTweenInfoUi(givenInfo:TweenInfo)
	defaultInfo_Ui = givenInfo
end

function HPBarModule.setDefaultTweenInfoHP(givenInfo:TweenInfo)
	defaultInfo_HP = givenInfo
end

function HPBarModule.setPaddingInfo(givenInfo:UDim2)
	padding = givenInfo
	frame_YLength = mainFrame.nameHolder.Size.Y.Scale*mainFrame.Size.Y.Scale + mainFrame.Size.Y.Scale + padding.Y.Scale
	refreshUis:Fire()
end

function HPBarModule.setBasePos(givenInfo:UDim2)
	basePos = givenInfo
	frame_YLength = mainFrame.nameHolder.Size.Y.Scale*mainFrame.Size.Y.Scale + mainFrame.Size.Y.Scale + padding.Y.Scale
	refreshUis:Fire()
end

function HPBarModule.removeBar(barTab)
	local frame, event = barTab[1], barTab[2]
	if event then event[2]:Disconnect() end
	frame.nameHolder.Text = "Removing..."
	local frameOrder = frame:GetAttribute("frameOrder")
	local goal = {Position = UDim2.new(-0.5, 0, frame.Position.Y.Scale, 0)}
	local tween = TServ:Create(frame, defaultInfo_Ui, goal)
	tween:Play()

	tween.Completed:Wait()
	frame.Parent = nil
	frame:Destroy()
	barTab = nil
	refreshUis:Fire(frameOrder)
end

function HPBarModule.newBar(charModel:Model, posTab:table) -- padding is a number 1 to 1000 (scales a whole screen's length at 1000)
	posTab = posTab or {}
	local refreshOnRespawn, bypassUi = posTab['refreshOnRespawn'] or true, posTab['bypassUiFormat'] or false --refreshOnRespawn requires a player model
	if not charModel then warn("charModel needs an input") return end
	local player, playerName = Plrs:GetPlayerFromCharacter(charModel), nil
	if player and player:IsA("Player") or charModel:IsA("Player") then
		if charModel:IsA("Player") then
			player = charModel
			charModel = player.Character
		end

		while not charModel do
			player.CharacterAdded:Wait()
			task.wait()
			charModel = player.Character
		end
		playerName = '[Player]: '..player.Name
	end

	local human = charModel:FindFirstChildOfClass("Humanoid")
	if not human then warn("charModel contains no humanoid") end
	
	local frame = mainFrame:Clone()
	local refreshEvent, refreshFunc = nil

	frame:SetAttribute("frameOrder", getNonBypassedBars())
	if not bypassUi then
		refreshFunc = function(startPos:UDim2, destroyingFrameOrder)
			if not startPos or typeof(startPos) ~= 'UDim2' then startPos = frame.Position end
			local currFrameOrder = frame:GetAttribute("frameOrder")
			if destroyingFrameOrder  and destroyingFrameOrder <= currFrameOrder then
				currFrameOrder = currFrameOrder - 1
				frame:SetAttribute("frameOrder", currFrameOrder)
			end
			--[[
			local borderPixels = 0
			local function addBorderPixels(ui)
				if ui.BorderMode == Enum.BorderMode.Outline then
					borderPixels += ui.BorderSizePixel
				elseif ui.BorderMode == Enum.BorderMode.Middle then
					borderPixels += ui.BorderSizePixel*0.5
				else
					return
				end
			end
			addBorderPixels(frame, frame.nameHolder) addBorderPixels = nil
			]]
			local UI_YEnd = frame_YLength*currFrameOrder + (basePos.Y.Scale)
			frame.Position = startPos

			local goalTab = {Position = UDim2.new(basePos.X.Scale, 0, UI_YEnd, 0)}
			local tween = TServ:Create(frame, defaultInfo_Ui, goalTab)
			tween:Play()
		end

		local refreshEvent = refreshUis.Event:Connect(function(destroyingFrameOrder)
			refreshFunc(nil, destroyingFrameOrder)
		end)
		refreshFunc(basePos)
	else
		local bv =Instance.new("BoolValue", frame)
		bv.Name = 'bypassUi'
	end

	local barTab = {
		frame, refreshEvent or nil
	}
	
	local healthOld = human.Health
	local percentOld = human.Health/human.MaxHealth*100
	local function updateHP()
		if not frame or not frame:FindFirstChild("healthBar") or not frame:FindFirstChild("notifyChange") then return end
		local health, percent = getHP(human)
		local goal = {Size = UDim2.new(percent/100, 0, frame.healthBar.Size.Y.Scale, 0)}
		local tween = TServ:Create(frame.healthBar, defaultInfo_HP, goal)
		
		local notifChange = frame.notifyChange:Clone()
		notifChange.Parent = frame
		notifChange.Visible = true
		local goal2 = {['Position'] = UDim2.new(notifChange.Position.X.Scale, 0, notifChange.Position.Y.Scale + 0.65, 0)}
		coroutine.wrap(function()
			if not frame or not frame:FindFirstChild("noHealth") then return end
			local noHealth = frame.noHealth
			task.wait(1)
			local percent = human.Health/human.MaxHealth
			goal = {Size = UDim2.new(percent, 0, noHealth.Size.Y.Scale, 0)}
			local noHPTween = TServ:Create(noHealth, defaultInfo_HP, goal)
			noHPTween:Play()
		end)()

		local percent2 = (human.Health/human.MaxHealth)*100
		local healthDiff = math.floor(human.Health - healthOld + 0.5)
		local percentDiff = math.floor((percent2-percentOld)*100)/100
		if healthDiff >= 0 then
			goal2 = {['Position'] = UDim2.new(goal2['Position'].X.Scale, 0, -goal2['Position'].Y.Scale, 0)}
			if percentDiff == 0 or healthDiff == 0 then 
				notifChange.TextColor3 = Color3.new(0.6, 0.6, 0.6)
				percentDiff, healthDiff = 0, 0
			else
				notifChange.TextColor3 = Color3.new(0, 0.51, 0)
			end
		end

		healthOld, percentOld = human.Health, percent2
		local notifyTween = TServ:Create(notifChange, defaultInfo_HP, goal2)
		notifyTween:Play()

		tween:Play()
		notifChange.Text = '<b>'..healthDiff.."\n".."("..percentDiff.."%)"..'</b>'

		frame.healthOverlay.Text = "<b>"..health.."</b>"

		notifyTween.Completed:Connect(function()
			notifChange:Destroy()
		end)
	end
	human:GetPropertyChangedSignal("Health"):Connect(updateHP)
	human:GetPropertyChangedSignal("MaxHealth"):Connect(updateHP)
	updateHP()

	local function DeathFunc()
		print('destroyed')
		if not player then HPBarModule.removeBar(barTab) return end
		frame.healthOverlay.Text = "Waiting on respawn..."
		local newHuman
		repeat
			player.CharacterAdded:Wait()
			newHuman = player.Character:FindFirstChildOfClass("Humanoid")
		until newHuman
		updateHP()
		if refreshFunc then refreshFunc() end
	end
	human.Died:Connect(DeathFunc)
	human.Destroying:Connect(DeathFunc)
	
	frame.xButton.MouseButton1Up:Connect(function()
		HPBarModule.removeBar(barTab)
	end)

	frame.nameHolder.Text = playerName or "[NonPlayer]: "..charModel.Name
	frame.Name = charModel.Name
	frame.Parent = mainUi
	frame.Visible = true
	return barTab
end

	
local s, e = pcall(function()
	mainUi.Parent = game:WaitForChild("CoreGui", 2)
end)
if e then mainUi.Parent = LP:WaitForChild("PlayerGui") end
return HPBarModule
