vipWindow = nil
addVipWindow = nil
editVipWindow = nil
vipInfo = {}

function init()
	connect(g_game, {
		onGameStart = refresh,
		onGameEnd = onGameEnd,
		onAddVip = onAddVip,
		onVipStateChange = onVipStateChange
	})


	g_keyboard.bindKeyDown('Ctrl+P', toggle)

	-- vipButton = modules.client_topmenu.addRightGameToggleButton('vipListButton', tr('VIP List') .. ' (Ctrl+P)',
	-- 	'/images/topbuttons/viplist', toggle, false, 3, tr('VIP'))
	vipWindow = g_ui.loadUI('viplist', modules.game_interface.getRightPanel())
	vipWindow.topButton = modules.game_sidemenu.getVipListButton()
	refresh()
end

function terminate()
	g_keyboard.unbindKeyDown('Ctrl+P')
	disconnect(g_game, {
		onGameStart = refresh,
		onGameEnd = onGameEnd,
		onAddVip = onAddVip,
		onVipStateChange = onVipStateChange
	})

	if addVipWindow then
		addVipWindow:destroy()
	end

	if editVipWindow then
		editVipWindow:destroy()
	end

	vipWindow:destroy()
end

function loadVipInfo()
	local settings = g_settings.getNode('VipList')
	if not settings then
		vipInfo = {}
		return
	end

	vipInfo = settings['VipInfo'] or {}
end

function getVipListInfo()
	return vipInfo
end

function setVipListInfo(info)
	vipInfo = info
end

function saveVipInfo()
	local settings = g_settings.getNode('VipList')
	if settings then
		settings['VipInfo'] = vipInfo
	else
		settings = {
			["VipInfo"] = vipInfo
		}
	end
	g_settings.mergeNode('VipList', settings)
end

function refresh()
	vipWindow:setup()

	clear()
	loadVipInfo()

	local lista = g_game.getVips()
	local sorted = getSortedBy()

	-- Comparison function for sorting by name
	local function compareByName(a, b)
		local a_name = a[1]:lower()
		local b_name = b[1]:lower()

		return a_name < b_name
	end

	-- Comparison function for sorting by type
	local function compareByType(a, b)
		local a_iconId = a[4]
		local b_iconId = b[4]
		if a_iconId > b_iconId then
			return false
		elseif a_iconId == b_iconId then
			return compareByName(a, b)
		else
			return true
		end
	end

	-- Comparison function for sorting by status
	local function compareByStatus(a, b)
		local a_state = a[2]
		local b_state = b[2]

		if a_state == VipState.Online and b_state ~= VipState.Online then
			return true
		elseif a_state ~= VipState.Online and b_state == VipState.Online then
			return false
		else
			return compareByType(a, b)
		end
	end

	-- Sort the lista table based on the value of sorted
	local sortFunctions = {
		name = compareByName,
		status = compareByStatus,
		type = compareByType
	}

	local sortedList = {}
	if sortFunctions[sorted] then
		-- Bubble sort algorithm
		for id, a in pairs(lista) do
			a[5] = id
			if vipInfo[tostring(id)] then
				a[4] = vipInfo[tostring(id)].iconId
			end
			table.insert(sortedList, a)
		end
		table.sort(sortedList, sortFunctions[sorted])
	end

	for _, vip in ipairs(sortedList) do
		onAddVipWidget(vip[5], vip[1], vip[2], vip[3], vip[4])
	end

	vipWindow:setContentMinimumHeight(43)
end

function clear()
	local vipList = vipWindow:getChildById('contentsPanel')
	vipList:destroyChildren()
	vipInfo = {}
end

function onGameEnd()
	-- saveVipInfo()
	-- clear()
	-- vipInfo = {}
end

function toggle()
	if modules.game_sidemenu.getVipListButton():isOn() then
		vipWindow:close()
	else
		vipWindow:open()
	end
end

function onMiniWindowClose()
	modules.game_sidemenu.getVipListButton():setOn(false)
end

function createAddWindow()
	if not addVipWindow then
		addVipWindow = g_ui.displayUI('addvip')
	end
end

