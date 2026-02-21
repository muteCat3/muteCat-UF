
local addonName, ns = ...

-- =============================================================================
-- MUTE CAT UNIT FRAMES CONFIGURATION
-- =============================================================================

ns.config = {
    -- Basic Addon Info
    addonName = addonName,
    
    -- Branding & Styling Colors
    classColors = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS,
    healthForeground = { 0.196, 0.196, 0.196, 1 },      -- Dark Gray for health text contrast
    healthBackground = { 0.565, 0.161, 0.239, 0.8 },    -- Muted Deep Red/Berry
    vehiclePowerColor = { 0.18, 0.72, 1.0, 1 },         -- Mana Blue for vehicles
    
    -- Unit Frame Dimensions
    frameWidth     = 240,
    frameHeight    = 39,
    powerHeight    = 2,
    innerPadding   = 1,
    
    -- Castbar Settings
    castbarHeight  = 22,
    castbarWidth   = 200,
    castbarCenterX = 0,
    castbarCenterY = 0,
    
    -- Secondary Resource Bar (Combo Points, Holy Power, etc.)
    secondaryBarWidth         = 200,
    secondaryBarHeight        = 15,
    secondaryTickThickness    = 2,
    secondaryBorderThickness  = 1,
    secondaryHideInVehicle    = true,
    secondaryHideMountedOutsideInstance = true,
    
    -- Media Assets (Icons & Textures)
    barTexture  = [[Interface\AddOns\]] .. addonName .. [[\Media\Textures\DF_Soft.tga]],
    combatIcon  = [[Interface\AddOns\]] .. addonName .. [[\Media\Textures\Status\Combat\Combat0.tga]],
    restingIcon = [[Interface\AddOns\]] .. addonName .. [[\Media\Textures\Status\Resting\Resting0.tga]],
}

-- =============================================================================
-- DERIVED SETTINGS
-- =============================================================================

-- Calculate Health Bar heights based on whether the power bar is shown
ns.config.healthHeightWithPower = ns.config.frameHeight - ns.config.powerHeight - (ns.config.innerPadding * 2)
ns.config.healthHeightNoPower   = ns.config.frameHeight - (ns.config.innerPadding * 2)

-- Centralized Hidden Parent for Blizzard frames
ns.hiddenParent = CreateFrame("Frame")
ns.hiddenParent:Hide()

-- Global access to config (optional, for other modules)
_G["muteCatUF_Config"] = ns.config
