---@diagnostic disable: need-check-nil, undefined-field

HudManager = class(nil)

local SS_frame, FG_frame = 1, 1

function HudManager.client_onCreate(self)
    self.funnyHUDswitch = true
    self.counter = 0
    self.phoneHUD = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/Layouts/PhoneHud.layout", nil, {
        isHud = true,
        isInteractive = false,
        needsCursor = false,
        hidesHotbar = false,
        isOverlapped = false,
        backgroundAlpha = 0
    })
    self.TvHUD = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/Layouts/TVHud.layout", nil, {
        isHud = true,
        isInteractive = false,
        needsCursor = false,
        hidesHotbar = false,
        isOverlapped = true,
        backgroundAlpha = 0
    })
    self.phoneHUD:setImage("Iphone", "$CONTENT_DATA/Gui/Images/Ui/memes/iphone.png")
    self.TvHUD:setImage("TV", "$CONTENT_DATA/Gui/Images/Ui/memes/TV.png")
    self.phoneHUD:open()
    self.TvHUD:open()
end

function HudManager.client_onFixedUpdate(self, dt)
    if not self.funnyHUDswitch then return end
    --SUBWAY_SURFERS_GAMEPLAY
    if SS_frame >= 389 then
        SS_frame = 1
    end
    if SS_frame % 2 == 0 then
        self.phoneHUD:setImage("SS_gameplay", "$CONTENT_DATA/Gui/Images/Ui/memes/SS_gameplay/" .. tostring(SS_frame) .. ".jpg")
    end
    SS_frame = SS_frame + 0.5
    --FAMILY_GUY_TV
    self.counter = self.counter + dt
    if FG_frame >= 14405 then
        FG_frame = 1
    end
    self.TvHUD:setImage("FG", "$CONTENT_DATA/Gui/Images/Ui/memes/FG_clips/" .. tostring(FG_frame) .. ".jpg")
    if self.counter > 0.033 then
        FG_frame = FG_frame + 1
        self.counter = 0
    end
end

function HudManager.cl_switchHUD(self)
    self.funnyHUDswitch = not self.funnyHUDswitch
    if self.funnyHUDswitch then
        self.phoneHUD:open()
        self.TvHUD:open()
    else
        self.phoneHUD:close()
        self.TvHUD:close()
    end
    sm.gui.chatMessage("CUSTOM HUD ADDITIONS ARE " .. (self.funnyHUDswitch and "ON" or "OFF"))
end