function createEditWindow(widget)
	if editVipWindow then
		return
	end

	editVipWindow = g_ui.displayUI('editvip')

	local name = widget:getText()
	local id = widget:getId():sub(4)

	local okButton = editVipWindow:getChildById('buttonOK')
	local cancelButton = editVipWindow:getChildById('buttonCancel')

	local nameLabel = editVipWindow:getChildById('nameLabel')
	nameLabel:setText(name)

	local descriptionText = editVipWindow:getChildById('descriptionText')
	descriptionText:appendText(widget:getTooltip())

	local notifyCheckBox = editVipWindow:recursiveGetChildById('checkBoxNotify')
	notifyCheckBox:setChecked(widget.notifyLogin)

	local iconRadioGroup = UIRadioGroup.create()
	for i = VipIconFirst, VipIconLast do
		iconRadioGroup:addWidget(editVipWindow:recursiveGetChildById('icon' .. i))
	end
	iconRadioGroup:selectWidget(editVipWindow:recursiveGetChildById('icon' .. widget.iconId))

	local cancelFunction = function()
		editVipWindow:destroy()
		iconRadioGroup:destroy()
		editVipWindow = nil
	end

	local saveFunction = function()
		local vipList = vipWindow:getChildById('contentsPanel')
		if not widget or not vipList:hasChild(widget) then
			cancelFunction()
			return
		end

		local name = widget:getText()
		local state = widget.vipState
		local description = descriptionText:getText()
		local iconId = tonumber(iconRadioGroup:getSelectedWidget():getId():sub(5))
		local notify = notifyCheckBox:isChecked()

		if g_game.getFeature(GameAdditionalVipInfo) then
			g_game.editVip(id, description, iconId, notify)
		else
			vipInfo[id] = { description = description, iconId = iconId, notifyLogin = notify }
		end

		saveVipInfo()
		refresh()

		editVipWindow:destroy()
		iconRadioGroup:destroy()
		editVipWindow = nil
	end

	cancelButton.onClick = cancelFunction
	okButton.onClick = saveFunction

	editVipWindow.onEscape = cancelFunction
	editVipWindow.onEnter = saveFunction
end

function destroyAddWindow()
	addVipWindow:destroy()
	addVipWindow = nil
end

function addVip()
	g_game.addVip(addVipWindow:getChildById('name'):getText())
	destroyAddWindow()
end

function removeVip(widgetOrName)
	if not widgetOrName then
		return
	end

	local widget
	local vipList = vipWindow:getChildById('contentsPanel')
	if type(widgetOrName) == 'string' then
		local entries = vipList:getChildren()
		for i = 1, #entries do
			if entries[i]:getText():lower() == widgetOrName:lower() then
				widget = entries[i]
				break
			end
		end
		if not widget then
			return
		end
	else
		widget = widgetOrName
	end

	if widget then
		local id = widget:getId():sub(4)
		g_game.removeVip(id)
		vipList:removeChild(widget)
		if vipInfo[id] and g_game.getFeature(GameAdditionalVipInfo) then
			vipInfo[id] = nil
		end
	end
end

function hideOffline(state)
	vipInfo['hideOffline'] = state
	saveVipInfo()
	refresh()
end

function isHiddingOffline()
	return vipInfo['hideOffline']
end

function getSortedBy()
	if not vipInfo['sortedBy'] then
		return 'status'
	end
	return vipInfo['sortedBy']
end

function sortBy(state)
	vipInfo['sortedBy'] = state
	saveVipInfo()
	refresh()
end

function onAddVip()
	saveVipInfo()
	refresh()
end

