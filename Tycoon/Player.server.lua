local DataService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local data = DataService:GetDataStore("Player DataT4")

local Tycoon = require(script.Parent:FindFirstChild("Tycoon Module"))
local playerData = require(script.Parent:FindFirstChild("Player Data"))

local tycoons = game.Workspace:WaitForChild("Tycoons")

local templateTycon = game.ReplicatedStorage:WaitForChild("Tycoon")

local function getPlayerTycoon(player)
	for _, tycoon in tycoons:GetChildren() do
		if tycoon:GetAttribute("PlayerID") and tycoon:GetAttribute("PlayerID") == player.UserId then 
			return tycoon
		end
	end
end

local playerTable = playerData.playerTable

local joinFunctions = {
	[true] = function(player, result)
		local newData = playerData.new(player)
		playerTable[player.UserId] = newData
	end,
	
	[false] = function(player, result)
		local newData = playerData.new(player, HttpService:JSONDecode(result))
		playerTable[player.UserId] = newData
	end,
}

local function playerAdded(player)
	local playerId = player.UserId
	
	local success, result = pcall(function()
		return data:GetAsync(playerId)
	end)
	
	if not success then
		warn("Player data was not loaded!")
	end
	
	joinFunctions[result == nil or result == "null"](player, result)
	
	local newTycoon = Tycoon.GetTycoon(tycoons)
	local tycoon = Tycoon.new(newTycoon)
	tycoon:Assign(player)
end

function Save(playerId, newData)
	local success, errorMessage = pcall(function()
		local jsonStructure = HttpService:JSONEncode(newData)
		data:SetAsync(playerId, jsonStructure)
	end)
end

local function playerRemoving(player)
	local playerId = player.UserId
	
	Save(playerId, playerTable[playerId])
end

Players.PlayerAdded:Connect(playerAdded)
Players.PlayerRemoving:Connect(playerRemoving)

function loopData(data)
	for playerId, Data in data do
		Save(playerId, Data)
	end
end

game:BindToClose(function()
	warn("Server shutdown!")
	loopData(playerTable)
end)