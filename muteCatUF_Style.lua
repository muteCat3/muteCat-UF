
--- @class muteCatUF: Namespace
local addonName, ns = ...
local cfg = ns.config
local oUF = ns.oUF
if not oUF then return end

-- =============================================================================
-- CONSTANTS & THEME
-- =============================================================================
local DEFAULT_FONT          = [[Fonts\FRIZQT__.TTF]]
local WHITE_TEXTURE         = [[Interface\Buttons\WHITE8x8]]
local BORDER_COLOR_VALUE    = 0.12156863
local BORDER_THICKNESS      = 1

local PLAYER_CLASS          = select(2, UnitClass("player"))
local PLAYER_CLASS_COLOR    = PLAYER_CLASS and cfg.classColors and cfg.classColors[PLAYER_CLASS]

-- Multi-expansion interpolation handling (Midnight 12.0.1+)
local SMOOTH_INTERPOLATION     = Enum.StatusBarInterpolation.ExponentialEaseOut or Enum.StatusBarInterpolation.Smooth or 1
local IMMEDIATE_INTERPOLATION  = Enum.StatusBarInterpolation.Immediate or 0

-- Paladin Holy Power fallback or native Blizzard color
local HOLY_POWER_COLOR = (PowerBarColor and (PowerBarColor.HOLY_POWER or (Enum.PowerType and PowerBarColor[Enum.PowerType.HolyPower]))) or { r = 0.95, g = 0.9, b = 0.6 }

-- =============================================================================
-- OUF TAGS
-- =============================================================================

