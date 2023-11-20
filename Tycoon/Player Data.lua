local PlayerData = {}
PlayerData.__index = PlayerData

PlayerData.playerTable = {}

function PlayerData.new(player, self)
	if self then return setmetatable(self, PlayerData) end
	
	local self = setmetatable({}, PlayerData)
	self.Cash = 10000
	self.ItemsBought = {}
	
	return self
end

function PlayerData:GetPlayerData(player)
	return PlayerData.playerTable[player.UserId]
end

function PlayerData:AddCash(cashAdded)
	self.Cash += cashAdded
end

function PlayerData:RemoveCash(cashRemove)
	self.Cash -= cashRemove
end

function PlayerData:AddItem(ItemId)
	table.insert(self.ItemsBought, ItemId)
end

return PlayerData