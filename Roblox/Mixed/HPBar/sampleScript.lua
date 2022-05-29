

local HPBarMod = require(game.ReplicatedStorage.HPBarModule)

local posTab = {
	['refreshOnRespawn'] = true,
	['bypassUiFormat'] = false
}
for i = 1, 5 do
HPBarMod.newBar(game.Players.LocalPlayer, posTab)
end
posTab['bypassUiFormat'] = true
local barTab = HPBarMod.newBar(game.Players.LocalPlayer, posTab)
local bar = barTab[1]
bar.AnchorPoint = Vector2.new(1, 0)
bar.Position = UDim2.new(0.9, 0, 0, 0)
