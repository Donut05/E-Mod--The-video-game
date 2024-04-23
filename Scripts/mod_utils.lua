dofile("$CONTENT_e05e0ad2-0a5f-46f9-98ab-b26c0a844922/Scripts/game/ShapeLibrary.lua")
dofile("$CONTENT_e05e0ad2-0a5f-46f9-98ab-b26c0a844922/Scripts/game/managers/LanguageManager.lua")

--dofile("$CONTENT_e05e0ad2-0a5f-46f9-98ab-b26c0a844922/Scripts/game/mod_utils.lua") to dofile it

---@class mod_utils
mod_utils = {}

local function getDialogueText(text)
    if type(text) == "table" then
        return string.format(Language_tag(text[1]), Language_tag(text[2]))
    end

    return Language_tag(text)
end

---The current version of crashlander as a string.
mod_utils.version = "Release 1.1.1.0"

---*Client only*  
---Returns a translated string if a language tag with the given name exists, otherwise returns the given name.
---@param name? string
---@return string
function mod_utils.getDisplayName(name)
    if not name then return "" end

    local tagged = Language_tag(name)
    if tagged ~= "nil" then return tagged end

    return name
end

---*Client only*  
---Creates a dialog gui with the given parameters.
---@param text string The text that should be displayed
---@param optionsAmount number The amount of options **( allowed: 0, 1, 2, 3 )**
---@param optionsTexts? table A table containing the strings displayed in the options in order **(default: "Accept", "Decline", "Leave")**
---@param optionsCallback string The name of the callback to be called when an option is chosen
---@param icon? string The path to the icon that should be displayed **(default: player)**
---@param displayedName? string The name to display under the icon **(default: "")**
---@param isSelfTalkGui? boolean Whether the gui is a "self talk" gui **(Only when there's 0 options)**
---@param forceHud? boolean Whether to force the gui to be a hud or not. **(default: false)**
---@return GuiInterface dialogGui The created dialog gui
function mod_utils.createDialogGui( text, optionsAmount, optionsTexts, optionsCallback, icon, displayedName, isSelfTalkGui, forceHud )
    optionsTexts = optionsTexts or {"Accept", "Decline", "Leave"}
    local isSelfTalk = (optionsAmount == 0 and isSelfTalkGui)
    local hotbarStr = (optionsAmount ~= 0 and "HidesHotbar") or (isSelfTalk and optionsAmount == 0 and "") or "HidesHotbar"
    local gui = sm.gui.createGuiFromLayout("$CONTENT_e05e0ad2-0a5f-46f9-98ab-b26c0a844922/Gui/Layouts/HUD/QuestDialogBox"..tostring(optionsAmount).."Options"..hotbarStr..".layout", nil, {
        isHud = isSelfTalk or forceHud,
        isInteractive = not isSelfTalk,
        needsCursor = not isSelfTalk,
        hidesHotbar = not isSelfTalk,
        isOverlapped = false,
        backgroundAlpha = 0,
    })
    gui:setText("DialogText", getDialogueText(text))
    if isSelfTalk then
        gui:setImage("Icon", mod_utils.getNamedIconPath("player") or "$CONTENT_DATA/Gui/PlaceholderIcon.png")
        gui:setText("Name", Language_tag("quest_self_name"))
    else
        gui:setImage("Icon", mod_utils.getNamedIconPath(icon or "player") or "$CONTENT_DATA/Gui/PlaceholderIcon.png")
        gui:setText("Name", mod_utils.getDisplayName(displayedName))
    end
	if optionsAmount >= 1 then
	    gui:setText("OptionOne", getDialogueText(optionsTexts[1]))
        gui:setButtonCallback("OptionOne", optionsCallback)
	end
    if optionsAmount >= 2 then
        gui:setText("OptionTwo", getDialogueText(optionsTexts[2]))
        gui:setButtonCallback("OptionTwo", optionsCallback)
    end
    if optionsAmount >= 3 then
        gui:setText("OptionThree", getDialogueText(optionsTexts[3]))
        gui:setButtonCallback("OptionThree", optionsCallback)
    end
    return gui
end

---@alias namedIcon
---| "player"
---| "playerFemale"
---| "playerMale"
---| "loneGuy"
---| "mark"
---| "ivan"
---| "justin"
---| "hank"

---*Client only*  
---Returns the path to the icon with the given name, returns *nil* if the name is invalid.  
---@param name namedIcon The name of the icon
---@return string path The path of the icon, *nil* if invalid
function mod_utils.getNamedIconPath( name )
    local icons = {
        player = sm.localPlayer.getPlayer():isMale() and "$CONTENT_e05e0ad2-0a5f-46f9-98ab-b26c0a844922/Gui/HUD/DialogIcons/YourCharMale.png" or "$CONTENT_e05e0ad2-0a5f-46f9-98ab-b26c0a844922/Gui/HUD/DialogIcons/YourCharFemale.png",
        playerFemale = "$CONTENT_e05e0ad2-0a5f-46f9-98ab-b26c0a844922/Gui/HUD/DialogIcons/YourCharFemale.png",
        playerMale = "$CONTENT_e05e0ad2-0a5f-46f9-98ab-b26c0a844922/Gui/HUD/DialogIcons/YourCharMale.png",
        loneGuy = "$CONTENT_e05e0ad2-0a5f-46f9-98ab-b26c0a844922/Gui/HUD/DialogIcons/LoneGuy.png",
        mark = "$CONTENT_e05e0ad2-0a5f-46f9-98ab-b26c0a844922/Gui/HUD/DialogIcons/Mark.png",
        ivan = "$CONTENT_e05e0ad2-0a5f-46f9-98ab-b26c0a844922/Gui/HUD/DialogIcons/Ivan.png",
        justin = "$CONTENT_e05e0ad2-0a5f-46f9-98ab-b26c0a844922/Gui/HUD/DialogIcons/Justin.png",
        hank = "$CONTENT_e05e0ad2-0a5f-46f9-98ab-b26c0a844922/Gui/HUD/DialogIcons/Hank.png",
    }
    return icons[name]
end


---*Client only*  
---Creates a tool charge gui with the given icon.
---@param iconPath string The path to the icon
---@return GuiInterface toolChargeGui The created tool charge gui
function mod_utils.createToolChargeGui( iconPath )
    local gui = sm.gui.createGuiFromLayout("$CONTENT_e05e0ad2-0a5f-46f9-98ab-b26c0a844922/Gui/Layouts/Tools/Tool_Power.layout", nil, {
        isHud = true,
        isInteractive = false,
        needsCursor = false,
        hidesHotbar = false,
        isOverlapped = true,
        backgroundAlpha = 0
    })
	gui:setImage( "Icon", iconPath )
    return gui
end

---*Server only*  
---Checks if atleast one unit with this character uuid exists.
---@param uuid Uuid The uuid of the unit's character
---@return boolean boolean Whether a unit with this character uuid exists
function mod_utils.doesUnitExist(uuid)
	for _, unit  in ipairs(sm.unit.getAllUnits()) do
		if unit:getCharacter():getCharacterType() == uuid then
			return true
		end
	end
	return false
end

---*Server only*
---Checks how many units with this character uuid exist.
---@param uuid Uuid The uuid of the unit's character
---@return integer integer How many units with this character uuid exist
function mod_utils.getUnitQuantity(uuid)
    local quantity = 0
    for _, unit in ipairs(sm.unit.getAllUnits()) do
        if unit:getCharacter():getCharacterType() == uuid then
            quantity = quantity + 1
        end
    end
    return quantity
end

---*Server only*
---Kills all units with this character uuid.
---@param uuid Uuid The uuid of the unit's character
function mod_utils.killUnitsOfUuid(uuid)
    for _, unit in ipairs(sm.unit.getAllUnits()) do
        if unit:getCharacter():getCharacterType() == uuid then
            unit:destroy()
        end
    end
end

---@class isInLiquidFilter
---@field water boolean?
---@field chemical boolean?
---@field oil boolean?

---Checks whether the given areaTrigger is inside a liquid.
---@param areaTrigger AreaTrigger The areaTrigger to check
---@param filter? isInLiquidFilter The liquids to check for **(default: { water = true, chemical = true, oil = true })**
---@return boolean boolean Whether the areaTrigger is in a liquid that's in the filter
function mod_utils.isInLiquid(areaTrigger, filter)
    filter = filter or { water = true, chemical = true, oil = true }
    for i, content in ipairs(areaTrigger:getContents()) do
        if sm.exists( content ) and type( content ) == "AreaTrigger" and content:getUserData() then
            for k, v in pairs(content:getUserData()) do
                if filter[k] == true and v == true then
                    return true
                end
            end
        end
    end
    return false
end

---Returns whether the function is being run on the server.
---@return boolean isServer
function mod_utils.isServer()
    local succ, _ = pcall(sm.gui.getKeyBinding, "")
    return not succ
end

---Returns the player with the given name.
---@param name string The name of the Player
---@return Player? player nil if none is found
function mod_utils.getPlayerByName(name)
    for _, player in ipairs(sm.player.getAllPlayers()) do
        if player:getName() == name then
            return player
        end
    end
    return nil
end


---*Client only*  
---Returns whether the player action is bound.
---@param action string
function mod_utils.isActionBound(action)
    local notSet = "#{MENU_OPTIONS_CONTROLS_BINDING_NOT_SET}"
    local bind = sm.gui.getKeyBinding(action, false)
    --print("bind:", bind, "notSet:", notSet)
    return bind ~= notSet
end

---*Server and Client*  
---Returns the current weather.  
---See **sm.crashlander.weatherTypes**
---@return integer weatherType
function mod_utils.getCurrentWeatherType()
    return mod_utils.isServer() and g_weatherManager.publicData.currentWeather or g_weatherManager.clientPublicData.currentWeather
end

---*Client only*  
---Returns the current translated weather string and weather icon.  
---See **sm.crashlander.weatherTypes**
---@return string name, string iconPath
function mod_utils.getCurrentWeatherData()
	local currentWeatherString = tostring( mod_utils.getCurrentWeatherType() )
    return Language_tag( "weather_"..currentWeatherString ), "$CONTENT_DATA/Gui/WeatherIcons/weather_"..currentWeatherString..".png"
end

---*Server and Client*  
---Returns whether the current weather has rain in it.
---See **sm.crashlander.weatherTypes**
---@return boolean isRaining
function mod_utils.isRaining()
    local currWeather = mod_utils.getCurrentWeatherType()
    return currWeather == 1 or currWeather == 5
end

---A table of all weather types.
mod_utils.weatherTypes = {
    clear = 0,
    rain = 1,
    cloudy = 2,
    verycloudy = 3,
    fog = 4,
    storm = 5,
}

---Returns the index of the item in the table
---@param item any
---@param t table
---@return integer? index nil if that item isn't in the table
function mod_utils.getIndexOf(item, t)
    for i, item2 in ipairs(t) do
        if item2 == item then
            return i
        end
    end
    return nil
end

---Returns a random color.
---@return Color Color
function mod_utils.getRandomColor()
    return sm.color.new(
        math.random(0,255)/256,
        math.random(0,255)/256,
        math.random(0,255)/256
    )
end

---Returns the recipe of an item by it's UUID/UUID string.
---@param uuid Uuid|string
---@return table
function mod_utils.fetchRecipeByUUID(uuid)
    if not g_craftingRecipes then return {} end

    local uuid_str = tostring(uuid)
    for k, data in pairs(g_craftingRecipes) do
        for _uuid, recipe in pairs(data.recipes) do
            if _uuid == uuid_str then
                return recipe.ingredientList
            end
        end
    end

    return {}
end

---Returns the amount of completed achievements.
---@return number
function mod_utils.getCompletedAchievementCount()
    if not g_achievementData then return 0 end

    local count = 0
    for k, achData in pairs(g_achievementData) do
        if achData.data.complete == true then count = count + 1 end
    end

    return count
end

---*Client only*  
---Returns the screen size for icons in interaction texts
---@return string screenSize
function mod_utils.getInteractionIconScreenSize()
    local screenRes = sm.gui.getScreenSize()
    local ImgRes = 1080

    if screenRes > 2560 then
        ImgRes = 2160
    elseif screenRes > 1920 then
        ImgRes = 1440
    elseif screenRes > 1366 then
        ImgRes = 1080
    else
        ImgRes = 720
    end

    return tostring(ImgRes)
end

mod_utils.empty = "Never gonna give you up \nNever gonna let you down \nNever gonna run around and desert you \nNever gonna make you cry \nNever gonna say goodbye \nNever gonna tell a lie and hurt you"
mod_utils.npcUuids = {sm.uuid.new("36b1e8ff-8ffa-4b75-a548-1d6377434d53"), sm.uuid.new("4296f22c-1205-4035-bad8-e12120fce5a8"), sm.uuid.new("bf3982d8-ac96-47c0-b8b7-224f822180e2"), sm.uuid.new("ae6310a3-ea6c-4e8e-ac28-407bb0c2dfb1"), sm.uuid.new("538ec386-f714-4cde-bd82-ade0d6f5edbf")}

mod_utils.equipmentSlots = {
    head = "head",
    torso = "torso",
    leg = "leg",
    foot = "foot",
    accessory = "acc"
}

---@alias EquipmentSlot
---| "head"
---| "torso"
---| "leg"
---| "foot"
---| "acc"

---@class EquipmentItem
---@field uuid Uuid
---@field slot EquipmentSlot
---@field renderable string?
---@field stats EquipmentStats?
---@field onUpdate string?
---@field onUse string?
---@field setId string?

---@class EquipmentStats
---@field damageReduction number? The amount of damage that the equipment will block(in percents)
---@field oxygenMultiplier number? The amount the oxygen will be multiplied by when equipped
---@field waterMovementMultiplier number? The amount the swim speed will be multiplied by when equpped

---@class EquipmentCallback
---@field callback string The name of the function that will be called.
---@field object Harvestable|ScriptableObject|Character|Tool|Interactable|Unit|Player|World The reference to the object that the function will be called on.

---@class EquipmentCallbackArgument
---@field state boolean
---@field player Player

---**Server only**
---@param uuid Uuid UUID of the item.
---@param slot EquipmentSlot The slot that the equipment will be used in, check **sm.crashlander.equipmentSlots**.
---@param renderable string Path to the renderable of the equipment.
---@param stats? EquipmentStats The stats of the equipment, optional, defaults to no special stats.
---@param onUpdate? EquipmentCallback The function that will be called when the equipment is equipped/unequipped, optional. The callback recieves an [EquipmentCallbackArgument] object as an argument. **Client only**
---@param onUse? EquipmentCallback The function that will be called when the equipment is used(player presses R), optional. The callback recieves the [Player] that has the item equipped as an argument. **Client only**
---@param setId? string The set id of the equipment, optional. **Client only**
function mod_utils.addEquipment(uuid, slot, renderable, stats, onUpdate, onUse, setId)
    assert(mod_utils.isServer() == true, "'sm.crashlander.addEquipment' must be called from a server function!")
    assert(type(uuid) == "Uuid", "'sm.crashlander.addEquipment', #1 expected 'Uuid', got '"..type(uuid).."'")
    assert(type(slot) == "string", "'sm.crashlander.addEquipment', #2 expected 'string', got '"..type(slot).."'")
    assert(renderable == nil or type(renderable) == "string", "'sm.crashlander.addEquipment', #3 expected 'string', got '"..type(renderable).."'")
    assert(stats == nil or type(stats) == "table", "'sm.crashlander.addEquipment', #4 expected 'table', got '"..type(stats).."'")
    assert(onUpdate == nil or type(onUpdate) == "table", "'sm.crashlander.addEquipment', #5 expected 'table', got '"..type(onUpdate).."'")
    assert(onUse == nil or type(onUse) == "table", "'sm.crashlander.addEquipment', #6 expected 'table', got '"..type(onUse).."'")
    assert(setId == nil or type(setId) == "string", "'sm.crashlander.addEquipment', #7 expected 'string', got '"..type(setId).."'")

    sm.event.sendToPlayer(
        sm.player.getAllPlayers()[1],
        "sv_updateEquipmentList",
        {
            uuid = uuid,
            slot = slot,
            renderable = renderable,
            stats = stats or {},
            onUpdate = onUpdate,
            onUse = onUse,
            setId = setId
        }
    )
end

---@param character Character The player's character 
---@return EquipmentItem[] equipmentList The list of equipped items
function mod_utils.getEquipmentList(character)
    if mod_utils.isServer() then
        return character.publicData.equipment
    end

    return character.clientPublicData.equipment
end

---@param character Character The player's character 
---@param uuid Uuid The uuid of the equipment
---@return boolean isEquipped, EquipmentItem? equipmentItem Whether the item is equipped or not
function mod_utils.isEquipmentEquipped(character, uuid)
    for k, item in pairs(mod_utils.getEquipmentList(character)) do
        if item.uuid == uuid then
            return true, item
        end
    end

    return false
end

---@param character Character The player's character 
---@param setId string The id of the equipment set
---@return boolean isEquipped
function mod_utils.isEquipmentSetEquipped(character, setId)
    local count = 0
    for k, item in pairs(mod_utils.getEquipmentList(character)) do
        if item.setId == setId then
            count = count + 1
        end
    end

    return count == 4
end

function mod_utils.combineTables(...)
    local combinedTable = {}
    for _, tableToCombine in ipairs({...}) do
        for _, value in ipairs(tableToCombine) do
            table.insert(combinedTable, value)
        end
    end

    return combinedTable
end

---Gets the actual length of a table.
---@param tbl table
---@return number
function mod_utils.getRealLength(tbl)
    if not tbl then return 0 end

	local count = 0
	for k, v in pairs(tbl) do
		count = count + 1
	end

	return count
end

---Gets an item from the table by a number index.
---@param tbl table
---@param index number
---@return any
function mod_utils.getByIndex(tbl, index)
    if not tbl then return end

	local count = 1
	for k, v in pairs(tbl) do
		if count == index then
			return v
		end

		count = count + 1
	end
end

---Returns true if any item from tbl is anywhere in tbl2
---@param tbl table
---@param tbl2 table
---@return any
function mod_utils.areAnyOf(tbl, tbl2)
    if not tbl then return false end

	for k, v in pairs(tbl) do
		if isAnyOf(v, tbl2) then
			return true
		end
	end
	return false
end

---Returns a table of all contents inside the specified container
---@param container Container
---@return table
function mod_utils.getContainerItems(container)
	local contents = {}
	if container and not container:isEmpty() then
		for i = 1, container:getSize() do
			local item = container:getItem(i - 1)
			if item.uuid ~= sm.uuid.getNil() then
				table.insert(contents, {uuid = item.uuid, quantity = item.quantity})
			end
		end
	end
	return contents
end


---@alias LanguageName string
---| "Brazilian"
---| "Chinese"
---| "English"
---| "French"
---| "German"
---| "Italian"
---| "Japanese"
---| "Korean"
---| "Polish"
---| "Russian"
---| "Spanish"

---**Server only**
---@param path string The path to the json file containing the tags. The path has to use $CONTENT_<uuid of your mod> instead of $CONTENT_DATA, or else it will refer to the Crashlander files. (You can find the uuid of your mod in description.json in the root folder of your mod)
---@param language LanguageName The language that the tags are for.
function mod_utils.addLanguageTagSet(path, language)
    assert(mod_utils.isServer() == true, "'sm.crashlander.addLanguageTagSet' must be called from a server function!")

    sm.event.sendToScriptableObject(g_languageManager.scriptableObject, "sv_addTags", { path = path, language = language })
end

---@type mod_utils
sm.crashlander = mod_utils

print("[CRASHLANDER] API LOADED")