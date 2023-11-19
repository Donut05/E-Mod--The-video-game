---@diagnostic disable: need-check-nil
---@class Grab : ToolClass

Grab = class()

---@diagnostic disable-next-line: unbalanced-assignments
local grabbing, mass, gui, previousBody = false, 0

function Grab.client_onCreate(self)
    gui = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/Layouts/GrabHandHud.layout", false, {
        isHud = true,
        isInteractive = false,
        needsCursor = false,
        hidesHotbar = false,
        isOverlapped = false,
        backgroundAlpha = 0
    })
end

local function GetBodyMass(result)
    local totalWeight = 0
    local shapes = result:getBody():getShapes()
    for _, shape in ipairs(shapes) do
        totalWeight = totalWeight + shape:getMass()
    end
    return totalWeight
end

function Grab.client_onEquip(self, animate)
    if sm.exists(gui) then
        gui:open()
    end
end

function Grab.client_onUnequip(self, animate)
    if sm.exists(gui) then
        gui:close()
    end
end

function Grab.client_onEquippedUpdate(self, primaryState, secondaryState, forceBuild)
    ---@diagnostic disable-next-line: undefined-field
    local hit, result = sm.physics.spherecast(sm.localPlayer.getRaycastStart(), sm.localPlayer.getRaycastStart() + sm.localPlayer.getDirection() * 2, 0.5, self.tool:getOwner().character)
    if primaryState == 2 and hit and result.type == "body" and not (result:getBody():isStatic()) and GetBodyMass(result) < 1000 then
        grabbing = true
        if not previousBody then
            previousBody = result:getBody()
            mass = GetBodyMass(result)
        else
            if previousBody ~= result:getBody() then
                previousBody = result:getBody()
                mass = GetBodyMass(result)
            end
        end
    elseif not hit and not grabbing then
        if sm.exists(gui) then
            gui:setImage("HandIcon", "$CONTENT_DATA/Gui/Images/empty.png")
        end
    elseif hit and not grabbing and result.type == "body" then
        gui:setImage("HandIcon", "$CONTENT_DATA/Gui/Images/Ui/hand-open-icon.png")
    else
        grabbing = false
    end
    if primaryState == 2 and hit and result.type == "body" and not (result:getBody():isStatic()) and GetBodyMass(result) > 1000 then
        gui:setImage("HandIcon", "$CONTENT_DATA/Gui/Images/Ui/hand-heavy-icon.png")
    end

    return true, false
end

function Grab.client_onFixedUpdate(self, dt)
    if grabbing and sm.exists(previousBody) and mass ~= nil and sm.exists(gui) then
        if mass < 1000 then
            gui:setImage("HandIcon", "$CONTENT_DATA/Gui/Images/Ui/hand-grab-icon.png")
            local CooM = previousBody:getCenterOfMassPosition()
            local FinalDestination = sm.camera.getPosition() + sm.camera.getDirection() * 2
            local Direction = FinalDestination - CooM
            sm.physics.applyImpulse(previousBody, (Direction * mass) - (previousBody:getVelocity() * (mass * 0.25)), true)
            if Direction:length() > 10 then
                grabbing = false
            end
        end
    end
end

function Grab.client_onDestroy(self)
    if sm.exists(gui) then
        gui:close()
        gui:destroy()
    end
end

function Grab.client_onRefresh(self)
    Grab.client_onCreate(self)
end