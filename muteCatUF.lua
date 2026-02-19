
local addonName, ns = ...
local oUF = ns and ns.oUF
if not oUF then return end

-- =============================================================================
-- MUTE CAT UNIT FRAMES: CORE INITIALIZATION
-- =============================================================================

-- Register our custom style with oUF
oUF:RegisterStyle(addonName, ns.Style)
oUF:SetActiveStyle(addonName)

-- Spawn the main frame group
oUF:Factory(function(factory)
    -- [1] Primary Frames
    local player = factory:Spawn("player", addonName .. "_Player")
    player:SetPoint("CENTER", UIParent, "CENTER", -420, -266)

    local target = factory:Spawn("target", addonName .. "_Target")
    target:SetPoint("CENTER", UIParent, "CENTER", 420, -266)

    local focus  = factory:Spawn("focus",  addonName .. "_Focus")
    focus:SetPoint("CENTER", UIParent, "CENTER", 420, -226)

    -- [2] Edit Mode Integration
    if ns.SetupEditMode and player and target and player.Castbar then
        ns.SetupEditMode(player, target, focus, player.Castbar, player.SecondaryResourceBar)
    end

    -- [3] Blizzard Frame Suppression
    ns.HideBlizzardUnitFrames()

    -- Ensure frames stay hidden across zoning/loading
    local loginHider = CreateFrame("Frame")
    loginHider:RegisterEvent("PLAYER_ENTERING_WORLD")
    loginHider:SetScript("OnEvent", ns.HideBlizzardUnitFrames)

    -- [4] Vehicle and Power Update Watcher
    -- Handles UI updates when entering vehicles or when power types sync
    local eventWatcher = CreateFrame("Frame")
    local events = {
        "UNIT_ENTERED_VEHICLE",
        "UNIT_EXITED_VEHICLE",
        "UNIT_DISPLAYPOWER",
        "UPDATE_VEHICLE_ACTIONBAR",
        "VEHICLE_UPDATE"
    }
    for _, event in ipairs(events) do eventWatcher:RegisterEvent(event) end
    
    eventWatcher:SetScript("OnEvent", function(_, _, unit)
        if unit and unit ~= "player" then return end

        if player and player.Power and player.Health then
            player.Power:ForceUpdate()
            player.Health:ForceUpdate()
        end
    end)
end)
