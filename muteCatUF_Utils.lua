
local _, ns = ...
local cfg = ns.config

-- Cache global references for performance
local classColors         = cfg.classColors
local vehiclePowerColor   = cfg.vehiclePowerColor
local NEUTRAL_REACTION    = { r = 254 / 255, g = 227 / 255, b = 66 / 255 }
local HOSTILE_REACTION    = { r = 144 / 255, g = 41 / 255,  b = 61 / 255 }

-- Midnight "Secret Numbers" detection (WoW 12.0.1+)
local isSecretValue = issecretvalue or function() return false end

-- =============================================================================
-- UTILITY FUNCTIONS
-- =============================================================================

--- Checks if a value is accessible or hidden by Blizzard's new "Secret Number" API.
--- @param value any
--- @return boolean
function ns.CanAccessValue(value)
    return value ~= nil and not isSecretValue(value)
end

--- Validates if a resource value (HP, Mana) is greater than zero and accessible.
--- @param value number
--- @return boolean
function ns.HasVisiblePower(value)
    if not ns.CanAccessValue(value) then return false end
    return value > 0
end

--- Formats large numbers into a shorter, readable string (e.g., 10.5M).
--- @param value number
--- @return string
function ns.ShortValue(value)
    if not value then return "0" end
    
    if AbbreviateNumbers then
        local ok, abbr = pcall(AbbreviateNumbers, value)
        if ok and abbr then return abbr end
    end

    local ok, text = pcall(BreakUpLargeNumbers, value)
    if ok and text then return text end

    return tostring(value)
end

--- Checks if the player is currently in a vehicle UI or physically in a vehicle.
--- @return boolean
function ns.IsPlayerInVehicle()
    return UnitHasVehicleUI("player") or UnitInVehicle("player")
end

--- Gets the RGB color components for a unit's class.
--- @param unit string
--- @return number, number, number
function ns.GetClassColor(unit)
    local _, class = UnitClass(unit)
    local color = class and classColors and classColors[class]
    if color then return color.r, color.g, color.b end
    return 1, 1, 1 -- Fallback to White
end

--- Gets the RGB color for a unit nameplate based on player status or reaction.
--- @param unit string
--- @return number, number, number
function ns.GetNameColor(unit)
    if UnitIsPlayer(unit) then
        return ns.GetClassColor(unit)
    end

    local reaction = UnitReaction(unit, "player")
    if reaction then
        if reaction <= 3 then return HOSTILE_REACTION.r, HOSTILE_REACTION.g, HOSTILE_REACTION.b end
        if reaction == 4 then return NEUTRAL_REACTION.r, NEUTRAL_REACTION.g, NEUTRAL_REACTION.b end
        
        local factionColor = FACTION_BAR_COLORS[reaction]
        if factionColor then return factionColor.r, factionColor.g, factionColor.b end
    end

    return 1, 1, 1 -- Fallback to White
end

--- Updates the status bar color based on the unit's class or vehicle status.
--- Optimized to prevent redundant color updates.
--- @param power StatusBar
--- @param unit string
function ns.SetPowerColor(power, unit)
    if not power then return end

    -- Handle Vehicle Overrides
    if unit == "player" and ns.IsPlayerInVehicle() then
        if power.__mcPowerColorKey == "vehicle" then return end
        power.__mcPowerColorKey = "vehicle"
        power:SetStatusBarColor(unpack(vehiclePowerColor))
        return
    end

    -- Regular Class Colors
    local _, class = UnitClass(unit)
    local color = class and classColors and classColors[class]
    
    if color then
        if power.__mcPowerColorKey == class then return end
        power.__mcPowerColorKey = class
        power:SetStatusBarColor(color.r, color.g, color.b, 1)
    else
        -- Fallback for Unknown/NPC Power
        if power.__mcPowerColorKey == "fallback" then return end
        power.__mcPowerColorKey = "fallback"
        power:SetStatusBarColor(0.4, 0.4, 0.4, 1)
    end
end
