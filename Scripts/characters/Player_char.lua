---@diagnostic disable: need-check-nil, undefined-global, undefined-field

dofile "$SURVIVAL_DATA/Scripts/game/characters/MechanicCharacter.lua"
dofile "$CONTENT_DATA/Scripts/visualised_trigger.lua"

PlayerChar = class(MechanicCharacter)

local TPcooldown = 30           --Cooldown after space teleportation, in seconds
local comingfromRefresh = false --A flag to check if the script is being refreshed to not trigger MechanicCharacter.client_onCreate(self) twice

function PlayerChar.server_onCreate(self)
    --Generic data creation below
    if not comingfromRefresh then
        MechanicCharacter.server_onCreate(self)
    else
        comingfromRefresh = false
    end
    --Debug print below
    print("PlayerChar.server_onCreate")
end

function PlayerChar.client_onCreate(self)
    --Generic data creation below
    if not comingfromRefresh then
        MechanicCharacter.client_onCreate(self)
    else
        comingfromRefresh = false
    end
    --Movement on creations helper shpere creation below
    self.movementHelperSphere = sm.areaTrigger.createSphere(2, sm.vec3.zero(), nil, 1)
    self.movementHelperSphere:bindOnStay("cl_creationMovementHelperOnStay")
    --Speed lines effect creation below
    self.debugVelocity = sm.effect.createEffect("ShapeRenderable")
    self.debugVelocity:setParameter("uuid", sm.uuid.new("628b2d61-5ceb-43e9-8334-a4135566df7a"))
    self.debugVelocity:setParameter("color", sm.color.new("FF0000"))
    self.fallingEffect = sm.effect.createEffect("Player - Anime_lines")
    --Space teleportation data creation below
    self.isOnCooldown = false
    self.previousTick = sm.game.getCurrentTick()
    self.spaceTeleportBox = CreateVisualizedTrigger(sm.vec3.new(self.character.worldPosition.x, self.character.worldPosition.y, 1000), sm.vec3.new(200, 200, 40))
    --Debug print below
    print("PlayerChar.client_onCreate")
end

function PlayerChar.client_onFixedUpdate(self, dt)
    --Generic checks below
    if not sm.exists(self.character) then
        return
    end
    if not (sm.localPlayer.getPlayer() == self.character:getPlayer()) then return end

    --Speed lines effect code below
    if self.fallingEffect ~= nil then
        if math.abs(self.character.velocity.x) > 20 or math.abs(self.character.velocity.y) > 20 or math.abs(self.character.velocity.z) > 20 then
            self.fallingEffect:setPosition(sm.camera.getPosition() + sm.camera.getDirection() / 2)
            local rotation = sm.camera.getRotation() * sm.vec3.getRotation(sm.vec3.new(0, 0, -1), sm.vec3.new(0, 1, 0))
            self.fallingEffect:setRotation(rotation)
            self.fallingEffect:start()
        else
            if self.fallingEffect:isPlaying() then
                self.fallingEffect:stop()
            end
        end
    end

    --Movement on creations helper code below
    self.movementHelperSphere:setWorldPosition(self.character.worldPosition)

    --Space teleportation code below
    if self.spaceTeleportBox and self.character.worldPosition.z > 700 then
        self.spaceTeleportBox:setPosition(sm.vec3.new(self.character.worldPosition.x, self.character.worldPosition.y, 1000))
        if #(self.spaceTeleportBox.trigger:getContents()) > 0 and not self.isOnCooldown then
            print("RAN TELEPORTATION CODE!!!!!!!!!!!!!!!!!!!!!!")
            self.isOnCooldown = true
            sm.event.sendToWorld(self.character:getWorld(), "cl_teleportToSpace", self.character.worldPosition)
        end
    end
    if self.isOnCooldown and sm.game.getCurrentTick() >= (self.previousTick + (TPcooldown * 40)) then
        print("TELEPORTATION COOLDOWN OVER!")
        self.previousTick = sm.game.getCurrentTick()
        self.isOnCooldown = false
    end
end

function PlayerChar.cl_creationMovementHelperOnStay(self, trigger, results)
    --Apply forces only if the player is not grounded
    local hit, trash = sm.physics.spherecast(self.character.worldPosition, self.character.worldPosition - sm.vec3.new(0, 0, 0.75), 0.29, self.character, sm.physics.filter.dynamicBody)
    if hit then return end
    --Get collective impulse of all bodies around the player
    local collectiveImpulse = sm.vec3.zero()
    for _, body in ipairs(results) do
        sm.particle.createParticle("construct_welding", body.worldPosition)
        collectiveImpulse = collectiveImpulse + body.velocity * 0.75
    end
    sm.physics.applyImpulse(self.character, collectiveImpulse, true)
    --Debug draw
    if not self.debugVelocity:isPlaying() then
        self.debugVelocity:start()
    end
    local shit = 0.1
    local fuckyou = collectiveImpulse * shit / 2
    self.debugVelocity:setPosition(fuckyou + self.character.worldPosition)
    local hueta = sm.vec3.new(collectiveImpulse:length() * shit, 0.10, 0.10)
    self.debugVelocity:setScale(hueta)
    self.debugVelocity:setRotation(sm.vec3.getRotation(sm.vec3.new(1, 0, 0), collectiveImpulse))
    sm.gui.displayAlertText(tostring(collectiveImpulse))
    sm.particle.createParticle("construct_welding", self.character.worldPosition + collectiveImpulse * shit)
end

function PlayerChar.server_onRefresh(self)
    comingfromRefresh = true
    self:server_onCreate()
end

function PlayerChar.client_onRefresh(self)
    comingfromRefresh = true
    self:client_onCreate()
end