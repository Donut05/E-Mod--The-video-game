dofile("$SURVIVAL_DATA/Scripts/game/survival_loot.lua")

---A Chest can be used to store items from your inventory. Stored items cannot be deleted and will be dropped if the Chest is destroyed.
---@class Chest : ShapeClass
---@field sv ChestSv
---@field cl ChestCl
Chest = class(nil)
Chest.poseWeightCount = 1

--------------------
-- #region Server
--------------------

function Chest.server_onCreate(self)
	local container = self.shape.interactable:getContainer(0)
	if not container then
		container = self.shape:getInteractable():addContainer(0, self.data.slots, 65535)
	elseif self.shape.body:isOnLift() then
		--empty container when spawned via lift
		sm.container.beginTransaction()
		for i = 0, container.size, 1 do
			sm.container.setItem(container, i, sm.uuid.getNil(), 0)
		end
		sm.container.endTransaction()
	end

	self.sv = {
		container = container,
		lootList = {},
		cachedPos = self.shape.worldPosition,
		playersHavingChestGuiOpen = 0
	}
end

function Chest:server_onFixedUpdate()
	if not sm.exists(self.shape) then return end

	--cache chest data
	self.sv.lootList = {}
	for i = 0, self.sv.container.size, 1 do
		local item = self.sv.container:getItem(i)
		if item.uuid ~= sm.uuid.getNil() then
			self.sv.lootList[#self.sv.lootList + 1] = item
		end
	end

	self.sv.cachedPos = self.shape.worldPosition

	if self.shape.body:isOnLift() then
		Chest.setIsInWater(self, false)
	end
end

function Chest.server_onDestroy(self)
	--drop chest contents when destroyed
	---@diagnostic disable-next-line: undefined-global
	SpawnLoot(sm.player.getAllPlayers()[1], self.sv.lootList, self.sv.cachedPos)
end

function Chest.server_canErase(self)
	return self.sv.container:isEmpty()
end

function Chest.sv_openChestAnim(self)
	self.sv.playersHavingChestGuiOpen = self.sv.playersHavingChestGuiOpen + 1
	if self.sv.playersHavingChestGuiOpen == 1 then
		self.network:sendToClients("cl_openChestAnim")
	end
end

function Chest.sv_closeChestAnim(self)
	self.sv.playersHavingChestGuiOpen = self.sv.playersHavingChestGuiOpen - 1
	if self.sv.playersHavingChestGuiOpen == 0 then
		self.network:sendToClients("cl_closeChestAnim")
	end
end

-- #endregion

--------------------
-- #region Client
--------------------

local chestOpeningSpeed = 8.0
local effectRoationFix = sm.vec3.getRotation(sm.vec3.new(0, 0, 1), sm.vec3.new(0, 1, 0))

function Chest:client_onCreate()
	---@diagnostic disable-next-line: missing-fields
	self.cl = {}
	self.cl.chestAnimDirection = -1
	self.cl.isInWater = false
	if self.data.uwLoopingEffect then
		self.cl.bubblesLooping = sm.effect.createEffect(self.data.uwLoopingEffect, self.interactable)
	else
		self.cl.bubblesLooping = sm.effect.createEffect("Chests - Large_chest_bubbles_loop", self.interactable)
	end
	self.cl.bubblesLooping:setOffsetRotation(effectRoationFix)
end

function Chest.client_onInteract(self, character, state)
	if not state then return end
	local container = self.shape.interactable:getContainer(0)
	if container then
		self.cl.containerGui = sm.gui.createContainerGui(true)
		if self.data.title then
			self.cl.containerGui:setText("UpperName", self.data.title)
		else
			self.cl.containerGui:setText("UpperName", "#{CONTAINER_TITLE_GENERIC}")
		end
		self.cl.containerGui:setVisible("TakeAll", true)
		self.cl.containerGui:setContainer("UpperGrid", container);
		self.cl.containerGui:setText("LowerName", "#{INVENTORY_TITLE}")
		self.cl.containerGui:setContainer("LowerGrid", sm.localPlayer.getInventory())
		self.cl.containerGui:setOnCloseCallback("cl_guiClosed")
		self.cl.containerGui:open()

		if self.data.openSound then
			if self.data.openSound2 and sm.cae_injected then
				if math.random(0, 1) == 0 then
					sm.effect.playEffect(self.data.openSound, self.shape.worldPosition)
				else
					sm.effect.playEffect(self.data.openSound2, self.shape.worldPosition)
				end
			else
				sm.effect.playEffect(self.data.openSound, self.shape.worldPosition)
			end
		else
			sm.effect.playEffect("Action - Chest_Open", self.shape.worldPosition)
		end
		self.network:sendToServer("sv_openChestAnim")
	end
end

function Chest.cl_guiClosed(self)
	self.network:sendToServer("sv_closeChestAnim")
	if self.data.closeSound then
		if self.data.closeSound2 and sm.cae_injected then
			if math.random(0, 1) == 0 then
				sm.effect.playEffect(self.data.closeSound, self.shape.worldPosition)
			else
				sm.effect.playEffect(self.data.closeSound2, self.shape.worldPosition)
			end
		else
			sm.effect.playEffect(self.data.closeSound, self.shape.worldPosition)
		end
	else
		sm.effect.playEffect("Action - Chest_Close", self.shape.worldPosition)
	end
end

function Chest.client_onDestroy(self)
	if self.cl.containerGui then
		if sm.exists(self.cl.containerGui) then
			self.cl.containerGui:close()
			self.cl.containerGui:destroy()
		end
	end
end

function Chest.cl_openChestAnim(self)
	self.cl.chestAnimDirection = 1
	if self.cl.isInWater then
		if self.data.uwOpenEffect then
			sm.effect.playEffect(self.data.uwOpenEffect, self.shape.worldPosition, nil,
				self.shape.worldRotation * effectRoationFix)
		else
			sm.effect.playEffect("Chests - Large_chest_bubbles_open", self.shape.worldPosition, nil,
				self.shape.worldRotation * effectRoationFix)
		end
	end
end

function Chest.cl_closeChestAnim(self)
	self.cl.chestAnimDirection = -1
	if self.cl.isInWater then
		if self.data.uwCloseEffect then
			sm.effect.playEffect(self.data.uwCloseEffect, self.shape.worldPosition, nil,
				self.shape.worldRotation * effectRoationFix)
		else
			sm.effect.playEffect("Chests - Large_chest_bubbles_close", self.shape.worldPosition, nil,
				self.shape.worldRotation * effectRoationFix)
		end
	end
end

function Chest.client_onUpdate(self, dt)
	local poseWeight = self.interactable:getPoseWeight(0)
	poseWeight = poseWeight + (chestOpeningSpeed * self.cl.chestAnimDirection) * dt
	poseWeight = sm.util.clamp(poseWeight, 0, 1)
	self.interactable:setPoseWeight(0, poseWeight)
	if self.cl.isInWater then
		if not self.cl.bubblesLooping:isPlaying() then
			self.cl.bubblesLooping:start()
		end
	else
		if self.cl.bubblesLooping:isPlaying() then
			self.cl.bubblesLooping:stop()
		end
	end
end

-- #endregion

--------------------
-- #region Custom
--------------------

function Chest.setIsInWater(self, isInWater)
	self.cl.isInWater = isInWater
end

-- #endregion

--------------------
-- #region Types
--------------------

---@class ChestSv
---@field container Container
---@field cachedPos Vec3 cached position of the Chest
---@diagnostic disable-next-line: undefined-doc-name
---@field lootList table <number, Item> list of all items in a Chest
---@field playersHavingChestGuiOpen integer how many players have the chest opened rn

---@class ChestCl
---@field containerGui GuiInterface gui that is visible when opening the chest
---@field chestAnimDirection -1|1 whehter the chest keeps opening or closing
---@field isInWater boolean whehter the chest is in the water or not
---@field bubblesLooping Effect Looping bubbles effect that plays when chest is underwater


-- #endregion