--- Abbreviated health tag for native muteCat look.
if not oUF.Tags.Methods["mutecat:curhpabbr"] then
    oUF.Tags.Methods["mutecat:curhpabbr"] = function(unit)
        local value = UnitHealth(unit)
        return ns.ShortValue(value)
    end
    oUF.Tags.Events["mutecat:curhpabbr"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION"
end

-- =============================================================================
-- UTILITY FUNCTIONS
-- =============================================================================

--- Applies class coloring to castbars.
--- @param castbar StatusBar
local function ApplyCastbarClassColor(castbar)
    if PLAYER_CLASS_COLOR then
        castbar:SetStatusBarColor(PLAYER_CLASS_COLOR.r, PLAYER_CLASS_COLOR.g, PLAYER_CLASS_COLOR.b, 1)
    else
        castbar:SetStatusBarColor(HOLY_POWER_COLOR.r, HOLY_POWER_COLOR.g, HOLY_POWER_COLOR.b, 1)
    end
end

--- Aggressively hides a Blizzard frame by unregistering events and hooking Show.
--- @param frame Frame
--- @param flagName string? Unique internal identifier
local function HideFrameForever(frame, flagName)
    if not frame then return end
    local hiddenFlag = flagName or "__mcHiddenSetup"
    if not frame[hiddenFlag] then
        if frame.UnregisterAllEvents then
            frame:UnregisterAllEvents()
        end
        hooksecurefunc(frame, "Show", frame.Hide)
        frame[hiddenFlag] = true
    end
    frame:SetParent(ns.hiddenParent)
    frame:Hide()
end

--- Disables Blizzard Boss Frames via native Edit Mode settings (Midnight API).
local function DisableBossFramesViaEditMode()
    if ns.__mcBossSettingApplied then return end
    if C_EditMode and Enum.EditModeAccountSetting and Enum.EditModeAccountSetting.ShowBossFrames then
        C_EditMode.SetAccountSetting(Enum.EditModeAccountSetting.ShowBossFrames, 0)
        ns.__mcBossSettingApplied = true
    end
end

--- Standardized border creation for unit frames and resources.
--- @param owner table The object to receive the border textures
--- @param parent Frame The parent frame for the textures
--- @param r number? Red
--- @param g number? Green
--- @param b number? Blue
local function CreateFrameBorder(owner, parent, r, g, b)
    local red, green, blue = r or 0, g or 0, b or 0
    local alpha = 0.7
    
    owner.borderTop = parent:CreateTexture(nil, "OVERLAY")
    owner.borderTop:SetTexture(WHITE_TEXTURE)
    owner.borderTop:SetPoint("TOPLEFT", owner, "TOPLEFT", 0, 0)
    owner.borderTop:SetPoint("TOPRIGHT", owner, "TOPRIGHT", 0, 0)
    owner.borderTop:SetHeight(BORDER_THICKNESS)
    owner.borderTop:SetVertexColor(red, green, blue, alpha)

    owner.borderBottom = parent:CreateTexture(nil, "OVERLAY")
    owner.borderBottom:SetTexture(WHITE_TEXTURE)
    owner.borderBottom:SetPoint("BOTTOMLEFT", owner, "BOTTOMLEFT", 0, 0)
    owner.borderBottom:SetPoint("BOTTOMRIGHT", owner, "BOTTOMRIGHT", 0, 0)
    owner.borderBottom:SetHeight(BORDER_THICKNESS)
    owner.borderBottom:SetVertexColor(red, green, blue, alpha)

    owner.borderLeft = parent:CreateTexture(nil, "OVERLAY")
    owner.borderLeft:SetTexture(WHITE_TEXTURE)
    owner.borderLeft:SetPoint("TOPLEFT", owner, "TOPLEFT", 0, 0)
    owner.borderLeft:SetPoint("BOTTOMLEFT", owner, "BOTTOMLEFT", 0, 0)
    owner.borderLeft:SetWidth(BORDER_THICKNESS)
    owner.borderLeft:SetVertexColor(red, green, blue, alpha)

    owner.borderRight = parent:CreateTexture(nil, "OVERLAY")
    owner.borderRight:SetTexture(WHITE_TEXTURE)
    owner.borderRight:SetPoint("TOPRIGHT", owner, "TOPRIGHT", 0, 0)
    owner.borderRight:SetPoint("BOTTOMRIGHT", owner, "BOTTOMRIGHT", 0, 0)
    owner.borderRight:SetWidth(BORDER_THICKNESS)
    owner.borderRight:SetVertexColor(red, green, blue, alpha)
end

-- =============================================================================
-- CASTBAR SYSTEM
-- =============================================================================

local function CastbarPostStart(castbar)
    if ns.RefreshCastbarFromEditMode then ns.RefreshCastbarFromEditMode(castbar) end
    ApplyCastbarClassColor(castbar)
    castbar:SetAlpha(1)
    castbar:Show()
end

local function EnsureCastbarAnchor()
    if ns.CastbarAnchor then return ns.CastbarAnchor end
    local anchor = CreateFrame("Frame", "muteCatUF_CastbarAnchor", UIParent)
    anchor:SetPoint("CENTER", UIParent, "CENTER", cfg.castbarCenterX, cfg.castbarCenterY)
    anchor:SetSize(cfg.castbarWidth + cfg.castbarHeight, cfg.castbarHeight)
    anchor:SetFrameStrata("MEDIUM")
    anchor:EnableMouse(false)
    ns.CastbarAnchor = anchor
    return anchor
end

function ns.ApplyCastbarSize(castbar, width, height)
    if not castbar then return end
    local w = math.max(80, tonumber(width) or cfg.castbarWidth)
    local h = math.max(10, tonumber(height) or cfg.castbarHeight)
    castbar:SetSize(w, h)
    
    if castbar.__mcAnchor then
        castbar:ClearAllPoints()
        castbar:SetPoint("LEFT", castbar.__mcAnchor, "LEFT", h, 0)
        castbar.__mcAnchor:SetSize(w + h, h)
    elseif ns.CastbarAnchor then
        ns.CastbarAnchor:SetSize(w + h, h)
    end
    
    local icon = castbar.IconFrame or castbar.Icon
    if icon then icon:SetSize(h, h) end
end

-- =============================================================================
-- SECONDARY RESOURCE SYSTEM (Class Power)
-- =============================================================================

local secondarySupportedClasses = {
    DEMONHUNTER = true, DRUID = true, EVOKER = true, MAGE = true,
    MONK = true, PALADIN = true, ROGUE = true, SHAMAN = true, WARLOCK = true
}

local function EnsureSecondaryResourceAnchor()
    if ns.SecondaryResourceAnchor then return ns.SecondaryResourceAnchor end
    local anchor = CreateFrame("Frame", "muteCatUF_SecondaryResourceAnchor", UIParent)
    anchor:SetPoint("CENTER", UIParent, "CENTER", 0, -40)
    anchor:SetSize(cfg.secondaryBarWidth, cfg.secondaryBarHeight)
    anchor:SetFrameStrata("MEDIUM")
    ns.SecondaryResourceAnchor = anchor
    return anchor
end

local function SetSecondaryClassPowerColor(element, r, g, b)
    -- FINAL OVERRIDE: If we are in CLASS COLOR mode, do not let anything change it.
    -- This fixes the Hammer of Light / Divine Toll flickering for Paladins.
    if element.__mcClassColorActive and PLAYER_CLASS_COLOR then
        local rc, gc, bc = PLAYER_CLASS_COLOR.r, PLAYER_CLASS_COLOR.g, PLAYER_CLASS_COLOR.b
        -- Always force it, even if no change is detected, to override internal oUF/Blizzard resets
        element.__mcColorR, element.__mcColorG, element.__mcColorB = rc, gc, bc
        for i = 1, #element do
            element[i]:SetStatusBarColor(rc, gc, bc, 1)
        end
        return
    end

    element.__mcColorR, element.__mcColorG, element.__mcColorB = r, g, b
    for i = 1, #element do
        element[i]:SetStatusBarColor(r, g, b, 1)
    end
end

local function WantsSecondaryClassColor(element, cur, max)
    if not PLAYER_CLASS_COLOR then return false, false end
    
    local canEvaluate = ns.CanAccessValue(max) and ns.CanAccessValue(cur)
    
    -- Midnight Memory: Store last known valid max to survive "Secret Number" bursts
    if ns.CanAccessValue(max) and max > 0 then
        element.__mcLastValidMax = max
    end

    if not canEvaluate then
        -- Grace period: if we were full and now get secrets/invalid, stay full for a moment
        return element.__mcClassColorActive, false
    end

    local effectiveMax = element.__mcLastValidMax or max
    local isAtMax = effectiveMax > 0 and cur >= effectiveMax
    
    -- Special Case: Paladins at 5+ HP are always "Full" for UI purposes,
    -- even if Hero Talents mess with the internal max reporting during procs.
    if PLAYER_CLASS == "PALADIN" and cur >= 5 then
        isAtMax = true
    end

    return isAtMax, true
end



local function UpdateSecondaryResourceTicks(container, maxPower)
    if not container then return end
    local maxValue = math.max(0, math.floor(tonumber(maxPower) or 0))
    container.__mcMaxPower = maxValue

    local width = math.floor(container:GetWidth() + 0.5)
    if width <= 0 then return end
    container.__mcActualWidth = width

    if not container.ticks then container.ticks = {} end
    for i = 1, #container.ticks do container.ticks[i]:Hide() end
    if maxValue <= 1 then return end

    local tickParent = container.tickLayer or container
    for i = 1, (maxValue - 1) do
        local tick = container.ticks[i]
        if not tick then
            tick = tickParent:CreateTexture(nil, "OVERLAY", nil, 7)
            tick:SetTexture(WHITE_TEXTURE)
            tick:SetVertexColor(BORDER_COLOR_VALUE, BORDER_COLOR_VALUE, BORDER_COLOR_VALUE, 0.7)
            container.ticks[i] = tick
        end
        local x = math.floor((i * width / maxValue) + 0.5)
        tick:SetPoint("TOPLEFT", container, "TOPLEFT", x - 1, 0)
        tick:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", x - 1, 0)
        tick:SetWidth(1)
        tick:Show()
    end
end

local function LayoutSecondaryResourceBars(container, classPower, maxPower)
    if not container or not classPower then return end
    local maxValue = math.max(1, math.floor(tonumber(maxPower) or 1))
    local width = container.__mcActualWidth or math.floor(container:GetWidth() + 0.5)
    local height = container:GetHeight() or 0
    if width <= 0 or height <= 0 then return end

    for i = 1, #classPower do
        local seg = classPower[i]
        seg:ClearAllPoints()
        if i <= maxValue then
            local left = math.floor(((i - 1) * width / maxValue) + 0.5)
            local right = math.floor((i * width / maxValue) + 0.5)
            local inclusiveRight = (i < maxValue) and (right - 2) or (right - 1)
            seg:SetPoint("TOPLEFT", container, "TOPLEFT", left, 0)
            seg:SetSize(math.max(1, inclusiveRight - left + 1), height)
        else
            seg:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
            seg:SetSize(1, height)
        end
    end
end

function ns.ApplySecondaryResourceBarSize(container, width, height)
    if not container then return end
    local w = math.max(80, tonumber(width) or cfg.secondaryBarWidth)
    local h = math.max(6, tonumber(height) or cfg.secondaryBarHeight)
    container:SetSize(w, h)
    
    if ns.SecondaryResourceAnchor then ns.SecondaryResourceAnchor:SetSize(w, h) end
    UpdateSecondaryResourceTicks(container, container.__mcMaxPower or 5)
    
    if ns.__mcPlayerFrame and ns.__mcPlayerFrame.ClassPower then
        LayoutSecondaryResourceBars(container, ns.__mcPlayerFrame.ClassPower, container.__mcMaxPower or 5)
    end
end

local function IsSecondaryResourceSuppressed()
    local qol = _G.muteCatQOL
    if qol and qol.ShouldHideByVisibilityRules then
        return qol:ShouldHideByVisibilityRules()
    end

    -- Fallback if QoL is not loaded.
    if InCombatLockdown() then
        return false
    end
    local inInstance, instanceType = IsInInstance()
    if inInstance and (instanceType == "party" or instanceType == "raid") then
        return false
    end
    if
        ns.clientSceneActive
        or (C_ActionBar and C_ActionBar.HasOverrideActionBar and C_ActionBar.HasOverrideActionBar())
        or (ns.IsPlayerInVehicle and ns.IsPlayerInVehicle())
    then
        return true
    end
    if C_PetBattles and C_PetBattles.IsInBattle and C_PetBattles.IsInBattle() then
        return true
    end
    if IsResting and IsResting() then
        return true
    end
    local shapeshiftFormID = GetShapeshiftFormID()
    return IsMounted() or shapeshiftFormID == 3 or shapeshiftFormID == 29 or shapeshiftFormID == 27
end

function ns.UpdateSecondaryResourceBar()
    local container = ns.SecondaryResourceBar
    local playerFrame = ns.__mcPlayerFrame
    if not container or not playerFrame or not playerFrame.ClassPower then return end
    if container.__mcPreview then
        container:SetAlpha(1)
        container:Show()
        return
    end

    -- Important: class power must stay shown and only be alpha-hidden, otherwise updates can break.
    container:Show()
    local classPowerEnabled = playerFrame.ClassPower.__isEnabled == true
    local suppressed = IsSecondaryResourceSuppressed()
    if (not classPowerEnabled) or suppressed then
        container:SetAlpha(0)
    else
        container:SetAlpha(1)
    end
end

local function RequestSecondaryResourceBarUpdate(delay)
    if ns.__mcSecondaryUpdatePending then
        ns.__mcSecondaryUpdateDirty = true
        return
    end
    ns.__mcSecondaryUpdatePending = true
    C_Timer.After(delay or 0, function()
        ns.__mcSecondaryUpdatePending = false
        ns.UpdateSecondaryResourceBar()
        if ns.__mcSecondaryUpdateDirty then
            ns.__mcSecondaryUpdateDirty = false
            RequestSecondaryResourceBarUpdate(0.02)
        end
    end)
end

ns.RequestSecondaryResourceBarUpdate = RequestSecondaryResourceBarUpdate

local function SecondaryClassPowerPostUpdate(element, cur, max, hasMaxChanged, powerType)
    local container = element.__container
    if not container then return end

    local visibleMax = math.max(1, tonumber(max) or 0)
    container.__mcMaxPower = visibleMax

    if hasMaxChanged then
        LayoutSecondaryResourceBars(container, element, visibleMax)
        UpdateSecondaryResourceTicks(container, visibleMax)
    end

    local colorObj = element.__owner.colors.power[powerType]
    local r, g, b = (colorObj and colorObj.r or HOLY_POWER_COLOR.r), (colorObj and colorObj.g or HOLY_POWER_COLOR.g), (colorObj and colorObj.b or HOLY_POWER_COLOR.b)
    
    -- Store power type for color-only updates
    element.__powerType = powerType 
    element.__cur, element.__max = cur, max -- store for pulse/sticky logic

    -- Set flag BEFORE calling setter to ensure lock-in mechanism works
    element.__mcClassColorActive = WantsSecondaryClassColor(element, cur, max)
    
    if element.__mcClassColorActive then
        SetSecondaryClassPowerColor(element, PLAYER_CLASS_COLOR.r, PLAYER_CLASS_COLOR.g, PLAYER_CLASS_COLOR.b)
    else
        SetSecondaryClassPowerColor(element, r, g, b)
    end
    ns.UpdateSecondaryResourceBar()
end

--- Wrapper for oUF color-only updates
local function SecondaryClassPowerPostUpdateColor(element)
    SecondaryClassPowerPostUpdate(element, element.__cur or 0, element.__max or 0, false, element.__powerType or "HOLY_POWER")
end

function ns.InitializeSecondaryResourceBar(owner)
    if not secondarySupportedClasses[PLAYER_CLASS] then return end
    if ns.SecondaryResourceBar then ns.__mcPlayerFrame = owner; return ns.SecondaryResourceBar end

    local anchor = EnsureSecondaryResourceAnchor()
    local container = CreateFrame("Frame", nil, UIParent)
    container:SetPoint("CENTER", anchor, "CENTER", 0, 0)
    container:SetFrameLevel(anchor:GetFrameLevel() + 5)
    container:SetIgnoreParentAlpha(true)

    container.bg = container:CreateTexture(nil, "BACKGROUND")
    container.bg:SetAllPoints(container)
    container.bg:SetTexture(cfg.barTexture)
    container.bg:SetVertexColor(0, 0, 0, 0.55)

    -- Shared layers for borders and ticks
    local function CreateLayer(level)
        local l = CreateFrame("Frame", nil, container)
        l:SetAllPoints(); l:SetFrameLevel(container:GetFrameLevel() + level)
        return l
    end
    container.tickLayer = CreateLayer(1)
    container.borderLayer = CreateLayer(2)
    CreateFrameBorder(container, container.borderLayer, BORDER_COLOR_VALUE, BORDER_COLOR_VALUE, BORDER_COLOR_VALUE)

    local classPower = {}
    for i = 1, 10 do
        local seg = CreateFrame("StatusBar", nil, container)
        seg:SetStatusBarTexture(cfg.barTexture)
        seg:SetMinMaxValues(0, 1)
        seg:SetValue(0) -- Force initial value to prevent visual garbage
        classPower[i] = seg
    end
    classPower.__container = container
    classPower.PostUpdate  = SecondaryClassPowerPostUpdate
    classPower.PostUpdateColor = SecondaryClassPowerPostUpdateColor
    owner.ClassPower = classPower

    ns.ApplySecondaryResourceBarSize(container, cfg.secondaryBarWidth, cfg.secondaryBarHeight)
    ns.SecondaryResourceBar = container
    ns.__mcPlayerFrame = owner

    local watcher = CreateFrame("Frame")
    local events = {
        "PLAYER_ENTERING_WORLD", 
        "PLAYER_MOUNT_DISPLAY_CHANGED", 
        "UNIT_ENTERED_VEHICLE", 
        "UNIT_EXITED_VEHICLE", 
        "UPDATE_SHAPESHIFT_FORM", 
        "ZONE_CHANGED_NEW_AREA",
        "PLAYER_REGEN_DISABLED",
        "PLAYER_REGEN_ENABLED",
        "UPDATE_OVERRIDE_ACTIONBAR",
        "CLIENT_SCENE_OPENED",
        "CLIENT_SCENE_CLOSED",
        "PLAYER_UPDATE_RESTING"
    }
    for _, e in ipairs(events) do watcher:RegisterEvent(e) end
    watcher:SetScript("OnEvent", function(_, event)
        local qol = _G.muteCatQOL
        if event == "CLIENT_SCENE_OPENED" then
            ns.clientSceneActive = true
            if qol and qol.SetClientSceneActive then
                qol:SetClientSceneActive(true)
            end
        elseif event == "CLIENT_SCENE_CLOSED" then
            ns.clientSceneActive = false
            if qol and qol.SetClientSceneActive then
                qol:SetClientSceneActive(false)
            end
        end
        RequestSecondaryResourceBarUpdate(0)
    end)
    RequestSecondaryResourceBarUpdate(0.05)

    return container
end

-- =============================================================================
-- UNIT FRAME STYLING
-- =============================================================================

function ns.HideBlizzardUnitFrames()
    DisableBossFramesViaEditMode()
    if PlayerFrame then PlayerFrame:SetParent(ns.hiddenParent) end
    if TargetFrame then TargetFrame:SetParent(ns.hiddenParent) end
    if FocusFrame  then FocusFrame:SetParent(ns.hiddenParent) end
    
    HideFrameForever(TargetFrameToT)
    HideFrameForever(FocusFrameToT)
    HideFrameForever(PlayerCastingBarFrame)
    HideFrameForever(PetCastingBarFrame)
    HideFrameForever(BossTargetFrameContainer, "__mcBossHidden")

    for i = 1, 5 do HideFrameForever(_G["Boss"..i.."TargetFrame"], "__mcBossHidden") end
end

local function SetPowerVisible(self, visible)
    if not self.Power or self.__mcPowerVisible == visible then return end
    self.__mcPowerVisible = visible
    if visible then
        self.Power:Show()
        self.Health:SetHeight(cfg.healthHeightWithPower)
    else
        self.Power:Hide()
        self.Health:SetHeight(cfg.healthHeightNoPower)
    end
end

local function UpdateNameDisplay(self, unit)
    if not self.Name then return end
    self.Name:SetText(UnitName(unit) or "")
    local r, g, b = ns.GetNameColor(unit)
    self.Name:SetTextColor(r, g, b)
end

local function HealthPostUpdate(health, unit)
    local self = health.__owner
    UpdateNameDisplay(self, unit)
    if self.HealthValue then
        local colorFunc = (unit == "target" or unit == "focus") and ns.GetNameColor or ns.GetClassColor
        self.HealthValue:SetTextColor(colorFunc(unit))
    end
end

local function PowerPostUpdate(power, unit, _, _, max)
    local self = power.__owner
    SetPowerVisible(self, (unit == "player" and ns.IsPlayerInVehicle()) or ns.HasVisiblePower(max))
    ns.SetPowerColor(power, unit)
end

--- The main oUF style function.
function ns.Style(self, unit)
    local width = (unit == "focus") and math.floor(cfg.frameWidth * 0.5) or cfg.frameWidth
    self:SetSize(width, cfg.frameHeight)
    self:SetFrameStrata("LOW")

    -- Main Background
    self.bg = self:CreateTexture(nil, "BACKGROUND")
    self.bg:SetAllPoints(); self.bg:SetTexture(cfg.barTexture); self.bg:SetVertexColor(0, 0, 0, 0.2)

    -- Black Frame Borders
    CreateFrameBorder(self, self, 0, 0, 0)

    -- Health Bar
    local health = CreateFrame("StatusBar", nil, self)
    health:SetPoint("TOPLEFT", self, cfg.innerPadding, -cfg.innerPadding)
    health:SetPoint("TOPRIGHT", self, -cfg.innerPadding, -cfg.innerPadding)
    health:SetHeight(cfg.healthHeightWithPower)
    health:SetStatusBarTexture(cfg.barTexture)
    health:SetStatusBarColor(unpack(cfg.healthForeground))
    health.frequentUpdates = true
    health.smoothing = SMOOTH_INTERPOLATION
    health.PostUpdate = HealthPostUpdate
    
    health.bg = health:CreateTexture(nil, "BACKGROUND")
    health.bg:SetAllPoints(); health.bg:SetTexture(cfg.barTexture); health.bg:SetVertexColor(unpack(cfg.healthBackground))
    self.Health = health

    -- Power Bar
    local power = CreateFrame("StatusBar", nil, self)
    power:SetPoint("TOPLEFT", health, "BOTTOMLEFT", 0, 0)
    power:SetPoint("TOPRIGHT", health, "BOTTOMRIGHT", 0, 0)
    power:SetHeight(cfg.powerHeight)
    power:SetStatusBarTexture(cfg.barTexture)
    power.frequentUpdates = true
    power.smoothing = SMOOTH_INTERPOLATION
    power.PostUpdate = PowerPostUpdate
    
    power.bg = power:CreateTexture(nil, "BACKGROUND")
    power.bg:SetAllPoints(); power.bg:SetTexture(cfg.barTexture); power.bg:SetVertexColor(0.15, 0.15, 0.15, 1)
    self.Power = power

    -- Texts
    self.Name = health:CreateFontString(nil, "OVERLAY")
    self.Name:SetFont(DEFAULT_FONT, 10, "THINOUTLINE")
    self.Name:SetPoint("LEFT", health, 4, 0)

    self.HealthValue = health:CreateFontString(nil, "OVERLAY")
    self.HealthValue:SetFont(DEFAULT_FONT, 10, "THINOUTLINE")
    self.HealthValue:SetPoint("RIGHT", health, -3, 0)
    if self.Tag then self:Tag(self.HealthValue, "[mutecat:curhpabbr]") end

    -- Player Castbar & Resources
    if unit == "player" then
        local anchor = EnsureCastbarAnchor()
        local castbar = CreateFrame("StatusBar", nil, UIParent)
        castbar.__mcAnchor = anchor
        castbar:SetPoint("LEFT", anchor, cfg.castbarHeight, 0)
        ns.ApplyCastbarSize(castbar)
        castbar:SetStatusBarTexture(cfg.barTexture)
        ApplyCastbarClassColor(castbar)
        castbar:SetFrameLevel(anchor:GetFrameLevel() + 5)
        castbar:SetIgnoreParentAlpha(true)
        castbar.timeToHold = 0.15
        castbar.smoothing = IMMEDIATE_INTERPOLATION

        castbar.bg = castbar:CreateTexture(nil, "BACKGROUND")
        castbar.bg:SetAllPoints(); castbar.bg:SetTexture(cfg.barTexture); castbar.bg:SetVertexColor(0, 0, 0, 0.55)
        CreateFrameBorder(castbar, castbar, BORDER_COLOR_VALUE, BORDER_COLOR_VALUE, BORDER_COLOR_VALUE)

        -- Castbar Icon
        local iconFrame = CreateFrame("Frame", nil, castbar)
        iconFrame:SetSize(cfg.castbarHeight, cfg.castbarHeight)
        iconFrame:SetPoint("RIGHT", castbar, "LEFT", 0, 0)
        iconFrame.bg = iconFrame:CreateTexture(nil, "BACKGROUND")
        iconFrame.bg:SetAllPoints(); iconFrame.bg:SetTexture(WHITE_TEXTURE); iconFrame.bg:SetVertexColor(0, 0, 0, 0.55)
        CreateFrameBorder(iconFrame, iconFrame, BORDER_COLOR_VALUE, BORDER_COLOR_VALUE, BORDER_COLOR_VALUE)

        castbar.Icon = iconFrame:CreateTexture(nil, "ARTWORK")
        castbar.Icon:SetPoint("TOPLEFT", 1, -1); castbar.Icon:SetPoint("BOTTOMRIGHT", -1, 1)
        castbar.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        castbar.IconFrame = iconFrame

        castbar.Text = castbar:CreateFontString(nil, "OVERLAY")
        castbar.Text:SetFont(DEFAULT_FONT, 10, "THINOUTLINE"); castbar.Text:SetPoint("LEFT", 4, 0)

        castbar.Time = castbar:CreateFontString(nil, "OVERLAY")
        castbar.Time:SetFont(DEFAULT_FONT, 10, "THINOUTLINE"); castbar.Time:SetPoint("RIGHT", -4, 0)

        castbar.PostCastStart = CastbarPostStart
        castbar.PostChannelStart = CastbarPostStart
        self.Castbar = castbar
        self.SecondaryResourceBar = ns.InitializeSecondaryResourceBar(self)

        -- Indicators
        local iconOverlay = CreateFrame("Frame", nil, self)
        iconOverlay:SetAllPoints(); iconOverlay:SetFrameLevel(self:GetFrameLevel() + 20)
        
        self.CombatIndicator = iconOverlay:CreateTexture(nil, "OVERLAY")
        self.CombatIndicator:SetSize(18, 18); self.CombatIndicator:SetPoint("TOP", 0, -8)
        self.CombatIndicator:SetTexture(cfg.combatIcon) -- Explicitly use custom texture to override oUF 13.3.0 Atlas default
        
        self.RestingIndicator = iconOverlay:CreateTexture(nil, "OVERLAY")
        self.RestingIndicator:SetSize(20, 20); self.RestingIndicator:SetPoint("TOPLEFT", -6, 7)
        self.RestingIndicator:SetTexture(cfg.restingIcon) -- Explicitly use custom texture to override oUF 13.3.0 Atlas default
    end
end
