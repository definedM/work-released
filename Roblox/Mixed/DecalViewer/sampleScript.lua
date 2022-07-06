
local gui = decalViewer.newUi({
	DecalSize = 0.1,
	FlipOrder = false, --Descending
	SortNewDecals = true,
	SortableProperties = {
		"Index",
		"RandomNum"
	},
	RawList = { --just save and load this from a file, dw about typing this manually
		{
			["Index"] = 1404,
			["InsertTime"] = 0,
			["RandomNum"] = 18,
			["decalGuiProperties"] = {
				["BackgroundColor3"] = Color3.new(1,0,1),
				["Image"] = "rbxassetid://166285971" --understand that u might need to decrement the decal id a few times to get the asset id... (roblox moment)
			}
		}
	},
    --below this is where the stuf is moastly at
	Callback1 = function(properties, x, y)
		print(properties)
	end,
	Callback2 = function(properties, x, y)
		print(properties)
	end,
})


if not game:IsLoaded() then game.Loaded:Wait() end

gui.newDecal({
		["Index"] = math.huge,
		["RandomNum"] = -math.huge
	}, {
	BackgroundColor3 = Color3.new(0, 0, 0)
})

for i = 1, 1003 do
	if i%150 == 0 then task.wait() end
	local decalTab = gui.newDecal({
		["Index"] = i,
		["RandomNum"] = math.random(0, 100)
	}, {
		Image = (math.random() > 0.6 and "rbxassetid://26646734") or "rbxassetid://26346734", --i picked random asset ids (some dday thing and a ucr thing)
		BackgroundColor3 = Color3.new(math.random(), math.random(), math.random())
	})
	--print(gui.uiList[decalTab.getListIndex()].decalGui.Position.Y)
end

print(gui.getRawList())
