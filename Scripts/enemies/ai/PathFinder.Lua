--[[
    I'm too lazy to comment this thing
    but...

    Copyright (C) 2023-2077 Me and ChatGPT, Orion Space Inc. <https://among.us/> + <https://scrapmechanic.com/biker.png>
    Everyone is permitted to copy and distribute verbatim copies
    of this license comment, but changing it is almost not allowed.
    I would still like you to leave a message to prove that I was there, me The Fearless, Sensual, Mysterious, Enchanting, Vigorous, Diligent, Overwhelming, Gorgeous, Passionate, Terrifying, Beautiful, Powerful, Grey Prince Zeldack.
    but if you don't I will send the FBI to your house (I have nothing special to compensate).
]]
--
print("PathFinder.lua")

dofile("$SURVIVAL_DATA/Scripts/util.lua")
-- if aStar then return end

---@diagnostic disable-next-line: lowercase-global
aStar = aStar or {}

function math.round(x)
    if x % 2 ~= 0.5 then
        return math.floor(x + 0.5)
    end
    return x - 0.5
end

function aStar.vectorRound(vec3)
    return sm.vec3.new(math.round(vec3.x), math.round(vec3.y), math.round(vec3.z))
end

function aStar.tableInIndex(t)
    local finalT = {}
    for _, value in pairs(t) do
        finalT[#finalT + 1] = value
    end
    return finalT
end

function aStar.vectorId(vec3)
    return vec3.x .. ";" .. vec3.y .. ";" .. vec3.z
end

function aStar.vectorToNode(vec3)
    return {
        id = aStar.vectorId(vec3),
        vec3 = vec3
    }
end

function aStar.distance(a, b)
    return (a - b):length()
end

function aStar.heuristicCostEstimate(a, b)
    return aStar.distance(a, b)
end

function aStar.count(t)
    local c = 0
    for _, __ in pairs(t) do
        c = c + 1
    end
    return c
end

function aStar.aStar(selfTable, pos, params, debug)
    selfTable.ticks = selfTable.ticks or 0
    selfTable.ticks = selfTable.ticks + 1
    local startNode = aStar.vectorToNode(pos.startPos) -- aStar.vectorToNode(aStar.vectorRound(start))
    local goalNode = aStar.vectorToNode(pos.endPos)    -- aStar.vectorToNode(aStar.vectorRound(goal))
    if pos.roundPos then
        startNode = aStar.vectorToNode(aStar.vectorRound(pos.startPos))
        goalNode = aStar.vectorToNode(aStar.vectorRound(pos.endPos))
    end

    if selfTable.ticks <= 1 then
        selfTable.closedset = {}                           -- The set of nodes already evaluated.
        selfTable.openset = { [startNode.id] = startNode } -- The set of tentative nodes to be evaluated, initially containing the start node
        selfTable.came_from = {}                           -- The map of navigated nodes.

        selfTable.g_score = {}
        selfTable.g_score[startNode.id] = 0 -- Cost from start along best known path.
        -- Estimated total cost from start to goal through y.
        selfTable.f_score = {}
        selfTable.f_score[startNode.id] = selfTable.g_score[startNode.id] +
            aStar.heuristicCostEstimate(startNode.vec3, goalNode.vec3)
    end

    if selfTable.openset and aStar.count(selfTable.openset) > params.maxOpenSet then
        selfTable.ticks = 0
        if debug.debugPrint then print("openset out of range") end
        return true, nil
    end

    local whileBreakCount = 0


    while selfTable.openset and aStar.count(selfTable.openset) > 0 do
        if whileBreakCount > params.maxLoop then
            return false, nil
        end
        whileBreakCount = whileBreakCount + 1

        local current = aStar.tableInIndex(selfTable.openset)
            [1] -- the node in openset having the lowest selfTable.f_score[] value
        for k, node in pairs(selfTable.openset) do
            if selfTable.f_score[current.id] > selfTable.f_score[node.id] then
                current = node
            end
        end
        if debug.showCheckNode then
            debug.showNodeCallback(current)
        end

        -- local sValid, sResult = sm.physics.spherecast( current.vec3, goalNode.vec3, 0.35, ignore )
        -- local canReach = not (sValid and sResult.type ~= "Character")
        local canReach = true
        if (not params.isValidEndNode and canReach and (aStar.distance(current.vec3, goalNode.vec3) < 1)) or (params.isValidEndNode and params.isValidEndNode(current, goalNode, params.isValidEndNodeParams)) then
            local path = aStar.reconstructPath(selfTable.came_from, current)
            path[#path + 1] = goalNode
            if debug.debugPrint then
                print("path found : " ..
                    aStar.count(path) ..
                    " nodes, in " ..
                    selfTable.ticks ..
                    " ticks, " ..
                    aStar.count(selfTable.openset) ..
                    "/" .. params.maxOpenSet .. " openset, " .. aStar.count(selfTable.closedset) .. " closedset")
            end
            selfTable.ticks = 0
            return true, path
        end

        selfTable.openset[current.id] = nil
        selfTable.closedset[current.id] = current

        for k, neighborNode in pairs(params.getNeighborNodes(current, startNode, params.getNeighborNodesParams or {})) do
            if not selfTable.closedset[neighborNode.id] then
                local tentative_g_score = selfTable.g_score[current.id] + aStar.distance(current.vec3, neighborNode.vec3)
                if (not selfTable.openset[neighborNode.id] or tentative_g_score < selfTable.g_score[neighborNode.id]) then
                    selfTable.came_from[neighborNode.id] = current
                    selfTable.g_score[neighborNode.id] = tentative_g_score
                    selfTable.f_score[neighborNode.id] = selfTable.g_score[neighborNode.id] +
                        aStar.heuristicCostEstimate(neighborNode.vec3, goalNode.vec3)
                    if not selfTable.openset[neighborNode.id] then
                        selfTable.openset[neighborNode.id] = neighborNode
                    end
                end
            end
        end
    end
    if debug.debugPrint then print("No path found") end
    selfTable.ticks = 0
    return true, nil
end

function aStar.reconstructPath(came_from, current_node)
    -- print("came_from",count(came_from))
    local cNod = current_node
    local p = { cNod }
    while came_from[cNod.id] do
        -- print("came_from node")
        cNod = came_from[cNod.id]
        p[#p + 1] = cNod
    end
    local fp = {}
    ---@diagnostic disable-next-line: undefined-global
    for i, value in reverse_ipairs(p) do
        fp[#fp + 1] = value
    end
    return fp
end