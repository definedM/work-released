-- internal variables
local baselineAPI
local executor_FullName = identifyexecutor and identifyexecutor() --Scriptware is one of them
local executor = (Krnl and "Krnl") or (syn and "Synapse") or executor_FullName or "Unknown"

local date = os.date
local rand, abs, floor, sqrt = math.random, math.abs, math.floor, math.sqrt
local easeLinear = Enum.EasingStyle.Linear
local killConnections = function(connections)
    local connection
    for i = 1, #connections do
        connection = connections[i]
        _ = connection and connection:Disconnect()
    end
end

local LPEvents = {
    ["charDied"] = {['length'] = 0},
    ["charDel"] = {['length'] = 0},
    ["charAdd"] = {['length'] = 0}
}
local suffixes = {"k", "M", "B", "T", "Qd", "Qn", "Sx", "Sp", "O", "N", "D", "U", "DD"}
local charTable = ('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890!@#$%^&*()'):split('')

-- wait for game to load (this api can ensure that your game loads before your script starts)
if not game.Loaded then game.Loaded:Wait() end

-- in-game variables
local tweenServ = game:GetService("TweenService")
local pathfindServ = game:GetService("PathfindingService")
local starterGui = game.StarterGui

local LP = game:GetService("Players").LocalPlayer

-- player events
local CharAdded = LP.CharacterAdded
local HRootAdded = Instance.new("BindableEvent")
local HumanoidAdded = Instance.new("BindableEvent")

-- player variables
local LPName = LP.Name
local Char = LP.Character or CharAdded:Wait()
local HRoot = Char:WaitForChild("HumanoidRootPart", 10)
local Humanoid = Char:WaitForChild("Humanoid", 10)


coroutine.wrap(function() -- refresh variables and call connections when player respawns
    local cleanGarbage = nil
        local function onCharacterAdd(newChar)
        _ = cleanGarbage and cleanGarbage()
        Char = newChar
        local charChildEvent, hrootDeleteEvent, diedEvent, HRootFoundFunc, HumanoidFoundFunc

        -- disconnects connections and wipes unnecessary variables (should only be called on death)
        cleanGarbage = function()
            coroutine.wrap(function()
                for i, callback in pairs(LPEvents.charDel) do
                    if not tonumber(i) then continue end
                    coroutine.wrap(callback)()
                end
            end)()
            killConnections({charChildEvent, hrootDeleteEvent, diedEvent})
            charChildEvent, hrootDeleteEvent, diedEvent = nil

            HRootFoundFunc, HumanoidFoundFunc, Char, HRoot, Humanoid, cleanGarbage = nil
        end

        -- update variables and call cleanGarbage when dead
        HRootFoundFunc = function(instance)
            HRoot = instance
            HRootAdded:Fire(HRoot)
            hrootDeleteEvent = HRoot.Destroying:Connect(cleanGarbage)
            if Humanoid then charChildEvent:Disconnect() end
        end
        HumanoidFoundFunc = function(instance)
            Humanoid = instance
            HumanoidAdded:Fire(Humanoid)
            diedEvent = Humanoid.Died:Connect(function()
                for i, callback in pairs(LPEvents.charDied) do
                    if not tonumber(i) then continue end
                    coroutine.wrap(function() callback() end)()
                end
            end)
            if HRoot then charChildEvent:Disconnect() end
        end

        -- new instances added to this triggers their corresponding functions
        charChildEvent = Char.ChildAdded:Connect(function(instance) 
            if instance.Name == "HumanoidRootPart" then 
                HRootFoundFunc(instance)

            elseif instance:IsA("Humanoid") then 
                HumanoidFoundFunc(instance)

            end
        end)

        do -- check if they existed before the charChildEvent was connected
            local rootCheck, humanCheck = Char:FindFirstChild("HumanoidRootPart"), Char:FindFirstChildOfClass("Humanoid")
            if rootCheck then HRootFoundFunc(rootCheck) end
            if humanCheck then HumanoidFoundFunc(humanCheck) end
        end
        for i, callback in pairs(LPEvents.charAdd) do
            if not tonumber(i) then continue end
            coroutine.wrap(function()
                print(callback)
                callback(Char)
            end)()
        end
    end
    _ = Char and onCharacterAdd(Char)
    LP.CharacterAdded:Connect(onCharacterAdd)
end)()

local executorExclusive = {} --for functions special to a certain executor so u can just do executorExclusive.request() (no need to cal syn aadn syn.getreertqst or krnl or som long shid!)

