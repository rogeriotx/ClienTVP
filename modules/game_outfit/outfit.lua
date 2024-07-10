local window = nil

local colorModeGroup = nil
local colorBoxGroup = nil

local colorBoxes = {}
local currentColorBox = nil

ignoreNextOutfitWindow = 0
local tempOutfit = {}
local ServerData = {
  currentOutfit = {},
  outfits = {},
}

local AppearanceData = {
  "outfit"
}

function init()
  connect(
    g_game,
    {
      onOpenOutfitWindow = create,
      onGameEnd = destroy
    }
  )
end

function terminate()
  disconnect(
    g_game,
    {
      onOpenOutfitWindow = create,
      onGameEnd = destroy
    }
  )
  destroy()
end

function create(currentOutfit, outfitList, mountList, wingList, auraList, shaderList, healthBarList, manaBarList)
  if ignoreNextOutfitWindow and g_clock.millis() < ignoreNextOutfitWindow + 1000 then
    return
  end

  if window then
    destroy()
  end

  if currentOutfit.shader == "" then
    currentOutfit.shader = "outfit_default"
  end

  ServerData = {
    currentOutfit = currentOutfit,
    outfits = outfitList,
  }

  window = g_ui.displayUI("outfitwindow")

  previewCreature = window.creature

  tempOutfit = currentOutfit

  local hasOutfit = false
  for i = 1, #ServerData.outfits do
    if ServerData.outfits[i][1] == tempOutfit.type then
        tempOutfit.name = ServerData.outfits[i][2]
        tempOutfit.addons = ServerData.outfits[i][3]
        hasOutfit = true
      break
    end
  end

  if not hasOutfit then
    tempOutfit.type = ServerData.outfits[1][1]
    tempOutfit.name = ServerData.outfits[1][2]
    tempOutfit.addons = ServerData.outfits[1][3]
  end

  updatePreview()

  if currentOutfit.addons == 3 then
    window.addon1.check:setChecked(true)
    window.addon2.check:setChecked(true)
  elseif currentOutfit.addons == 2 then
    window.addon1.check:setChecked(false)
    window.addon2.check:setChecked(true)
  elseif currentOutfit.addons == 1 then
    window.addon1.check:setChecked(true)
    window.addon2.check:setChecked(false)
  end
  window.addon1.check.onCheckChange = onAddonChange
  window.addon2.check.onCheckChange = onAddonChange

  configureAddons(currentOutfit.addons)

  colorBoxGroup = UIRadioGroup.create()
  for j = 0, 6 do
    for i = 0, 18 do
      local colorBox = g_ui.createWidget("OutfitColorBox", window.colorBoxPanel)
      local outfitColor = getOutfitColor(j * 19 + i)
      colorBox:setBackgroundColor(outfitColor)
      colorBox:setId("colorBox" .. j * 19 + i)
      colorBox.colorId = j * 19 + i

      if colorBox.colorId == currentOutfit.head then
        currentColorBox = colorBox
        colorBox:setChecked(true)
      end
      colorBoxGroup:addWidget(colorBox)
    end
  end

  colorBoxGroup.onSelectionChange = onColorCheckChange

  colorModeGroup = UIRadioGroup.create()
  colorModeGroup:addWidget(window.head)
  colorModeGroup:addWidget(window.primary)
  colorModeGroup:addWidget(window.secondary)
  colorModeGroup:addWidget(window.detail)

  colorModeGroup.onSelectionChange = onColorModeChange
  colorModeGroup:selectWidget(window.head)
end

function destroy()
  if window then
    window:destroy()
    window = nil

    colorBoxes = {}
    currentColorBox = nil

    colorModeGroup:destroy()
    colorModeGroup = nil
    colorBoxGroup:destroy()
    colorBoxGroup = nil

    ServerData = {
      currentOutfit = {},
      outfits = {},
    }

  end
end

