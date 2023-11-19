---@diagnostic disable: need-check-nil, undefined-global, undefined-field

WeatherManager = class(nil)

function WeatherManager.client_onCreate(self)
    self.rainSoundInsideVolume = 0
    self.rainSoundVolume = 0
    self.rain = sm.effect.createEffect("Environment - Rain")
    self.fakeRain = sm.effect.createEffect("Environment - Rain_fake")
    if sm.cae_injected then
        self.rainSound = sm.effect.createEffect("Environment - Rain_sound_DLL")
        self.rainSoundInside = sm.effect.createEffect("Environment - Rain_sound_inside_DLL")
        self.rainSound:setParameter("CAE_Volume", self.rainSoundVolume)
        self.rainSoundInside:setParameter("CAE_Volume", self.rainSoundInsideVolume)
    else
        self.rainSound = sm.effect.createEffect("Environment - Rain_sound_noDLL")
    end
end

function WeatherManager.client_onUpdate(self, dt)
    if self.rainSwitch then
        local player = sm.localPlayer.getPlayer()
        local rainPos = sm.vec3.new(player.character.worldPosition.x, player.character.worldPosition.y, 0) + sm.vec3.new(player.character.velocity.x, player.character.velocity.y, 0)
        self.rain:setPosition(rainPos)
        self.fakeRain:setPosition(rainPos)
        local hit, result = sm.physics.raycast(player.character.worldPosition, player.character.worldPosition + sm.vec3.new(0, 0, 100))
        local hit2, hit3, hit4, hit5, hit_rainHeightLimitCheck, trash
        hit2, trash = sm.physics.raycast(player.character.worldPosition, player.character.worldPosition + sm.vec3.new(100, 0, 0))
        hit3, trash = sm.physics.raycast(player.character.worldPosition, player.character.worldPosition + sm.vec3.new(-100, 0, 0))
        hit4, trash = sm.physics.raycast(player.character.worldPosition, player.character.worldPosition + sm.vec3.new(0, 100, 0))
        hit5, trash = sm.physics.raycast(player.character.worldPosition, player.character.worldPosition + sm.vec3.new(0, -100, 0))
        hit_rainHeightLimitCheck, trash = sm.physics.raycast(player.character.worldPosition, player.character.worldPosition + sm.vec3.new(0, 0, 14)) --Addtional height check for buildings bigger than the rain effect
        if hit and hit2 and hit3 and hit4 and hit5 then
            if not hit_rainHeightLimitCheck then
                self.rain:stopImmediate()
                self.fakeRain:stopImmediate()
            end
            if sm.cae_injected then
                --Update inside ambient sound position
                self.rainSoundInside:setPosition(result.pointWorld + sm.vec3.new(0, 0, 2))
                --Lower outside ambient sound volume
                if self.rainSoundVolume > 0 then
                    self.rainSound:setParameter("CAE_Volume", self.rainSoundVolume)
                    self.rainSoundVolume = self.rainSoundVolume - 0.005
                elseif self.rainSoundVolume <= 0 then
                    self.rainSoundVolume = 0
                    self.rainSound:setParameter("CAE_Volume", self.rainSoundVolume) --Even though nothing bad should happen with negative volume, set it to 0 just in case because who the fuck knows
                    self.rainSound:stopImmediate()
                end
                --Boost inside ambient sound volume
                if self.rainSoundInsideVolume >= 1 then
                    self.rainSoundInsideVolume = 1
                    self.rainSoundInside:setParameter("CAE_Volume", self.rainSoundInsideVolume) --Set one more time to avoid ear rape
                elseif self.rainSoundInsideVolume < 1 then
                    self.rainSoundInside:setParameter("CAE_Volume", self.rainSoundInsideVolume)
                    self.rainSoundInsideVolume = self.rainSoundInsideVolume + 0.005
                end
            else
                self.rainSound:setPosition(result.pointWorld + sm.vec3.new(0, 0, 2))
                if not self.rainSound:isPlaying() then
                    self.rainSound:start()
                end
            end
            if sm.cae_injected then
                if self.rainSoundInside:isDone() or not self.rainSoundInside:isPlaying() then --This code loops the sound
                    self.rainSoundInside:start()
                end
            end
        else
            --Update outside ambient sound position
            self.rainSound:setPosition(player.character.worldPosition + sm.vec3.new(0, 0, 0.5))
            if sm.cae_injected then
                --Lower inside ambient sound volume
                if self.rainSoundInsideVolume > 0 then
                    self.rainSoundInside:setParameter("CAE_Volume", self.rainSoundInsideVolume)
                    self.rainSoundInsideVolume = self.rainSoundInsideVolume - 0.005
                elseif self.rainSoundInsideVolume <= 0 then
                    self.rainSoundInsideVolume = 0
                    self.rainSoundInside:setParameter("CAE_Volume", self.rainSoundVolume)
                    self.rainSoundInside:stopImmediate()
                end
                --Boost outside ambient sound volume
                if self.rainSoundVolume >= 1 then
                    self.rainSoundVolume = 1
                    self.rainSound:setParameter("CAE_Volume", self.rainSoundVolume)
                elseif self.rainSoundVolume < 1 then
                    self.rainSound:setParameter("CAE_Volume", self.rainSoundVolume)
                    self.rainSoundVolume = self.rainSoundVolume + 0.005
                end
            end
            if self.rainSound:isDone() or not self.rainSound:isPlaying() then --This code loops the sound
                self.rainSound:start()
            end
            if not self.rain:isPlaying() then --Turn rain back on if we were in a building higher than the effect
                self.rain:start()
            end
            if not self.fakeRain:isPlaying() then
                self.fakeRain:start()
            end
        end
    else
        if sm.cae_injected then
            if self.rainSoundVolume > 0 then
                self.rainSound:setParameter("CAE_Volume", self.rainSoundVolume)
                self.rainSoundVolume = self.rainSoundVolume - 0.005
            elseif self.rainSoundVolume <= 0 then
                self.rainSoundVolume = 0
                self.rainSound:setParameter("CAE_Volume", self.rainSoundVolume)
                self.rainSound:stopImmediate()
            end
            if self.rainSoundInsideVolume > 0 then
                self.rainSoundInside:setParameter("CAE_Volume", self.rainSoundInsideVolume)
                self.rainSoundInsideVolume = self.rainSoundInsideVolume - 0.005
            elseif self.rainSoundInsideVolume <= 0 then
                self.rainSoundInsideVolume = 0
                self.rainSoundInside:setParameter("CAE_Volume", self.rainSoundVolume)
                self.rainSoundInside:stopImmediate()
            end
        else
            self.rainSound:stop()
        end
    end
end

function WeatherManager.sv_toggle_rain(self)
    self.network:sendToClients("cl_toggle_rain")
end

function WeatherManager.cl_toggle_rain(self)
    self.rainSwitch = not self.rainSwitch
    if self.rainSwitch then
        self.rain:start()
        self.fakeRain:start()
    else
        self.rain:stop()
        self.fakeRain:stop()
    end
    print(self.rainSwitch)
end

function WeatherManager.client_onRefresh(self)
    WeatherManager.client_onCreate(self)
end