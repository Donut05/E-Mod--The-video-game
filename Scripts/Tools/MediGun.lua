---@class Medi : ToolClass
---@field target Character
---@field effects Effect[]
Medi = class()

local defaultDir = sm.vec3.new(1, 0, 0)
local cycles = 20
local range = 100

---@param target Character
function Medi.sv_updateTarget(self, target)
    if target then
        target:setTumbling(true)
        target:getUnit().publicData.mediBeamActive = true
    elseif self.target then
        self.target:getUnit().publicData.mediBeamActive = false
    end

    self.network:sendToClients("cl_updateTarget", target)
end

function Medi.client_onCreate(self)
    self.target = nil
    self.effects = {}
    for i = 1, cycles do
        self.effects[#self.effects + 1] = sm.effect.createEffect("Medi - Beam_segment")
    end
end

function Medi:client_onDestroy()
    self:cl_stopFx()
end

function Medi.client_onUpdate(self)
    if not sm.exists(self.target) then
        self.target = nil
    end

    if not self.target or not self.tool:isEquipped() then
        self:cl_stopFx()
        return
    end

    local owner = self.tool:getOwner().character
    local start = owner.worldPosition
    local _end = self.target.worldPosition
    if self.tool:isLocal() and (_end - start):length2() > range then
        self.network:sendToServer("sv_updateTarget", nil)
        return
    end

    local mid = start + owner.direction * 5

    ---@diagnostic disable-next-line: param-type-mismatch
    local hit, result = sm.physics.raycast(start, mid, owner)
    if hit then
        mid = result.pointWorld + result.normalWorld * 0.1
    end

    local posCache = {} --Generate position cache for rotation
    for j = 1, cycles do
        posCache[j] = sm.vec3.bezier2(start, mid, _end, j / cycles)
    end

    for i = 1, cycles do
        local pos = posCache[i]
        local effect = self.effects[i]
        effect:setPosition(pos)

        local nextPos = posCache[i + 1]
        if nextPos then
            effect:setRotation(sm.vec3.getRotation(defaultDir, nextPos - pos))
        end

        if not effect:isPlaying() then effect:start() end
    end
end

function Medi.server_onFixedUpdate(self)
    --target synced to everyone, no need for the server to store it
    if not self.target or not sm.exists(self.target) then return end

    if self.target:isPlayer() then
        local edibleParams = {
            hpGain = 1
        }
        sm.event.sendToPlayer(self.target:getPlayer(), "sv_e_eat", edibleParams)
    end
end


function Medi:client_onUnequip()
    if self.tool:isLocal() then
        self.network:sendToServer("sv_updateTarget", nil)
    end
end

function Medi.client_onEquippedUpdate(self, lmb)
    if lmb == 1 then
        if self.target then
            self.network:sendToServer("sv_updateTarget", nil)
        else
            local hit, result = sm.localPlayer.getRaycast(math.sqrt(range))
            if hit then
                local character = result:getCharacter()
                if character then
                    self.network:sendToServer("sv_updateTarget", character)
                end
            end
        end
    end

    return true, true
end

function Medi.cl_updateTarget(self, target)
    self.target = target
end

function Medi:cl_stopFx()
    for i = 1, cycles do
        self.effects[i]:stopImmediate()
    end
end
