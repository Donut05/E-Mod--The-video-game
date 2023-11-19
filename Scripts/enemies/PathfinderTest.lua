---@diagnostic disable: deprecated, undefined-field
print("PathfinderTest.lua")
dofile("$CONTENT_DATA/Scripts/enemies/ai/PathFinder.lua")

---@class PathfinderTest:ShapeClass
PathfinderTest = class()

local maxRange = 100         -- Maximum scan distance
local sphereCastRadus = 0.25 -- The size of the SphereCast which checks if the node is valid
local nodeDistance = 0.5     -- The distance between the nodes

local function calculateRightVector(vector)
    local yaw = math.atan2(vector.y, vector.x) - math.pi / 2
    return sm.vec3.new(math.cos(yaw), math.sin(yaw), 0)
end

local function calculateUpVector(vector)
    return calculateRightVector(vector):cross(vector)
end

local function better_quat_rotation(forward, right, up)
    forward = forward:safeNormalize(sm.vec3.new(1, 0, 0))
    right = right:safeNormalize(sm.vec3.new(0, 0, 1))
    up = up:safeNormalize(sm.vec3.new(0, 1, 0))
    local e = right.x; local f = right.y; local g = right.z; local h = forward.x; local i = forward.y; local j = forward
    .z; local k = up.x; local l = up.y; local m = up.z; local n = 0; local o = e + i + m; local p = e - i - m; if p > o then
        o = p; n = 1
    end; local q = i - e - m; if q > o then
        o = q; n = 2
    end; local r = m - e - i; if r > o then
        o = r; n = 3
    end; local s = math.sqrt(o + 1.0) * 0.5; local t = 0.25 / s; if n == 1 then return sm.quat.new(s, (f + h) * t,
            (k + g) * t, (j - l) * t) elseif n == 2 then return sm.quat.new((f + h) * t, s, (j + l) * t, (k - g) * t) elseif n == 3 then return
        sm.quat.new((k + g) * t, (j + l) * t, s, (f - h) * t) end; return sm.quat.new((j - l) * t, (k - g) * t, (f - h) *
    t, s)
end

local function getNeighborNodes(currentNode, startNode, params)
    local neighborNodes = {}

    -- check if the node is valid
    local function neighborNodeIsValid(node)
        if (aStar.distance(node.vec3, startNode.vec3) > maxRange) or (math.abs(startNode.vec3.z - node.vec3.z) > math.min(maxRange, 10)) then
            return false
        end
        local dir = (currentNode.vec3 - node.vec3):normalize()
        local sValid, sResult = sm.physics.spherecast(currentNode.vec3 + dir * (nodeDistance), node.vec3, sphereCastRadus,
            params.ignore)
        local canReach = not (sValid and sResult.type ~= "Character")
        return canReach
    end

    -- scans neighboring nodes
    for x = -1, 1 do
        for y = -1, 1 do
            for z = -1, 1 do
                if (x .. y .. z) ~= "000" then
                    local addVector = sm.vec3.new(x, y, z) * nodeDistance
                    local neighborNode = aStar.vectorToNode(currentNode.vec3 + addVector)
                    if neighborNodeIsValid(neighborNode) then
                        neighborNodes[neighborNode.id] = neighborNode
                    end
                end
            end
        end
    end
    return neighborNodes
end


function PathfinderTest.client_onCreate(self)
    self.cl = {}
    self.cl.aStar = {}
    self.cl.aStar.endsWithDirectPath = false
    self.cl.path = {}
    self.cl.line = {}
end

function PathfinderTest.cl_showPath(self, path)
    if path then
        for k, node in pairs(path) do
            sm.effect.playEffect("SledgehammerHit - Default", node.vec3)
        end
    end
end