function onAddVipWidget(id, name, state, description, iconId, notify)
	if not name or name:len() == 0 then
		return
	end

	local vipList = vipWindow:getChildById('contentsPanel')
	for _, child in pairs(vipList:getChildren()) do
		if child:getText() == name then
			return -- don't add duplicated vips
		end
	end

	local label = g_ui.createWidget('VipListLabel')
	label.onMousePress = onVipListLabelMousePress
	label:setId('vip' .. id)
	label:setText(name)

	if not g_game.getFeature(GameAdditionalVipInfo) then
		local tmpVipInfo = vipInfo[tostring(id)]
		label.iconId = 0
		label.notifyLogin = false
		if tmpVipInfo then
			if tmpVipInfo.iconId then
				label:setImageClip(torect((tmpVipInfo.iconId * 12) .. ' 0 12 12'))
				label.iconId = tmpVipInfo.iconId
			end
			if tmpVipInfo.description then
				label:setTooltip(tmpVipInfo.description)
			end
			label.notifyLogin = tmpVipInfo.notifyLogin or false
		end
	else
		label:setTooltip(description)
		label:setImageClip(torect((iconId * 12) .. ' 0 12 12'))
		label.iconId = iconId
		label.notifyLogin = notify
	end

	if state == VipState.Online then
		label:setColor('#5FF75F')
	elseif state == VipState.Pending then
		label:setColor('#ffca38')
	else
		label:setColor('#F75F5F')
	end

	label.vipState = state

	label:setPhantom(false)
	connect(label, { onDoubleClick = function()
		g_game.openPrivateChannel(label:getText())
		return true
	end })

	if state == VipState.Offline and isHiddingOffline() then
		label:setVisible(false)
	end

	vipList:addChild(label)
end

function onVipStateChange(id, state)
	local vipList = vipWindow:getChildById('contentsPanel')
	local label = vipList:getChildById('vip' .. id)
	if not label then
		return
	end
	local name = label:getText()
	local description = label:getTooltip()
	local iconId = label.iconId
	local notify = label.notifyLogin
	label:destroy()
	
	saveVipInfo()
	refresh()

	if notify and state ~= VipState.Pending then
		modules.game_textmessage.displayFailureMessage(tr('%s has logged %s.', name, (state == VipState.Online and 'in' or 'out')))
	end
end

function onVipListMousePress(widget, mousePos, mouseButton)
	if mouseButton ~= MouseRightButton then return end

	local vipList = vipWindow:getChildById('contentsPanel')

	local menu = g_ui.createWidget('PopupMenu')
	menu:setGameMenu(true)
	menu:addOption(tr('Add new VIP'), function() createAddWindow() end)

	menu:addOption(tr('Sort by name'), function() sortBy('name') end)
	menu:addOption(tr('Sort by type'), function() sortBy('type') end)
	menu:addOption(tr('Sort by status'), function() sortBy('status') end)

	if not isHiddingOffline() then
		menu:addOption(tr('Hide Offline VIPs'), function() hideOffline(true) end)
	else
		menu:addOption(tr('Show offline VIPs'), function() hideOffline(false) end)
	end
	menu:display(mousePos)

	return true
end

function onVipListLabelMousePress(widget, mousePos, mouseButton)
	if mouseButton ~= MouseRightButton then return end

	local vipList = vipWindow:getChildById('contentsPanel')

	local menu = g_ui.createWidget('PopupMenu')
	menu:setGameMenu(true)
	menu:addOption(tr('Edit %s', widget:getText()), function() if widget then createEditWindow(widget) end end)
	menu:addOption(tr('Remove %s', widget:getText()), function() if widget then removeVip(widget) end end)
	menu:addOption(tr('Message to %s', widget:getText()), function() g_game.openPrivateChannel(widget:getText()) end)
	menu:addSeparator()
	menu:addOption(tr('Add new VIP'), function() createAddWindow() end)

	menu:addOption(tr('Sort by name'), function() sortBy('name') end)
	menu:addOption(tr('Sort by type'), function() sortBy('type') end)
	menu:addOption(tr('Sort by status'), function() sortBy('status') end)

	if not isHiddingOffline() then
		menu:addOption(tr('Hide Offline VIPs'), function() hideOffline(true) end)
	else
		menu:addOption(tr('Show offline VIPs'), function() hideOffline(false) end)
	end

	menu:addSeparator()
	if modules.game_console.getOwnPrivateTab() then
		menu:addSeparator()
		menu:addOption(tr('Invite to private chat'), function() g_game.inviteToOwnChannel(widget:getText()) end)
		menu:addOption(tr('Exclude from private chat'), function() g_game.excludeFromOwnChannel(widget:getText()) end)
	end

	menu:addOption(tr('Copy Name'), function() g_window.setClipboardText(widget:getText()) end)


	menu:display(mousePos)

	return true
end
