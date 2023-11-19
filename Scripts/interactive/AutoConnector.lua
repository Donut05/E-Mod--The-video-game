---@diagnostic disable: need-check-nil, lowercase-global
---@class Connector : ShapeClass

dofile("$CONTENT_DATA/Scripts/visualised_trigger.lua")

Connector = class(nil)
Connector.maxParentCount = 1
Connector.connectionInput = sm.interactable.connectionType.logic
Connector.colorNormal = sm.color.new("f1ca06")
Connector.colorHighlight = sm.color.new("f6e857")

local defaultDir = sm.vec3.new(0, 0, 1)
local segments = 14
local previousTick = sm.game.getCurrentTick()
local trigger = nil --Becuase fuck this

function Connector.client_onCreate(self)
    self.pointer = sm.effect.createEffect("Connector - Pointer", self.interactable)
    self.start = sm.vec3.zero()
    self.effects = {}
    for i = 1, segments do
        if i == 1 then
            self.effects[i] = sm.effect.createEffect("Connector - Connection_first")
        elseif i == segments then
            self.effects[i] = sm.effect.createEffect("Connector - Connection_last")
        else
            self.effects[i] = sm.effect.createEffect("Connector - Connection")
        end
    end
end

function Connector.client_onUpdate(self, dt)
    local parent = self.interactable:getSingleParent()
    if not parent then
        self.pointer:stop()
        for j = 1, #self.effects do
            self.effects[j]:stopImmediate()
        end
        return
    end

    if parent:isActive() then
        if not self.pointer:isPlaying() then
            self.pointer:start()
        end
    else
        self.pointer:stop()
    end

    local pos = self.interactable:getWorldBonePosition("pipe")
    local pos2 = self.interactable.shape:transformLocalPoint(sm.vec3.new(0, 0.2, 2.72))
    local sucess, result = sm.physics.raycast(pos, pos2)
    if sucess then
        if result.type == "body" then
            if not trigger then
                print("DF")
                trigger = CreateVisualizedTrigger(result.pointWorld, sm.vec3.new(0.1, 0.1, 0.1))--sm.areaTrigger.createBox(sm.vec3.new(0.1, 0.1, 0.1), result.pointWorld)
            end
            if previousTick + 10 == sm.game.getCurrentTick() then
                previousTick = sm.game.getCurrentTick()
                if trigger then
                    print(trigger:getContents())
                    if #trigger:getContents() == 1 then
                        print(trigger:getContents()[1])
                        --print(_G[sm.item.getFeatureData(result:getShapes()[1].interactable.shape.uuid).classname].connectionOutput)
                    end
                end
                if sm.exists(trigger) then
                    sm.areaTrigger.destroy(trigger)
                    trigger = nil
                end
            end
        end
    end

    --if self.interactable.shape.body:isStatic() then return end

    self._end = self.interactable:getWorldBonePosition("pipe")
    for i = 1, segments do
        self.effects[i]:setPosition(sm.vec3.lerp(self.start, self._end, i / segments))
        self.effects[i]:setRotation(sm.vec3.getRotation(defaultDir, self._end - self.start))
        self.effects[i]:setParameter("Color", self.shape:getColor())
        if not self.effects[i]:isPlaying() then self.effects[i]:start() end
    end
end

function Connector.client_onRefresh(self)
    Connector.client_onCreate(self)
    if sm.exists(trigger) then
        sm.areaTrigger.destroy(trigger)
        trigger = nil
    end
end
