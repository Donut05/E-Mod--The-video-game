---@diagnostic disable: undefined-doc-param
---@class VisualizedTrigger
---@field trigger AreaTrigger
---@field effect Effect
---@field setPosition function
---@field setRotation function
---@field setScale function
---@field destroy function
---@field setVisible function
---@field show function
---@field hide function

---Create an AreaTrigger that has a visualization
---@param position Vec3 position of the trigger in the world
---@param scale Vec3 scale of the trigger
---@param filter integer filters for the trigger, see sm.areaTrigger.filter
---@return VisualizedTrigger

function CreateVisualizedTrigger(position, scale, filter)
    local effect = sm.effect.createEffect("ShapeRenderable")
    effect:setParameter("uuid", sm.uuid.new("5f41af56-df4c-4837-9b3c-10781335757f"))
    effect:setParameter("visualization", true)
    effect:setScale(scale)
    effect:setPosition(position)
    effect:start()

    if not filter then
        filter = 34319
    end

    return {
        trigger = sm.areaTrigger.createBox(scale * 0.5, position, sm.quat.identity(), filter),
        effect = effect,
        setPosition = function(self, position)
            self.trigger:setWorldPosition(position)
            self.effect:setPosition(position)
        end,
        setRotation = function(self, rotation)
            self.trigger:setWorldRotation(rotation)
            self.effect:setRotation(rotation)
        end,
        setScale = function(self, scale)
            self.trigger:setSize(scale * 0.5)
            self.effect:setScale(scale)
        end,
        destroy = function(self)
            sm.areaTrigger.destroy(self.trigger)
            self.effect:destroy()
        end,
        setVisible = function(self, state)
            if state then
                self.effect:start()
            else
                self.effect:stop()
            end
        end,
        show = function(self)
            self.effect:start()
        end,
        hide = function(self)
            self.effect:stop()
        end
    }
end