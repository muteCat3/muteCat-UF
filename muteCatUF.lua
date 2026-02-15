local addonName, ns = ...
local oUF = ns and ns.oUF
if not oUF then
    return
end

oUF:RegisterStyle(addonName, ns.Style)
oUF:SetActiveStyle(addonName)

oUF:Factory(function(factory)
    local player = factory:Spawn("player", addonName .. "_Player")
    player:SetPoint("CENTER", UIParent, "CENTER", -420, -266)

    local target = factory:Spawn("target", addonName .. "_Target")
    target:SetPoint("CENTER", UIParent, "CENTER", 420, -266)

    local focus = factory:Spawn("focus", addonName .. "_Focus")
    focus:SetPoint("CENTER", UIParent, "CENTER", 420, -226)

    if ns.SetupEditMode and player and target and player.Castbar then
        ns.SetupEditMode(player, target, focus, player.Castbar)
    end

    ns.HideBlizzardUnitFrames()

    local hider = CreateFrame("Frame")
    hider:RegisterEvent("PLAYER_ENTERING_WORLD")
    hider:SetScript("OnEvent", ns.HideBlizzardUnitFrames)

    local vehicleWatcher = CreateFrame("Frame")
    vehicleWatcher:RegisterEvent("UNIT_ENTERED_VEHICLE")
    vehicleWatcher:RegisterEvent("UNIT_EXITED_VEHICLE")
    vehicleWatcher:RegisterEvent("UNIT_DISPLAYPOWER")
    vehicleWatcher:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR")
    vehicleWatcher:RegisterEvent("VEHICLE_UPDATE")
    vehicleWatcher:SetScript("OnEvent", function(_, _, unit)
        if unit and unit ~= "player" then
            return
        end

        if player and player.Power and player.Health then
            player.Power:ForceUpdate()
            player.Health:ForceUpdate()
        end
    end)
end)
