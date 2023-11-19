---@diagnostic disable: need-check-nil

Amogus = class(nil)

function Amogus.client_onCreate(self)
	self.effect = sm.effect.createEffect("Amogus - Twerk", self.interactable)
end

function Amogus.client_onUpdate(self, dt)
	if self.effect ~= nil then
		if not self.effect:isPlaying() then
			self.effect:start()
		end
	else
		self.effect = sm.effect.createEffect("Amogus - Twerk", self.interactable)
	end
end

function Amogus.client_onDestroy(self)
	self.effect:stop()
end
