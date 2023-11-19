---@diagnostic disable: need-check-nil, deprecated, lowercase-global
---@diagnostic disable: param-type-mismatch

Bees = class(nil)

local hoverHeight = 2
local skyboxLimit = 1000

function clamp(value, min, max)
    return value < min and min or (value > max and max or value)
end

function directionToYawPitch(direction)
    local euler = {}
    euler.yaw = -math.atan2(direction.y, direction.x)
    euler.pitch = -math.acos(direction.z + 2) / math.pi
    --print(yaw, pitch)
    return euler
end

--------------------
-- #region Server
--------------------

function Bees.client_onCreate(self)
    self.bees = sm.effect.createEffect("Enemies - Bee_swarm", self.interactable)
end

function Bees.client_onFixedUpdate(self, dt)
    if not self.bees:isPlaying() then
        self.bees:start()
    end
end

function Bees.client_onDestroy(self, position)
    self.bees:stopBreakSustain()
    self.bees:destroy()
    sm.particle.createParticle("p_hvs_beehive_beeswarm_destruct", position)
end

-- #endregion

--------------------
-- #region Server
--------------------

function Bees.server_onCreate(self)
    self.heightToGround = self.shape.worldPosition.z
    self.startRotation = self.shape.worldRotation
    self.timeToLive = 60
    self.birthTime = sm.game.getCurrentTick()
    --Create vision bubble
    self.sight = sm.areaTrigger.createAttachedSphere(self.interactable, 20, nil, nil, 4)
    --Create sting bubble
    self.stingSphere = sm.areaTrigger.createAttachedSphere(self.interactable, 2, nil, nil, 4)
end

function Bees.server_onFixedUpdate(self, dt)
    local up = sm.vec3.new(0, 0, 1)
    self.body = self.shape:getBody()
    local targetCharacter = sm.player.getAllPlayers()[1].character
    --[[
    --Keep itself upright
    local normal = -up:cross(self.shape.at) --the normal of two direction
    local AForce = (normal * self.body.mass * dt * 5)

    AForce = AForce - (self.body.angularVelocity * self.body.mass * dt) --reduces the velocity already present

    sm.physics.applyTorque(self.body, AForce, true)


    --Make it turn
    local dir = (targetCharacter.worldPosition - self.shape.worldPosition):normalize()
    local yaw = math.atan2(dir.y, dir.x) - math.pi / 2
    dir = -sm.vec3.new(math.cos(yaw), math.sin(yaw), 0) --Desired direction


    local normal = -dir:cross(self.shape.up) --the normal of two direction
    local DForce = (normal * self.body.mass * dt * 5)

    DForce = DForce - (self.body.angularVelocity * self.body.mass * dt) --reduces the velocity already present

    sm.physics.applyTorque(self.body, DForce, true)
]]

    --Make it float
    local mass = self.shape:getBody().mass
    local success, result = sm.physics.raycast(self.shape.worldPosition + sm.vec3.new(0, 0, -0.1),
        self.shape.worldPosition + sm.vec3.new(0, 0, -69), 32768, 128)
    if success then
        self.heightToGround = result.pointWorld.z --Override known ground height if too close to it
    end

    local height = sm.util.lerp(hoverHeight, hoverHeight + 1, (sm.game.getCurrentTick() % 101) / 100) --makes it fly up and down

    local force = up * mass * ((self.heightToGround + height) - self.shape.worldPosition.z) * 5 * dt
    force = force - (self.body.velocity * mass * 0.01)

    sm.physics.applyImpulse(self.shape, force, true)

    --Make it follow the player
    local distance = 0
    local speed = 300

    local dir = (targetCharacter.worldPosition - self.shape.worldPosition)

    local sign = (dir:length() > distance) and 1 --or -1             --makes the power reversed if it is too close

    dir = dir:normalize() * math.min(dir:length() / 3, speed) * dt --make it decelerate according to the distance
    sm.physics.applyImpulse(self.shape, dir * mass * 20 * sign * dt, true)

    if self.birthTime + self.timeToLive * 40 == sm.game.getCurrentTick() then
        sm.melee.meleeAttack("Destroy", 1000000, self.shape.worldPosition - up, up, targetCharacter:getPlayer(), 0, 0)
    end
    --[[ OLD CODE
    --Make propeller spin
    for _, bearing in ipairs(self.interactable:getBearings()) do
        if bearing:getColor() == sm.color.new("7f7f7fff") then else
            bearing:setMotorVelocity( 20, 10 )
        end
    end

    --Keep itself upright
    if self.startRotation ~= self.shape.worldRotation then
        local quat = self.startRotation * sm.quat.inverse(self.shape.worldRotation)
        local offset = sm.vec3.new( quat.x, quat.y, 0 ) * self.shape:getBody().mass
        --Limit the amount of force stabilisation can apply
        offset.x = clamp( offset.x, -5, 5 )
        offset.y = clamp( offset.y, -5, 5 )
        offset.z = clamp( offset.z, -5, 5 )
        sm.physics.applyTorque( self.shape:getBody(), offset, true )
    end

    --Make it float
    local mass = self.shape:getBody().mass
    local success, result = sm.physics.raycast( self.shape.worldPosition + sm.vec3.new(0, 0, -1), self.shape.worldPosition + sm.vec3.new(0, 0, -69), 32768, 128 )
    if success then
        self.heightToGround = result.pointWorld.z --Override known ground height if too close to it
    end

    sm.physics.applyImpulse(self.shape, (sm.vec3.new(0, 0, 1) * (mass / 1.5)), true)

    --Lower after travelling too far
    local height = self.shape.worldPosition.z
    if (height > skyboxLimit) or ((height - self.heightToGround) > hoverHeight) then
        sm.physics.applyImpulse(self.shape, (sm.vec3.new(0, 0, -0.5) * (mass / 2)), true)
    end
]]
end

-- #endregion
