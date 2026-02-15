local _, ns = ...
local cfg = ns.config
local classColors = cfg.classColors
local vehiclePowerColor = cfg.vehiclePowerColor

local isSecretValue = issecretvalue or function()
    return false
end

function ns.CanAccessValue(value)
    return value ~= nil and not isSecretValue(value)
end

function ns.HasVisiblePower(value)
    if not ns.CanAccessValue(value) then
        return false
    end

    return value > 0
end

function ns.ShortValue(value)
    if AbbreviateNumbers then
        local okAbbr, abbr = pcall(AbbreviateNumbers, value)
        if okAbbr and abbr then
            return abbr
        end
    end

    local ok, text = pcall(BreakUpLargeNumbers, value)
    if ok and text then
        return text
    end

    return tostring(value or 0)
end

function ns.IsPlayerInVehicle()
    return UnitHasVehicleUI("player") or UnitInVehicle("player")
end

function ns.GetClassColor(unit)
    local _, class = UnitClass(unit)
    local color = class and classColors and classColors[class]
    if color then
        return color.r, color.g, color.b
    end

    return 1, 1, 1
end

function ns.GetNameColor(unit)
    if UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        local classColor = class and classColors and classColors[class]
        if classColor then
            return classColor.r, classColor.g, classColor.b
        end
    end

    local reaction = UnitReaction(unit, "player")
    local reactionColor = reaction and FACTION_BAR_COLORS and FACTION_BAR_COLORS[reaction]
    if reactionColor then
        return reactionColor.r, reactionColor.g, reactionColor.b
    end

    return 1, 1, 1
end

function ns.SetPowerColor(power, unit)
    if not power then
        return
    end

    if unit == "player" and ns.IsPlayerInVehicle() then
        local color = vehiclePowerColor
        if power.__mcPowerColorKey == "vehicle" then
            return
        end
        power.__mcPowerColorKey = "vehicle"
        power:SetStatusBarColor(color[1], color[2], color[3], color[4])
        return
    end

    local _, class = UnitClass(unit)
    local color = class and classColors and classColors[class]
    if color then
        local key = class
        if power.__mcPowerColorKey == key then
            return
        end
        power.__mcPowerColorKey = key
        power:SetStatusBarColor(color.r, color.g, color.b, 1)
    else
        if power.__mcPowerColorKey == "fallback" then
            return
        end
        power.__mcPowerColorKey = "fallback"
        power:SetStatusBarColor(0.4, 0.4, 0.4, 1)
    end
end
