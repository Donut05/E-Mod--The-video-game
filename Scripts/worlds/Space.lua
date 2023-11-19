---@diagnostic disable: undefined-global, undefined-field, need-check-nil

dofile"$SURVIVAL_DATA/Scripts/game/worlds/BaseWorld.lua"

Space = class(BaseWorld)

Space.terrainScript = "$GAME_DATA/Scripts/terrain/terrain_flat.lua" --"$CONTENT_DATA/Scripts/terrain/terrain_space.lua"
Space.groundMaterialSet = "$GAME_DATA/Terrain/Materials/gnd_standard_materialset.json"
Space.enableSurface = false
Space.enableAssets = true
Space.enableClutter = true
Space.enableNodes = true
Space.enableCreations = true
Space.enableHarvestables = true
Space.enableKinematics = true
Space.renderMode = "outdoor"
Space.cellMinX = -64
Space.cellMaxX = 63
Space.cellMinY = -48
Space.cellMaxY = 47

function Space.server_onCreate(self)
	BaseWorld.server_onCreate(self)
	sm.physics.setGravity(0)
end

function Space.sv_receievePosition(self, position)
	print("RECEIEVED INBOUND POSITION FROM THE OTHER SIDE!")
	self.inboundPosition = position
end

function Space.server_onFixedUpdate(self, dt)
	local portal = sm.portal.popWorldPortalHook("space_hole")
	if self.inboundPosition and portal and sm.exists(portal) then
		print("CREATING THE OTHER SIDE OF THE PORTAL!")
		portal:setOpeningB(sm.vec3.new(self.inboundPosition.x, self.inboundPosition.y, 0), sm.quat.identity())
		print("PORTAL CREATED! INITIATING TRANSFER!")
		portal:transferAToB()
		print("TRANSFER COMPLETE! CLOSING THE PORTAL!")
		sm.portal.destroy(portal)
		print("CLEARING INBOUND POSITION!")
		self.inboundPosition = nil
		print("ALL DONE!")
	end
end