baselineAPI = {
    ['ver'] = 1.1,

    -- local player stuff
    ['LocalPlayer'] = LP,
    ['nickname'] = LPName, -- i guess preloading strings can help a bit
    ['character'] = function(dontYield)
        return Char or (not dontYield and CharAdded:Wait()) or nil
    end,
    ['humanoidrootpart'] = function(dontYield)
        return HRoot or (not dontYield and HRootAdded.Event:Wait()) or nil
    end,
    ['humanoid'] = function(dontYield) 
        return Humanoid or (not dontYield and HumanoidAdded.Event:Wait()) or nil
    end,
    ["onCharacterEvent"] = function(eventType, callback) --charDied is only fired when your humanoid dies, which wont happen if your humanoid is deleted
        eventType = LPEvents[eventType]
        if not eventType then 
            warn(eventType, "is not a valid argument. Valid arguments are:")
            table.foreach(LPEvents, warn)
        end
        local index
        for i = 1, eventType.length+1 do
            if eventType[i] then continue end
            index = i
        end        
        eventType.length += 1 -- increment custom length (caus canot get # of elements in dictionaries :<)
        eventType[index] = callback -- claims a spot in the table
        
        local connection = {} -- uhm very limited version of rbxscriptsignal
        function connection:Disconnect()
            eventType[index] = nil -- deletes the event from the table
        end
        return connection
    end,
    
    --executor identification
    ['isSynapse'] = function()
        return executor == "Synapse"
    end,
    ['isKrnl'] = function()
        return executor == "Krnl"
    end,
    ['executor'] = executor,
    --[[
        Acknowledged executors (possible returns for baselineAPI.executor):
        Synapse, Krnl, ScriptWare, Unknown
    ]]
    
    -- string manipulation
    ['getDate'] = function() return date("%x") end, -- return <string>
    ['getTime'] = function() return date("%X") end, -- return <string>
    ['getDateTime'] = function() return date("%c") end, -- return <string>
    ['formatHMS'] = function(seconds) -- seconds <int>
        local mins = (seconds - seconds%60)/60
        seconds = seconds - mins*60

        local hrs = (mins - mins%60)/60
        mins = mins - hrs*60

        return string.format("%02i", hrs)..":"..string.format("%02i", mins)..":"..string.format("%02i", seconds)
    end, -- return <string>: string in HH:MM:SS format
    ['uhmmidkwatnameilldolater'] = function()
        local date = os.date("!*t")
        local hour = (date.hour - 5) % 24
        local ampm = hour < 12 and "AM" or "PM"
        local timestamp = string.format("%02i:%02i %s", ((hour - 1) % 12) + 1, date.min, ampm)
        return timestamp
    end,
    ['generaterandomstring'] = function(desiredLength)
        local string = '' 
        for i = 1, desiredLength or rand(10, 30) do 
            string = string..charTable[rand(1, #charTable)]
        end 
        return string 
    end,
    ['suffixNum'] = function(num, decPlaces) -- num <float>: number to suffixify; decPlaces <integer>: # of decimal places to round (no negatives)
        decPlaces = decPlaces or 0 
        num = floor(num) -- round number
        local absNum = abs(num)
        if absNum < 1000 then return tostring(num) end -- no suffix
        
        local absNumLen = tostring(absNum):len()
        absNum = tostring(floor(
            num + 5*10^( absNumLen - decPlaces-2 )
        ))--round number to the visible decimal places

        local visibleNums = absNumLen%3 -- the amount of decimal places visible
        visibleNums = (visibleNums == 0 and 3) or visibleNums
        
        absNum = absNum:sub(1, visibleNums).. -- get the whole numbers when suffixed
            ((decPlaces ~= 0) and '.'..absNum:sub(visibleNums+1, visibleNums+decPlaces) or "").. -- if there are decimal places to round, then round
            suffixes[ floor( (absNumLen-1)/3 ) ] -- get suffix wth the length of the number
        return (num < 0 and "-" or "")..absNum -- format the string with the appropriate extreme (pos/neg)
    end, -- return <string>: the suffixed number rounded up
    --[[
    local function suffixNum(num, decPlaces) 
        
    end

    ]]

    -- object stuff
    ['nearestPartToPart'] = function(path, part)
        local Closest
        for i,v in next, path:GetChildren() do
            if v:IsA("MeshPart") or v:IsA("Part") then
                if Closest == nil then
                    Closest = v
                else
                    if (part.Position - v.Position).magnitude < (Closest.Position - part.Position).magnitude then
                        Closest = v
                    end
                end
            end
        end
        return Closest
    end,
    ['partwithnamepart'] = function(name, path)
        for i,v in next, path:GetChildren() do
            if (v.Name:match(name)) then
                return v
            end
        end
    end,
    ['getbiggestmodel'] = function(path)
        local part
        for i,v in next, path:GetChildren() do
            if v:IsA("Model") then
                if part == nil then
                    part = v
                end
                if v:GetExtentsSize().Y > part:GetExtentsSize().Y then
                    part = v
                end
            end
        end
        return part
    end,

    -- umm internet stuf
    ['request'] = syn and syn.request or http and http.request or http_request or httprequest or request,
    ['getsitebody'] = function(link)
        local Response = syn.request({Url = link, Method = "GET"})
        return Response.Body
    end,
    ['webhook'] = function(hook, color, title, description) --possible sublibrary for functions that are out of the client
        return pcall(function()
            local OSTime = os.time();
            local Time = date('!*t', OSTime);
            local Embed = {
                color = color;
                title =  title;
                description = description;
            };
    
            (syn and syn.request or http_request) {
                Url = hook;
                Method = 'POST';
                Headers = {
                    ['Content-Type'] = 'application/json';
                };
                Body = game:GetService'HttpService':JSONEncode( { content = Content; embeds = { Embed } } );
            };
        end)
    end,
    ['imagehook'] = function(hook, description, title, image)
        return pcall(function()
            local OSTime = os.time()
            local Time = date('!*t', OSTime)
            local Embed = {
                color = '3454955',
                title =  title,
                description = description,
                thumbnail = {
                    url = image
                }
            }
    
            (syn and syn.request or http_request) {
                Url = hook,
                Method = 'POST',
                Headers = {
                    ['Content-Type'] = 'application/json',
                },
                Body = game:GetService('HttpService'):JSONEncode( {content = Content, embeds = {Embed}} )
            }
        end)
    end,

    -- file management
    ['getFile'] = function(fileName, dontCreate)
        local success, result = pcall(function() readfile(fileName) end) --errm i may need to account for file paths that uses folders (isfolder, makefolder)
        if success then return result end --return the result as the found file
        return writefile(fileName, "")
    end,

    -- misc
    ['notify'] = function(title, description, duration)
        pcall(function()
            starterGui:SetCore("SendNotification", {
                Title = title,
                Text = description,
                Duration = duration,
            })
        end)
    end,
    ['getUserIcon'] = function(userId)
        return string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%s&width=420&height=420&format=png", userId)
    end,
    ['newThread'] = function(callback)
        return coroutine.wrap(callback)()
    end,
    ['killConnections'] = killConnections,
    ['killRoblox'] = function()
        game:Shutdown()
    end
}

-- player character manipulation
baselineAPI.teleport = function(location) -- location <CFrame(preferred) or Vector3>: place to teleport to
    baselineAPI.humanoidrootpart().CFrame = (typeof(location) == "CFrame" and location) or CFrame.new(location)
end
baselineAPI.tween = function(seconds, location)
    local tween = tweenServ:Create(baselineAPI.humanoidrootpart(), TweenInfo.new(seconds, easeLinear), {CFrame = (typeof(location) == "CFrame" and location) or CFrame.new(location)})
    tween:Play()
    tween.Completed:Wait()
    return tween
end
baselineAPI.tweenNoDelay = function(seconds, location)
    local tween = tweenServ:Create(baselineAPI.humanoidrootpart(), TweenInfo.new(seconds, easeLinear), {CFrame = (typeof(location) == "CFrame" and location) or CFrame.new(location)})
    tween:Play()
    return tween
end
baselineAPI.walkTo = function(vector) -- walk to position (not pathfinding)
    baselineAPI.humanoid():MoveTo(vector) 
end
baselineAPI.pathfind = function(goal)
    local path = pathfindServ:CreatePath({
        AgentCanJump = true,
        WaypointSpacing = 1
    })
    path:ComputeAsync(baselineAPI.humanoidrootpart().Position, goal)
    local waypoints = path:GetWaypoints()
    for _, point in ipairs(waypoints) do
        local Humanoid = baselineAPI.humanoid()
        Humanoid:MoveTo(point.Position)
        Humanoid.MoveToFinished:Wait()

        Humanoid.Jump = (point.Action == Enum.PathWaypointAction.Jump)
    end
end

baselineAPI.cast = function(origin, direction, params, maxLength) -- origin <Vector3>: ray origin; direction <Vector3>: ray direction; params<table>: which; maxLength<number> how long the ray should be shortened to
    if maxLength and direction.Magnitude > maxLength then direction = direction.Unit*maxLength end
    local rayParams = RaycastParams.new(); for rayParam, rayArg in pairs(params) do rayParams[rayParam] = rayArg end
    
    return workspace:Raycast(origin, direction, rayParams)
end --return <Instance?> the part hit during raycast, if any

baselineAPI.getNearestPart = function(instance)
    local HumanoidRootPos = baselineAPI.humanoidrootpart().Position
    
    local nearestPart = instance:FindFirstChildOfClass("Part")
    local nearestDist = (nearestPart.Position - HumanoidRootPos).Magnitude
    for _, child in next, instance:GetChildren() do
        local dist = (nearestPart.Position - HumanoidRootPos).Magnitude
        if (HumanoidRootPos - child.Position).magnitude > dist then continue end

        nearestPart, nearestDist = v, dist
    end
    return nearestPart
end

return baselineAPI
