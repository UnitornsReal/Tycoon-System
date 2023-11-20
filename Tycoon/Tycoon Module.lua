local Tycoon = {}
Tycoon.__index = Tycoon

local templateTycon = game.ReplicatedStorage:WaitForChild("Tycoon")

--Create the tycoon
function Tycoon.new(tycoonModel)
	local self = setmetatable({}, Tycoon)

	self.Model = tycoonModel
	self.Buttons = tycoonModel:WaitForChild("Buttons")
	
	self.Dependencies = {}
	self.ItemIdBought = {}
	
	return self
end

--Assign the tycoon
function Tycoon:Assign(player)
	player.RespawnLocation = self.Model:WaitForChild("Spawn")
	self.Model:SetAttribute("PlayerID", player.UserId)
	
	self:LoadSaved(player)
	self:GetButtonsPressed(player)
	
	player:LoadCharacter()
end

function Tycoon:LoadSaved(player)
	local playerData = require(script.Parent:FindFirstChild("Player Data")):GetPlayerData(player)
	
	if playerData.ItemsBought then
		for _, ItemId in playerData.ItemsBought do
			local button = self:GetButtonById(ItemId)
			if button then button:Destroy() end
			
			self:SetItem(player, ItemId)
		end
	end
end

--Processes the buttons pressed
function Tycoon:GetButtonsPressed(player)
	local firstDependency = 1000000000

	for _,button in self.Buttons:GetChildren() do
		local dependency = button:GetAttribute("Dependency")
		local connection
		
		if dependency < firstDependency then
			firstDependency = dependency
		end
		
		button:FindFirstChild("Display Information").Item.Text = Tycoon.GetItemById(button:GetAttribute("ItemId")).Name
		button:FindFirstChild("Display Information").Price.Text = "Price: "..tostring(button:GetAttribute("Price"))
		
		if not self.Dependencies[dependency] then self.Dependencies[dependency] = {} end
		table.insert(self.Dependencies[dependency], button)
		
		local function buy(hit)
			local player = game.Players:GetPlayerFromCharacter(hit.Parent)
			if (player and player.UserId == self.Model:GetAttribute("PlayerID")) then

				local claimItem = self:ClaimItem(player, button, button:GetAttribute("ItemId"))

				if claimItem then
					table.remove(self.Dependencies[dependency], table.find(self.Dependencies[dependency], button))
					button:Destroy()
					
					self:AreDependenciesUnlocked(dependency)
					
					connection:Disconnect()
				end
			end
		end
		
		connection = button.Touched:Connect(buy)
	end
	
	self:SetObtainableButtons(firstDependency)
end

function Tycoon:ClaimItem(player, button, ItemId)
	local tycoon = self.Model
	local price = button:GetAttribute("Price")
	
	local playerData = require(script.Parent:FindFirstChild("Player Data")):GetPlayerData(player)
	
	if playerData.Cash < price then return false end
	
	playerData:RemoveCash(price)
	playerData:AddItem(ItemId)
	
	self:SetItem(player, ItemId)
	
	return true
end

function Tycoon:SetItem(player, ItemId)
	local item = Tycoon.GetItemById(ItemId):Clone()
	local relativeCFrame = templateTycon.PrimaryPart.CFrame:ToObjectSpace(item:GetPivot())
	local worldCFrame = self.Model.PrimaryPart.CFrame:toWorldSpace(relativeCFrame)

	item.Parent = self.Model.Items
	item:PivotTo(worldCFrame)
	
	self:AnimateItem(item)
	
	if item:GetAttribute("ItemType") and item:GetAttribute("ItemType") == "Dropper" then
		local interval = item:GetAttribute("Interval")
		local cashReward = item:GetAttribute("CashReward")
		
		local newDropper = require(script.Parent:WaitForChild("Droppers")).new(item, interval, cashReward)
		
		local connection
		connection = game["Run Service"].Heartbeat:Connect(function(delta)
			newDropper:Update(delta, self.Model)
		end)
	end
end

function Tycoon:SetObtainableButtons(firstDependency)
	for _, button in pairs(self.Buttons:GetChildren()) do
		local displayInfo = button:FindFirstChild("Display Information")

		if button:GetAttribute("Dependency") > firstDependency then
			self:DisableButton(button, displayInfo)
		else
			self:EnableButton(button, displayInfo)
		end
	end
end

function Tycoon:GetButtonById(ItemId)
	for _, button in self.Buttons:GetChildren() do
		if button:GetAttribute("ItemId") == ItemId then
			return button
		end
	end
end

function Tycoon:DisableButton(button, displayInfo)
	displayInfo.Enabled = false
	button.Transparency = 1
	button.CanCollide = false
	button.CanTouch = false
end

function Tycoon:EnableButton(button, displayInfo)
	displayInfo.Enabled = true
	button.Transparency = 0
	button.CanCollide = true
	button.CanTouch = true
end

function Tycoon:AnimateItem(item)
	for _, part in item:GetChildren() do
		local originalSize = part.Size
		part.Size = Vector3.new(0,0,0)

		local tween = game.TweenService:Create(part, TweenInfo.new(1.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false), {Size = originalSize})
		tween:Play()
	end
end

function Tycoon:AreDependenciesUnlocked(dependency)
	if #self.Dependencies[dependency] <= 0 then
		self:SetObtainableButtons(dependency + 1)
	end
end

--Additional Functions
function Tycoon.GetTycoon(tycoons)
	for _, tycoon in tycoons:GetChildren() do
		if not tycoon:GetAttribute("PlayerID") then 
			local newButtons = templateTycon:FindFirstChild("Buttons"):Clone()

			local relativeCFrame = templateTycon.PrimaryPart.CFrame:ToObjectSpace(newButtons:GetPivot())
			local worldCFrame = tycoon.PrimaryPart.CFrame:toWorldSpace(relativeCFrame)

			newButtons.Parent = tycoon
			newButtons:PivotTo(worldCFrame)

			return tycoon 
		end
	end
end

function Tycoon.GetItemById(ItemId)
	for _, item in templateTycon:FindFirstChild("Items"):GetChildren() do
		if item:GetAttribute("ItemId") == ItemId then
			return item
		end
	end
end

function Tycoon.ResetTycoon(tycoon)
	tycoon:FindFirstChild("Buttons"):Destroy()
	tycoon:FindFirstChild("Items"):ClearAllChildren()
	tycoon:SetAttribute("PlayerID", nil)
end

return Tycoon