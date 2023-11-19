---@diagnostic disable: need-check-nil, deprecated, lowercase-global, undefined-field
---@diagnostic disable: param-type-mismatch

BallSpider = class(nil)
BallSpider.maxChildCount = 10
BallSpider.connectionOutput = 8
BallSpider.colorNormal = sm.color.new(0x5D0092ff)
BallSpider.colorHighlight = sm.color.new(0x8600D4ff)

local hoverHeight = 5
local skyboxLimit = 1000
local lasttick = sm.game.getCurrentTick()
local attackType = 0 -- | 0 - idle | 1 - laser burst | 2 - big laser | 3 - stomp | 4 - pathing | 5 - sticky bombs |

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

function float(shape, dt)
    local up = sm.vec3.new(0, 0, 1)
    local mass = shape:getBody().mass * 2
    local success, result = sm.physics.raycast(shape.worldPosition + sm.vec3.new(0, 0, -1),
        shape.worldPosition + sm.vec3.new(0, 0, -69), 32768, 128)
    if success then
        heightToGround = result.pointWorld.z --Override known ground height if too close to it
    else
        heightToGround = shape.worldPosition.z
    end

    local height = sm.util.lerp(hoverHeight, hoverHeight + 1, (sm.game.getCurrentTick() % 101) / 100) --makes it fly up and down

    local force = up * mass * ((heightToGround + height) - shape.worldPosition.z) * 5 * dt
    force = force - (shape.body.velocity * mass * 0.01)

    sm.physics.applyImpulse(shape, force, true)
end

function getMiddle(positions)
    if #positions == 0 then return end
    local sum = sm.vec3.zero()
    for _, position in ipairs(positions) do
        sum = sum + position
    end
    return sum / #positions
end

function BallSpider.server_onCreate(self)
    self.heightToGround = self.shape.worldPosition.z
    self.startRotation = self.shape.worldRotation
    --Create vision bubble
    self.sight = sm.areaTrigger.createAttachedSphere(self.interactable, 20, nil, nil, 4)
end

function BallSpider.client_onCreate(self)
    local shapes = self.shape.body:getCreationShapes()
    self.feet = {}
    self.feetPos = {}
    for _, shape in ipairs(shapes) do
        if shape.uuid == sm.uuid.new("b1c6bac0-4055-4193-8490-7704d0ea7113") then
            self.feet[#self.feet + 1] = shape
        end
    end
    for _, foot in ipairs(self.feet) do
        self.feetPos[#self.feetPos + 1] = foot.worldPosition
    end
end

function BallSpider.server_onFixedUpdate(self, dt)
    local up = sm.vec3.new(0, 0, 1)
    self.body = self.shape:getBody()
    local targetCharacter = sm.player.getAllPlayers()[1].character

    --Keep itself upright
    local normal = up:cross(self.shape.at)                              --the normal of two direction
    local AForce = (normal * self.body.mass * dt * 5)
    AForce = AForce - (self.body.angularVelocity * self.body.mass * dt) --reduces the velocity already present
    sm.physics.applyTorque(self.body, AForce, true)

    --Make it float
    local mass = self.shape:getBody().mass * 2
    local success, result = sm.physics.raycast(self.shape.worldPosition + sm.vec3.new(0, 0, -1),
        self.shape.worldPosition + sm.vec3.new(0, 0, -69), 32768, 128)
    if success then
        self.heightToGround = result.pointWorld.z --Override known ground height if too close to it
    end

    local height = sm.util.lerp(hoverHeight, hoverHeight + 1, (sm.game.getCurrentTick() % 101) / 100) --makes it fly up and down

    local force = up * mass * ((self.heightToGround + height) - self.shape.worldPosition.z) * 5 * dt
    force = force - (self.body.velocity * mass * 0.01)

    sm.physics.applyImpulse(self.shape, force, true)

    --Make it sit in the middle of all legs
    local distance = 1
    local speed = 100

    local dir = (getMiddle(self.feetPos) - self.shape.worldPosition)

    local sign = (dir:length() > distance) and 1 or -1             --makes the power reversed if it is too close

    dir = dir:normalize() * math.min(dir:length() / 3, speed) * dt --make it decelerate according to the distance
    sm.physics.applyImpulse(self.shape, dir * mass * 10 * sign * dt, true)

    if attackType == 1 then
        --Make it turn
        local dir = (targetCharacter.worldPosition - self.shape.worldPosition):normalize()
        local yaw = math.atan2(dir.y, dir.x) - math.pi / 2
        dir = -sm.vec3.new(math.cos(yaw), math.sin(yaw), 0) --Desired direction
        local normal = dir ---dir:cross(self.shape.up) --the normal of two direction
        local DForce = (normal * self.body.mass * dt * 5)
        DForce = DForce - (self.body.angularVelocity * self.body.mass * dt) --reduces the velocity already present
        sm.physics.applyTorque(self.body, DForce, true)
        if sm.game.getCurrentTick() == lasttick + 20 then
            lasttick = sm.game.getCurrentTick()
            sm.projectile.shapeFire(self.shape, sm.uuid.new("9012f301-ea27-4122-95f4-764210a510c5"), sm.vec3.new(0, 1, 0), targetCharacter.worldPosition, 40)
        end
    elseif attackType == 3 and sm.exists(closestFoot) then
        local length = (closestFoot.worldPosition - targetCharacter.worldPosition):length()
        local heightDiff = (closestFoot.worldPosition.z - targetCharacter.worldPosition.z)
        if length < 5 and length > 2 and heightDiff < 1 then
            float(closestFoot, dt)
            --Make it follow the player
            local distance = 0
            local speed = 10000
            local dir = (targetCharacter.worldPosition - closestFoot.worldPosition)
            local sign = (dir:length() > distance) and 1 or -1
            dir = dir:normalize() * math.min(dir:length() / 3, speed) * dt
            sm.physics.applyImpulse(closestFoot, dir * mass * 100 * sign * dt, true)
        end
    elseif attackType == 4 and #self.feet > 0 then

    end
end

function BallSpider.client_onFixedUpdate(self, dt)
    --[[
    if self.sight:getContents() ~= {} and self.sight:getContents() ~= nil then
        local closestplayer, playersfraction, direction
        for _, character in ipairs(self.sight:getContents()) do
            local hit, result = sm.physics.raycastTarget(self.shape.worldPosition, character.worldPosition, character)
            if hit then
                if closestplayer == nil then
                    closestplayer = result:getCharacter()
                    playersfraction = result.fraction
                    direction = result.directionWorld
                elseif playersfraction >= result.fraction then
                    closestplayer = result:getCharacter()
                    playersfraction = result.fraction
                    direction = result.directionWorld
                end
            end
        end
    end]]
    local targetCharacter = sm.player.getAllPlayers()[1].character
    local closestDistance = math.huge
    for _, shape in pairs(self.feet) do
        local distance = (shape.worldPosition - targetCharacter.worldPosition):length()
        if distance < closestDistance then
            closestDistance = distance
            closestFoot = shape
        end
    end
    --Keep itself upright
    local up = sm.vec3.new(0, 0, 1)
    local normal = -up:cross(closestFoot.at)
    local AForce = (normal * closestFoot.body.mass * dt * 5)
    AForce = AForce - (closestFoot.body.angularVelocity * closestFoot.body.mass * dt)
    sm.physics.applyTorque(closestFoot.body, AForce, true)
    sm.particle.createParticle("construct_welding", closestFoot.worldPosition)
end

function BallSpider.server_onRefresh(self)
    BallSpider.server_onCreate(self)
end

function BallSpider.client_onRefresh(self)
    BallSpider.client_onCreate(self)
end