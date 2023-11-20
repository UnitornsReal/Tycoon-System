local Dropper = {}
Dropper.__index = Dropper

function Dropper.new(dropper, interval, cashReward)
	local self = setmetatable({}, Dropper)
	self.dropper = dropper
	self.Interval = interval
	self.CashReward = cashReward
	self.Timer = 0
	return self
end

function Dropper:Update(deltaTime, tycoon)
	self.Timer = self.Timer + deltaTime
	if self.Timer >= self.Interval then
		self:DropItem(tycoon)
		self.Timer = 0
	end
end

function Dropper:DropItem(tycoon)
	local money = script:WaitForChild("Money"):Clone()
	money.Parent = workspace
	money.Anchored = false
	money:PivotTo(self.dropper:WaitForChild("DropPos").CFrame)
	
	local connection
	connection = money.Touched:Connect(function(hit)
		if hit:HasTag("Collector") then
			self:ApplyCash(tycoon)
			money:Destroy()
			connection:Disconnect()
		end
	end)
end

function Dropper:ApplyCash(tycoon)
	local player = game.Players:GetPlayerByUserId(tycoon:GetAttribute("PlayerID"))
	if player then
		local playerData = require(script.Parent:FindFirstChild("Player Data")):GetPlayerData(player)
		playerData:AddCash(self.CashReward)
	end
end

return Dropper