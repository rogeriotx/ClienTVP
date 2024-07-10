-- @docclass
UIMiniBroder = extends(UIWidget, "UIMiniBroder")

function UIMiniBroder.create()
    local resizeborder = UIMiniBroder.internalCreate()
    resizeborder:setFocusable(false)
    resizeborder.minimum = 0
    resizeborder.maximum = 1000
    return resizeborder
end

function UIMiniBroder:onSetup()
    self.cursortype = 'vertical'
end

function UIMiniBroder:onDestroy()
    if self.hovering then
        g_mouse.popCursor(self.cursortype)
    end
end

function UIMiniBroder:onHoverChange(hovered)
    self.hovering = hovered
    -- local dx, dy = mousePos.x - self:getX(), mousePos.y - self:getY()
    -- print("onMouseMove", self.hovering, dx, dy)
    -- if self.hovering then
    --     if dy > dx then
    --         -- if g_mouse.isCursorChanged() or g_mouse.isPressed() then
    --         -- else
    --         -- end
    --         g_mouse.pushCursor(self.cursortype)
    --     elseif not self:isPressed() and self.hovering then
    --         g_mouse.popCursor(self.cursortype)
    --     end
    -- end
end

function UIMiniBroder:onMouseMove(mousePos, mouseMoved)

    if self:isPressed() then
        local parent = self:getParent()
        local newSize = 0

        local delta = mousePos.y - self:getY() - self:getHeight() / 2
        newSize = math.min(math.max(parent:getHeight() + delta, self.minimum), self.maximum)
        parent:setHeight(newSize)

        self:checkBoundary(newSize)
        return true
    end
end

function UIMiniBroder:onMouseRelease(mousePos, mouseButton)
    if not self:isHovered() then
        g_mouse.popCursor(self.cursortype)
        self.hovering = false
    end
end

function UIMiniBroder:onStyleApply(styleName, styleNode)
    for name, value in pairs(styleNode) do
        if name == 'maximum' then
            self:setMaximum(tonumber(value))
        elseif name == 'minimum' then
            self:setMinimum(tonumber(value))
        end
    end
end

function UIMiniBroder:onVisibilityChange(visible)
    if visible and self.maximum == self.minimum then
        self:hide()
    end
end

function UIMiniBroder:setMaximum(maximum)
    self.maximum = maximum
    self:checkBoundary()
end

function UIMiniBroder:setMinimum(minimum)
    self.minimum = minimum
    self:checkBoundary()
end

function UIMiniBroder:getMaximum() return self.maximum end

function UIMiniBroder:getMinimum() return self.minimum end

function UIMiniBroder:setParentSize(size)
    local parent = self:getParent()
    parent:setHeight(size)
    self:checkBoundary(size)
end

function UIMiniBroder:getParentSize()
    local parent = self:getParent()
    return parent:getHeight()
end

function UIMiniBroder:checkBoundary(size)
    size = size or self:getParentSize()
    if self.maximum == self.minimum and size == self.maximum then
        self:hide()
    else
        self:show()
    end
end
