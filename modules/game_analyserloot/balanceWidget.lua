balanceWidget = {

	colors = {
		loot = "#09b500",
		supplies = "#f6ff00",
		profit = "#81ff85",
		loss = "#bd110b"
	},

  loot = 0,
  supplies = 0,

  widget = nil
}

function balanceWidget:clear()
  self.loot = 0
  self.supplies = 0

	self:setLoot(0)
	self:setSupplies(0)
	self:setBalance(0)
end

function balanceWidget:setLoot(value)
	self:setValue("labelLoot", formatNumber(value) .. " gp")
	self:setColor("labelLoot", self.colors.loot)
end

function balanceWidget:setSupplies(value)
	self:setValue("labelSupplies", formatNumber(value) .. " gp")
	self:setColor("labelSupplies", self.colors.supplies)
end

function balanceWidget:setBalance(value)
	self:setValue("labelBalance", formatNumber(value) .. " gp")

  if value > 0 then
		self:setColor("labelBalance", self.colors.profit)
	else
		self:setColor("labelBalance", self.colors.loss)
	end
end

function balanceWidget:update(category, cost)
  local balance = 0

	if category == "loot" then
		self.loot = self.loot + cost
	elseif category == "supply" then
		self.supplies = self.supplies + cost
	end

  balance = self.loot - self.supplies

	balanceWidget:setLoot(self.loot)
	balanceWidget:setSupplies(self.supplies)
	balanceWidget:setBalance(balance)
end

function balanceWidget:setValue(id, value)
	local skill = self.widget:recursiveGetChildById(id)

	if skill then
		local widget = skill:getChildById("value")

		widget:setText(value)
	end
end

function balanceWidget:setColor(id, value)
	local skill = self.widget:recursiveGetChildById(id)

	if skill then
		local widget = skill:getChildById("value")

		widget:setColor(value)
	end
end