---@diagnostic disable: need-check-nil, undefined-field

HudManager = class(nil)

local SS_frame, FG_frame, DAT_meme_tick = 1, 1, -2000

local function getCurrentDateTime()
    local currentTime = os.time()
    local epoch = 1970
    local secondsInMinute = 60
    local secondsInHour = 3600
    local secondsInDay = 86400
    local currentYear = epoch + math.floor(currentTime / (365 * secondsInDay))
    local yearStartSeconds = os.time({ year = currentYear, month = 1, day = 1, hour = 0, min = 0, sec = 0 })
    local secondsInCurrentYear = currentTime - yearStartSeconds
    local months = { "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" }
    local currentMonth = 1
    while currentMonth < 12 and secondsInCurrentYear >= (30.4375 * secondsInDay) do
        secondsInCurrentYear = secondsInCurrentYear - (30.4375 * secondsInDay)
        currentMonth = currentMonth + 1
    end
    local currentDay = math.floor(secondsInCurrentYear / secondsInDay) + 1
    local currentHour = math.floor((secondsInCurrentYear % secondsInDay) / secondsInHour)
    print(secondsInCurrentYear)
    print(secondsInDay)
    print(secondsInHour)
    local currentMinute = math.floor((secondsInCurrentYear % secondsInHour) / secondsInMinute)

    local function getDaySuffix(day)
        local suffixes = { "st", "nd", "rd" }
        local suffix = "th"
        if day % 100 < 11 or day % 100 > 13 then
            suffix = suffixes[day % 10] or "th"
        end
        return suffix
    end

    local calendar = {
        year = tostring(currentYear),
        month = months[currentMonth],
        day = tostring(currentDay) .. getDaySuffix(currentDay),
        hour = string.format("%02d", currentHour),
        minute = string.format("%02d", currentMinute)
    }

    return calendar
end

function HudManager.client_onCreate(self)
    self.lastTick = sm.game.getCurrentTick()
    -- ANIMATED HUDS INIT --
    local settings = {
        isHud = true,
        isInteractive = false,
        needsCursor = false,
        hidesHotbar = false,
        isOverlapped = false,
        backgroundAlpha = 0
    }
    self.funnyHUDswitch = true
    self.counter = 0
    self.phoneHUD = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/Layouts/PhoneHud.layout", false, settings)
    self.TvHUD = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/Layouts/TVHud.layout", false, settings)
    self.phoneHUD:setImage("Iphone", "$CONTENT_DATA/Gui/Images/Ui/memes/iphone.png")
    self.TvHUD:setImage("TV", "$CONTENT_DATA/Gui/Images/Ui/memes/TV.png")
    self.phoneHUD:open()
    self.TvHUD:open()
                        -- STATIC HUDS INIT --
    -- These do not take up much RAM, so we ingore the setting --
    self.dateTimeHUD = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/Layouts/DateAndTimeMemeHUD.layout", false, settings)
    self.dateTimeHUD:setImage("Meme", "$CONTENT_DATA/Gui/Images/Ui/memes/pc.jpg")
              -- CHAT MESSAGE --
    -- !Remove when main menu is added! --
    sm.gui.chatMessage("Use /switchHUD to toggle custom HUD elements!")
end

function HudManager.client_onFixedUpdate(self, dt)
    -- RANDOM CHANCE GUIS --
    if sm.game.getCurrentTick() >= self.lastTick + 1200 then --Roll for a random event every 30 seconds
        --Reset timer
        self.lastTick = sm.game.getCurrentTick()
        --Date and time meme
        if math.random(0, 50) == 0 then
            if not self.dateTimeHUD:isActive() then
                local calendar = getCurrentDateTime()
                self.dateTimeHUD:setText("Month", calendar.month)
                self.dateTimeHUD:setText("Day", calendar.day)
                self.dateTimeHUD:setText("Year", calendar.year)
                self.dateTimeHUD:setText("Time", (calendar.hour .. ":" .. calendar.minute))
                self.dateTimeHUD:open()
                if sm.cae_injected then
                    local data = {
                        effectName = "Sounds - Undertale_shop_date_and_time_meme",
                        worldPosition = sm.localPlayer.getPlayer().character.worldPosition
                    }
                    sm.event.sendToPlayer(sm.localPlayer.getPlayer(), "cl_playEffect", data)
                end
                DAT_meme_tick = sm.game.getCurrentTick()
            end
        end
    end
    if sm.game.getCurrentTick() >= DAT_meme_tick + 480 then
        if self.dateTimeHUD:isActive() then
            self.dateTimeHUD:close()
        end
    end
    -- PUT ALL ANIMATED GUIS BELOW --
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