-- show the red line
function PathfinderTest.cl_effectShowPath(self, start, goal)
    if not self.cl.path then
        return
    end

    if self.cl.path[1] then
        if self.cl.line[1] then
            if not self.cl.line[1]:isPlaying() then
                self.cl.line[1]:start()
            end

            local delta = start - self.cl.path[1].vec3
            local length = delta:length()

            local rot = better_quat_rotation(calculateUpVector(delta), delta, calculateRightVector(delta))
            local distance = sm.vec3.new(length, 0.10, 0.10)

            self.cl.line[1]:setPosition(self.cl.path[1].vec3 + delta * 0.5)
            self.cl.line[1]:setScale(distance)
            self.cl.line[1]:setRotation(rot)
        else
            self.cl.line[1] = sm.effect.createEffect("ShapeRenderable")
            self.cl.line[1]:setParameter("uuid", sm.uuid.new("628b2d61-5ceb-43e9-8334-a4135566df7a"))
            self.cl.line[1]:setParameter("color", sm.color.new("FF0000"))
        end
    end

    for i = 1, math.max(#self.cl.path, #self.cl.line), 1 do
        if self.cl.path[i] and self.cl.path[i + 1] then
            if self.cl.line[i + 1] then
                if not self.cl.line[i + 1]:isPlaying() then
                    self.cl.line[i + 1]:start()
                end

                local delta = self.cl.path[i + 1].vec3 - self.cl.path[i].vec3
                local length = delta:length()

                local rot = better_quat_rotation(calculateUpVector(delta), delta, calculateRightVector(delta))
                local distance = sm.vec3.new(length, 0.10, 0.10)

                self.cl.line[i + 1]:setPosition(self.cl.path[i].vec3 + delta * 0.5)
                self.cl.line[i + 1]:setScale(distance)
                self.cl.line[i + 1]:setRotation(rot)
            else
                self.cl.line[i + 1] = sm.effect.createEffect("ShapeRenderable")
                self.cl.line[i + 1]:setParameter("uuid", sm.uuid.new("628b2d61-5ceb-43e9-8334-a4135566df7a"))
                self.cl.line[i + 1]:setParameter("color", sm.color.new("FF0000"))
            end
        elseif self.cl.line[i + 1] then
            if self.cl.line[i + 1]:isPlaying() then
                self.cl.line[i + 1]:stop()
            end
        end
    end
end

function PathfinderTest.client_onFixedUpdate(self)
    local params = {
        ignore = self.shape:getBody()
    }

    local target = sm.localPlayer.getPlayer().character
    local endPos = target.worldPosition + sm.vec3.new(0, 0, 0.25)
    local startPos = self.shape.worldPosition

    -- start pathfinding on the first obstacle found
    local valid, result = sm.physics.spherecast(startPos, endPos, sphereCastRadus, self.shape.body)
    if not valid or not result:getCharacter() or result:getCharacter().id ~= target.id then
        if valid then
            startPos = result.pointWorld + result.normalWorld * sphereCastRadus * 1.1
        else
            startPos = endPos
        end
    end


    local showPathCallback = function(node)
        if sm.isServerMode() then
            self.network:sendToClients("cl_showPath", { node })
        else
            self:cl_showPath({ node })
        end
    end

    local isValidEndNode = function(node, endNode, params)
        if aStar.distance(node.vec3, endNode.vec3) < nodeDistance then
            return true
        end

        -- check if there is still an obstacle towards the player
        local valid, result = sm.physics.spherecast(node.vec3, endNode.vec3, sphereCastRadus, params.ignore)
        if not valid or result:getCharacter() and result:getCharacter().id == target.id then
            return true
        end
        return false
    end

    local dataTable = self.cl.aStar -- The table where the data will be stored

    local pos = {
        startPos = startPos, -- The Start Pos
        endPos = endPos,     -- The End Pos
        roundPos = false     -- If the coordinates are rounded
    }

    local params = {
        maxLoop = aStar.distance(startPos, endPos), -- Number of iterations per ticks (calculation speed) : influences FPS
        maxOpenSet = 99999999999,                   -- The number of nodes that can be calculated (reaction speed/max complexity) : influences the time before finding a lost target and the maximum complexity of the scan
        isValidEndNode = isValidEndNode,            -- A function that checks if a node is considered valid as a final node, if nil looks if the distance between the target is the final node is less than 1
        isValidEndNodeParams = params,              -- A table send to the isValidEndNode function if necessary
        getNeighborNodes = getNeighborNodes,        -- The function that retrieves valid neighboring nodes
        getNeighborNodesParams = params             -- A table send to the getNeighborNodes function if necessary
    }
    local debug = {
        debugPrint = true,                  -- A little bit of debugging
        showCheckNode = false,              -- Show calculated nodes if showNodeCallback is defined
        showNodeCallback = showPathCallback -- A function that displays all nodes in a table
    }

    local complete, path = aStar.aStar(dataTable, pos, params, debug) -- the magic
    if complete then
        --self:cl_showPath(path)
        self.cl.path = path
        if debug.debugPrint then
            print(self.cl.path and #self.cl.path or nil)
        end
        self:cl_effectShowPath(self.shape.worldPosition, endPos)
    end
end

function PathfinderTest.server_onCreate(self)
end

function PathfinderTest.server_onFixedUpdate(self)
end