---@diagnostic disable: lowercase-global, need-check-nil, undefined-field

Cloak = class(nil)
Cloak.maxParentCount = 2
Cloak.maxChildCount = 255
Cloak.connectionInput = sm.interactable.connectionType.logic + sm.interactable.connectionType.electricity
Cloak.connectionOutput = sm.interactable.connectionType.logic
Cloak.colorNormal = sm.color.new(0xff8000ff)
Cloak.colorHighlight = sm.color.new(0xff9f3aff)

function getCreationAabb(bodies)
    local boxMin, boxMax
    for _, body in ipairs(bodies) do
        local a, b = body:getWorldAabb()
        boxMin = (boxMin == nil) and a or boxMin:min(a)
        boxMax = (boxMax == nil) and b or boxMax:max(b)
    end

    return boxMin, boxMax
end

function DEBUG_createRectangleFrame(vec3A, vec3B)
    -- Determine the minimum and maximum points for the two corners
    local minPoint = sm.vec3.new(math.min(vec3A.x, vec3B.x), math.min(vec3A.y, vec3B.y), math.min(vec3A.z, vec3B.z))
    local maxPoint = sm.vec3.new(math.max(vec3A.x, vec3B.x), math.max(vec3A.y, vec3B.y), math.max(vec3A.z, vec3B.z))

    -- Calculate the other two corners of the rectangle
    local corner1 = minPoint
    local corner2 = sm.vec3.new(minPoint.x, minPoint.y, maxPoint.z)
    local corner3 = maxPoint
    local corner4 = sm.vec3.new(maxPoint.x, minPoint.y, minPoint.z)

    local frame = { corner1, corner2, corner3, corner4 }

    return frame
end

function Cloak.client_onCreate(self)
    self.cloakEffect = sm.effect.createEffect("Cloak_generator - Activation_plus_idle")
end

function Cloak.client_onFixedUpdate(self, dt)
    if self.interactable:isActive() then
        local bodies = self.interactable.body:getCreationBodies()
        local boxMin, boxMax = getCreationAabb(bodies)
        local scale = boxMax - boxMin
        self.cloakEffect:setPosition(boxMax)
        self.cloakEffect:setParameter("Scale", scale * 10)
        if not self.cloakEffect:isPlaying() then
            self.cloakEffect:start()
        end
    else
        if self.cloakEffect:isPlaying() then
            self.cloakEffect:stop()
        end
    end
end

function Cloak.client_onUpdate(self, dt)
    local parent = self.interactable:getParents(1)[1]
    if not parent then return end
    if parent:isActive() ~= self.interactable:isActive() then
        if parent:isActive() then
            self.network:sendToServer("sv_changeState", true)
        else
            self.network:sendToServer("sv_changeState", false)
        end
    end
end

function Cloak.client_onInteract(self, character, state)
    if not state then return end
    self.network:sendToServer("sv_changeState", not self.interactable:isActive())
end

function Cloak.sv_changeState(self, state)
    self.interactable:setActive(state)
end

function Cloak.client_onRefresh(self)
    print("Cloack gen refreshed!")
    self:client_onCreate()
end