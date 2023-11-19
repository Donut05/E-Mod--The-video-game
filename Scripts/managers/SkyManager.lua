---@diagnostic disable: need-check-nil, undefined-global, undefined-field

SkyManager = class(nil)

-- Sun disappears shortly after 0.8 and disappears after 0.185
-- Moon and sun intentionally have a bit of an overlap for cool screenshot potential
-- Note: This WILL require an update once QMark makes moving sun into a dll plugin
SkyManager.moonStartTime = 0.8 -- When moon loads in
SkyManager.moonEndTime = 0.21  -- When the moon despawns
SkyManager.moonDistance = 1500
SkyManager.moonStartAngle = -5
SkyManager.moonEndAngle = 182
SkyManager.starEndTime = 0.09

function SkyManager.client_onCreate(self)
    self.effects = self.effects or {}
    self.moon = { angle = 0 }
    self.starAngle = 0
    self.effects.moon = sm.effect.createEffect("Skybox - Moon")
    self.effects.stars = sm.effect.createEffect("Skybox - Stars")
    self.effects.ships = sm.effect.createEffect("Skybox - Cargo_ships")
end

local function convertToValue(floatValue, minRange, maxRange)
    local value = 0

    if floatValue >= 0.8 and floatValue <= 1.0 then
        value = minRange + (floatValue - 0.8) * ((maxRange - minRange) / 0.2)
    end

    if floatValue > 0.0 and floatValue <= 0.3 then
        value = maxRange - floatValue * ((-maxRange - minRange) / 0.2)
    end

    return value
end

function SkyManager:client_onFixedUpdate(dt)
    if not self.time then return end

    self.moon.angle = convertToValue(self.time, SkyManager.moonStartAngle, SkyManager.moonEndAngle)
end

function SkyManager.client_onUpdate(self, dt)
    if not sm.localPlayer.getPlayer().character then return end

    self.time = sm.game.getTimeOfDay()

    --------------------
    -- #region Cargo_ship_effect
    --------------------
    if not self.effects.ships:isPlaying() then
        self.effects.ships:start()
    end
    self.effects.ships:setPosition(sm.localPlayer.getPlayer().character.worldPosition)
    -- #endregion

    --------------------
    -- #region Moon_effect
    --------------------
    if self.time > self.moonStartTime or self.time <= self.moonEndTime then
        if not self.effects.moon:isPlaying() then
            self.effects.moon:start()
        end

        local offset_pos = sm.localPlayer.getPlayer().character.worldPosition
        local angle = 1 * (math.pi / 12)
        local rotation = sm.quat.angleAxis(angle, sm.vec3.new(0, 0, 1))
        rotation = rotation * sm.quat.angleAxis(-math.rad(self.moon.angle / 2), sm.vec3.new(0, 1, 0))
        local final_direction = rotation * sm.vec3.new(1, 0, 0) * self.moonDistance

        self.effects.moon:setPosition(offset_pos + final_direction)
    elseif self.time > self.moonEndTime then
        if self.effects.moon:isPlaying() then
            self.effects.moon:stopImmediate()
        end
    end
    -- #endregion

    --------------------
    -- #region Stars_effect
    --------------------
    if self.time > self.moonStartTime or self.time <= self.starEndTime then
        if not self.effects.stars:isPlaying() then
            self.effects.stars:start()
        end
        self.effects.stars:setPosition(sm.localPlayer.getPlayer().character.worldPosition)
    elseif self.time > self.starEndTime then
        if self.effects.stars:isPlaying() then
            self.effects.stars:stop()
        end
    end
    if self.time > self.moonStartTime or self.time <= self.moonEndTime then
        self.starAngle = self.starAngle + 0.0011
        self.effects.stars:setRotation(sm.quat.angleAxis((self.starAngle * (math.pi/180)), sm.vec3.new(0, -1, 0)))
    elseif self.time > self.moonEndTime then
        self.starAngle = 0
    end
    -- #endregion
end

function SkyManager.client_onRefresh(self)

    self.moon.angle = 0
    self.effects.moon:stopImmediate()
    self.effects.moon:destroy()

    self.effects.stars:stopImmediate()
    self.effects.stars:destroy()

    self.effects.ships:stopImmediate()
    self.effects.ships:destroy()

    SkyManager.client_onCreate(self)
end
