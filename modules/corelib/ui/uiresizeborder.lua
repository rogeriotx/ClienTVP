-- @docclass
UIResizeBorder = extends(UIWidget, "UIResizeBorder")

function UIResizeBorder.create()
	local resizeborder = UIResizeBorder.internalCreate()
	resizeborder:setFocusable(false)
	resizeborder.minimum = 0
	resizeborder.maximum = 1000
	return resizeborder
end

function UIResizeBorder:onSetup()
	if self:getWidth() > self:getHeight() then
		self.vertical = true
	else
		self.vertical = false
	end
end

function UIResizeBorder:onDestroy()
	if self.hovering then
		g_mouse.popCursor(self.cursortype)
	end
end

function UIResizeBorder:onHoverChange(hovered)
	if hovered then
		if g_mouse.isCursorChanged() or g_mouse.isPressed() then return end
		if self:getWidth() > self:getHeight() then
			self.vertical = true
			self.cursortype = 'vertical'
		else
			self.vertical = false
			self.cursortype = 'horizontal'
		end
		g_mouse.pushCursor(self.cursortype)
		self.hovering = true
		if not self:isPressed() then
			g_effects.fadeIn(self)
		end
	else
		if not self:isPressed() and self.hovering then
			g_mouse.popCursor(self.cursortype)
			g_effects.fadeOut(self)
			self.hovering = false
		end
	end
end

function UIResizeBorder:onMouseMove(mousePos, mouseMoved)
	if self:isPressed() then
		local parent = self:getParent()
		local newSize = 0
		if self.vertical then
			local delta = mousePos.y - self:getY() - self:getHeight() / 2
			local realDelta = parent:getHeight()

			newSize = math.min(math.max(parent:getHeight() + delta, self.minimum), self.maximum)
			parent:setHeight(newSize)

			realDelta = realDelta - parent:getHeight()

			local MiniWindowContainer = parent:getParent()
			if MiniWindowContainer and MiniWindowContainer:getClassName() == 'UIMiniWindowContainer' then

				local resizeableWindows = {}

				local index = MiniWindowContainer:getChildIndex(parent)
				for i = index + 1, MiniWindowContainer:getChildCount() do
					local child = MiniWindowContainer:getChildByIndex(i)
					if child then
						if child:isVisible() and child:isResizeable() then
							local nextResizer = child.bottomResizeBorder
							if nextResizer then
								table.insert(resizeableWindows, {child, index})
							end
						end
					end
				end
				if realDelta > 0 then
					for i = #resizeableWindows, 1, -1 do
						local child = resizeableWindows[i][1]
						local nextResizer = child.bottomResizeBorder

						local prev = child:getHeight()

						newSize = math.min(math.max(child:getHeight() + realDelta, nextResizer.minimum), nextResizer.maximum)
						if newSize > prev then
							child:setHeight(newSize)
							break
						end
					end
				elseif #resizeableWindows > 0 then
					local child, index = resizeableWindows[#resizeableWindows][1], resizeableWindows[#resizeableWindows][2]
					if child then

						local prev = child:getHeight()
						if child:getY() + prev > child:getParent():getHeight() then
							local nextResizer = child.bottomResizeBorder
							newSize = math.min(math.max(prev + realDelta, nextResizer.minimum),
								nextResizer.maximum)
							if newSize < prev then
								child:setHeight(newSize)
							end
						else
							if index < MiniWindowContainer:getChildCount() then
								local lastChild = MiniWindowContainer:getChildByIndex(MiniWindowContainer:getChildCount())
								if lastChild then
									if lastChild:getY() + lastChild:getHeight() > child:getParent():getHeight() then -- último widget encostando no canto inferior
										local widgetWall = MiniWindowContainer:getChildByIndex(index+1)
										if child:getY() + prev > widgetWall:getY() then
											local nextResizer = child.bottomResizeBorder
											newSize = math.min(math.max(prev + realDelta, nextResizer.minimum),
												nextResizer.maximum)
											if newSize < prev then
												child:setHeight(newSize)
											end
										end
									end
								end
							end
						end
					end
				end
			end
		else
			local delta = mousePos.x - self:getX() - self:getWidth() / 2
			newSize = math.min(math.max(parent:getWidth() + delta, self.minimum), self.maximum)
			parent:setWidth(newSize)
		end

		self:checkBoundary(newSize)
		return true
	end
end

function UIResizeBorder:onMouseRelease(mousePos, mouseButton)
	if not self:isHovered() then
		g_mouse.popCursor(self.cursortype)
		g_effects.fadeOut(self)
		self.hovering = false
	end
end

function UIResizeBorder:onStyleApply(styleName, styleNode)
	for name, value in pairs(styleNode) do
		if name == 'maximum' then
			self:setMaximum(tonumber(value))
		elseif name == 'minimum' then
			self:setMinimum(tonumber(value))
		end
	end
end

function UIResizeBorder:onVisibilityChange(visible)
	if visible and self.maximum == self.minimum then
		self:hide()
	end
end

function UIResizeBorder:setMaximum(maximum)
	self.maximum = maximum
	self:checkBoundary()
end

function UIResizeBorder:setMinimum(minimum)
	self.minimum = minimum
	self:checkBoundary()
end

function UIResizeBorder:getMaximum() return self.maximum end

function UIResizeBorder:getMinimum() return self.minimum end

function UIResizeBorder:setParentSize(size)
	local parent = self:getParent()
	if self.vertical then
		parent:setHeight(size)
	else
		parent:setWidth(size)
	end
	self:checkBoundary(size)
end

function UIResizeBorder:getParentSize()
	local parent = self:getParent()
	if self.vertical then
		return parent:getHeight()
	else
		return parent:getWidth()
	end
end

function UIResizeBorder:checkBoundary(size)
	size = size or self:getParentSize()
	if self.maximum == self.minimum and size == self.maximum then
		self:hide()
	else
		self:show()
	end
end
