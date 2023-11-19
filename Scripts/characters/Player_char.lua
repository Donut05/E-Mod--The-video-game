---@diagnostic disable: need-check-nil, undefined-global, undefined-field

dofile "$SURVIVAL_DATA/Scripts/game/characters/MechanicCharacter.lua"
dofile "$CONTENT_DATA/Scripts/visualised_trigger.lua"

PlayerChar = class(MechanicCharacter)

local falling -- Global for speed lines effect
local TPcooldown = 30 --Cooldown after space teleportation, in seconds

function PlayerChar.server_onCreate(self)
        -- Generic data creation below
    MechanicCharacter.server_onCreate(self)
        -- Debug print below
    print("PlayerChar.server_onCreate")
end

function PlayerChar.client_onCreate(self)
        -- Generic data creation below
    MechanicCharacter.client_onCreate(self)
        -- Speed lines effect creation below
    falling = sm.effect.createEffect("Player - Anime_lines")
        -- Space teleportation data creation below
    self.isOnCooldown = false
    self.previousTick = sm.game.getCurrentTick()
    self.spaceTeleportBox = CreateVisualizedTrigger(sm.vec3.new(self.character.worldPosition.x, self.character.worldPosition.y, 1000), sm.vec3.new(200, 200, 40))
        -- Debug print below
    print("PlayerChar.client_onCreate")
end

function PlayerChar.client_onFixedUpdate(self, dt)
        -- Generic checks below
    if not sm.exists(self.character) then
        return
    end
    if not (sm.localPlayer.getPlayer() == self.character:getPlayer()) then return end
        -- Speed lines effect code below
    if falling ~= nil then
        if math.abs(self.character.velocity.x) > 20 or math.abs(self.character.velocity.y) > 20 or math.abs(self.character.velocity.z) > 20 then
            falling:setPosition(sm.camera.getPosition() + sm.camera.getDirection() / 2)
            local rotation = sm.camera.getRotation() * sm.vec3.getRotation(sm.vec3.new(0, 0, -1), sm.vec3.new(0, 1, 0))
            falling:setRotation(rotation)
            falling:start()
        else
            if falling:isPlaying() then
                falling:stop()
            end
        end
    end
        -- Space teleportation code below
    if self.spaceTeleportBox and self.character.worldPosition.z > 700 then
        self.spaceTeleportBox:setPosition(sm.vec3.new(self.character.worldPosition.x, self.character.worldPosition.y, 1000))
        if #(self.spaceTeleportBox.trigger:getContents()) > 0 and not self.isOnCooldown then
            print("RAN TELEPORTATION CODE!!!!!!!!!!!!!!!!!!!!!!")
            self.isOnCooldown = true
            sm.event.sendToWorld( self.character:getWorld(), "cl_teleportToSpace", self.character.worldPosition)
        end
    end
    if self.isOnCooldown and sm.game.getCurrentTick() >= (self.previousTick + (TPcooldown * 40)) then
        print("TELEPORTATION COOLDOWN OVER!")
        self.previousTick = sm.game.getCurrentTick()
        self.isOnCooldown = false
    end
end