function configureAddons(addons)
  local hasAddon1 = addons == 1 or addons == 3
  local hasAddon2 = addons == 2 or addons == 3
  window.addon1.check:setEnabled(hasAddon1)
  window.addon2.check:setEnabled(hasAddon2)

  window.addon1.check.onCheckChange = nil
  window.addon2.check.onCheckChange = nil
  window.addon1.check:setChecked(false)
  window.addon2.check:setChecked(false)
  if tempOutfit.addons == 3 then
    window.addon1.check:setChecked(true)
    window.addon2.check:setChecked(true)
  elseif tempOutfit.addons == 2 then
    window.addon1.check:setChecked(false)
    window.addon2.check:setChecked(true)
  elseif tempOutfit.addons == 1 then
    window.addon1.check:setChecked(true)
    window.addon2.check:setChecked(false)
  end
  window.addon1.check.onCheckChange = onAddonChange
  window.addon2.check.onCheckChange = onAddonChange
end

function onOutfitSelect(list, focusedChild, unfocusedChild, reason)
  if focusedChild then
    local outfitType = tonumber(focusedChild:getId())
    local outfit = focusedChild.outfit:getOutfit()
    tempOutfit.type = outfit.type
    tempOutfit.addons = outfit.addons

    configureAddons(outfit.addons)

    if showOutfitCheck:isChecked() then
      updatePreview()
    end
  end
end


function onAddonChange(widget, checked)
  local addonId = widget:getParent():getId()

  local addons = tempOutfit.addons
  if addonId == "addon1" then
    addons = checked and addons + 1 or addons - 1
  elseif addonId == "addon2" then
    addons = checked and addons + 2 or addons - 2
  end

  tempOutfit.addons = addons
  updatePreview()
end

function onColorModeChange(widget, selectedWidget)
  local colorMode = selectedWidget:getId()
  if colorMode == "head" then
    colorBoxGroup:selectWidget(window.colorBoxPanel["colorBox" .. tempOutfit.head])
  elseif colorMode == "primary" then
    colorBoxGroup:selectWidget(window.colorBoxPanel["colorBox" .. tempOutfit.body])
  elseif colorMode == "secondary" then
    colorBoxGroup:selectWidget(window.colorBoxPanel["colorBox" .. tempOutfit.legs])
  elseif colorMode == "detail" then
    colorBoxGroup:selectWidget(window.colorBoxPanel["colorBox" .. tempOutfit.feet])
  end
end

function onColorCheckChange(widget, selectedWidget)
  local colorId = selectedWidget.colorId
  local colorMode = colorModeGroup:getSelectedWidget():getId()
  if colorMode == "head" then
    tempOutfit.head = colorId
  elseif colorMode == "primary" then
    tempOutfit.body = colorId
  elseif colorMode == "secondary" then
    tempOutfit.legs = colorId
  elseif colorMode == "detail" then
    tempOutfit.feet = colorId
  end

  updatePreview()
end

function updatePreview()
  local direction = previewCreature:getDirection()
  local previewOutfit = table.copy(tempOutfit)
  previewCreature:show()
  window.name:setText(tempOutfit.name)
  previewCreature:setOutfit(previewOutfit)
  previewCreature:setDirection(direction)
end

function accept()
  g_game.changeOutfit(tempOutfit)
  destroy()
end

function prevPreview()
  for i = 1, #ServerData.outfits do
    if ServerData.outfits[i][1] == tempOutfit.type then
      if i <= 1 then
        tempOutfit.type = ServerData.outfits[#ServerData.outfits][1]
        tempOutfit.name = ServerData.outfits[#ServerData.outfits][2]
        tempOutfit.addons = ServerData.outfits[#ServerData.outfits][3]
      else
        tempOutfit.type = ServerData.outfits[i - 1][1]
        tempOutfit.name = ServerData.outfits[i - 1][2]
        tempOutfit.addons = ServerData.outfits[i - 1][3]
      end
      break
    end
  end
  configureAddons(tempOutfit.addons)
  updatePreview()
end

function nextPreview()
  for i = 1, #ServerData.outfits do
    if ServerData.outfits[i][1] == tempOutfit.type then
      if i >= #ServerData.outfits then
        tempOutfit.type = ServerData.outfits[1][1]
        tempOutfit.name = ServerData.outfits[1][2]
        tempOutfit.addons = ServerData.outfits[1][1]
      else
        tempOutfit.type = ServerData.outfits[i + 1][1]
        tempOutfit.name = ServerData.outfits[i + 1][2]
        tempOutfit.addons = ServerData.outfits[i + 1][3]
      end
      break
    end
  end
  configureAddons(tempOutfit.addons)
  updatePreview()
end
