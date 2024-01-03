---@diagnostic disable: undefined-global

dofile "$SURVIVAL_DATA/Scripts/game/SurvivalPlayer.lua"

---@class Player : PlayerClass
Player = class(SurvivalPlayer)

function Player.server_onCreate(self)
    SurvivalPlayer.server_onCreate(self)
    print("Player.server_onCreate")
end

function Player.client_onCreate(self)
    SurvivalPlayer.client_onCreate(self)
    print("Player.client_onCreate")
end

function Player:server_onExplosion(center, destructionLevel)
    if (self.player.character.worldPosition - center):length() < 2 then
        g_sillyManager:Cl_OnScoreEvent("explode")
    end
end

function Player:cl_playEffect(data)
    sm.effect.playEffect(data.effectName, data.worldPosition)
end