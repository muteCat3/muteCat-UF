local addonName, ns = ...

ns.config = {
    addonName = addonName,
    classColors = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS,

    frameWidth = 240,
    frameHeight = 39,
    powerHeight = 2,
    castbarHeight = 22,
    castbarWidth = 200,
    castbarCenterX = 0,
    castbarCenterY = 0,
    innerPadding = 1,

    barTexture = "Interface\\AddOns\\" .. addonName .. "\\Media\\Textures\\DF_Soft.tga",
    combatIcon = "Interface\\AddOns\\" .. addonName .. "\\Media\\Textures\\Status\\Combat\\Combat0.tga",
    restingIcon = "Interface\\AddOns\\" .. addonName .. "\\Media\\Textures\\Status\\Resting\\Resting0.tga",

    healthForeground = { 0.19607845, 0.19607845, 0.19607845, 1 },
    healthBackground = { 0.56470591, 0.16078432, 0.23921570, 0.8 },
    vehiclePowerColor = { 0.18, 0.72, 1.0, 1 },
}

ns.config.healthHeightWithPower = ns.config.frameHeight - ns.config.powerHeight - (ns.config.innerPadding * 2)
ns.config.healthHeightNoPower = ns.config.frameHeight - (ns.config.innerPadding * 2)

ns.hiddenParent = CreateFrame("Frame")
ns.hiddenParent:Hide()
