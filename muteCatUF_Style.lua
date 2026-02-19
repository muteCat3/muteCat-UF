local _, ns = ...
local cfg = ns.config
local oUF = ns.oUF

local WHITE_TEXTURE = "Interface\\Buttons\\WHITE8x8"
local holyPowerColor = (PowerBarColor and (PowerBarColor.HOLY_POWER or (Enum and Enum.PowerType and PowerBarColor[Enum.PowerType.HolyPower]))) or { r = 0.95, g = 0.9, b = 0.6 }
local secondaryLineColor = 0.12156863
local PLAYER_CLASS = select(2, UnitClass("player"))
local PLAYER_CLASS_COLOR = PLAYER_CLASS and cfg.classColors and cfg.classColors[PLAYER_CLASS]
local SMOOTH_INTERPOLATION = (Enum and Enum.StatusBarInterpolation and (Enum.StatusBarInterpolation.ExponentialEaseOut or Enum.StatusBarInterpolation.Smooth)) or 1
local IMMEDIATE_INTERPOLATION = (Enum and Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.Immediate) or 0

if oUF and oUF.Tags and oUF.Tags.Methods and not oUF.Tags.Methods["mutecat:curhpabbr"] then
    oUF.Tags.Methods["mutecat:curhpabbr"] = function(unit)
        local value = UnitHealth and UnitHealth(unit)
        return ns.ShortValue(value)
    end
    oUF.Tags.Events["mutecat:curhpabbr"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION"
end

local function ApplyCastbarClassColor(castbar)
    if PLAYER_CLASS_COLOR then
        castbar:SetStatusBarColor(PLAYER_CLASS_COLOR.r, PLAYER_CLASS_COLOR.g, PLAYER_CLASS_COLOR.b, 1)
    else
        castbar:SetStatusBarColor(holyPowerColor.r, holyPowerColor.g, holyPowerColor.b, 1)
    end
end

local function HideFrameForever(frame, flagName)
    if not frame then
        return
    end

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

local function DisableBossFramesViaEditMode()
    if ns.__mcBossSettingApplied then
        return
    end

    if C_EditMode and C_EditMode.SetAccountSetting and Enum and Enum.EditModeAccountSetting and Enum.EditModeAccountSetting.ShowBossFrames then
        pcall(C_EditMode.SetAccountSetting, Enum.EditModeAccountSetting.ShowBossFrames, 0)
        ns.__mcBossSettingApplied = true
    end
end

local function CastbarPostStart(castbar)
    if ns.RefreshCastbarFromEditMode then
        ns.RefreshCastbarFromEditMode(castbar)
    end

    ApplyCastbarClassColor(castbar)

    castbar:SetAlpha(1)
    castbar:Show()
end

local function EnsureCastbarAnchor()
    if ns.CastbarAnchor then
        return ns.CastbarAnchor
    end

    local anchor = CreateFrame("Frame", "muteCatUF_CastbarAnchor", UIParent)
    anchor:SetPoint("CENTER", UIParent, "CENTER", cfg.castbarCenterX, cfg.castbarCenterY)
    anchor:SetSize(cfg.castbarWidth + cfg.castbarHeight, cfg.castbarHeight)
    anchor:SetFrameStrata("MEDIUM")
    anchor:EnableMouse(false)

    anchor.preview = anchor:CreateTexture(nil, "BACKGROUND")
    anchor.preview:SetAllPoints(anchor)
    anchor.preview:SetTexture(WHITE_TEXTURE)
    anchor.preview:SetVertexColor(1, 1, 1, 0)
    anchor:Show()

    ns.CastbarAnchor = anchor
    return anchor
end

function ns.ApplyCastbarSize(castbar, width, height)
    if not castbar then
        return
    end

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
    if castbar.IconFrame then
        castbar.IconFrame:SetSize(h, h)
    elseif castbar.Icon then
        castbar.Icon:SetSize(h, h)
    end
end

local function EnsureSecondaryResourceAnchor()
    if ns.SecondaryResourceAnchor then
        return ns.SecondaryResourceAnchor
    end

    local anchor = CreateFrame("Frame", "muteCatUF_SecondaryResourceAnchor", UIParent)
    anchor:SetPoint("CENTER", UIParent, "CENTER", 0, -40)
    anchor:SetSize(cfg.secondaryBarWidth, cfg.secondaryBarHeight)
    anchor:SetFrameStrata("MEDIUM")
    anchor:EnableMouse(false)

    anchor.preview = anchor:CreateTexture(nil, "BACKGROUND")
    anchor.preview:SetAllPoints(anchor)
    anchor.preview:SetTexture(WHITE_TEXTURE)
    anchor.preview:SetVertexColor(1, 1, 1, 0)
    anchor:Show()

    ns.SecondaryResourceAnchor = anchor
    return anchor
end

local secondarySupportedClasses = {
    DEMONHUNTER = true,
    DRUID = true,
    EVOKER = true,
    MAGE = true,
    MONK = true,
    PALADIN = true,
    ROGUE = true,
    SHAMAN = true,
    WARLOCK = true,
}

local function UnpackColor(color, fallbackR, fallbackG, fallbackB)
    if type(color) == "table" then
        if color.GetRGB then
            return color:GetRGB()
        end
        if color.r and color.g and color.b then
            return color.r, color.g, color.b
        end
        if color[1] and color[2] and color[3] then
            return color[1], color[2], color[3]
        end
    end

    return fallbackR, fallbackG, fallbackB
end

local function SetSecondaryClassPowerColor(element, r, g, b)
    if element.__mcColorR ~= r or element.__mcColorG ~= g or element.__mcColorB ~= b then
        element.__mcColorR, element.__mcColorG, element.__mcColorB = r, g, b
        for i = 1, #element do
            element[i]:SetStatusBarColor(r, g, b, 1)
        end
    end
end

local function GetCurrentSecondaryClassPowerColor(element)
    local first = element and element[1]
    if first and first.GetStatusBarColor then
        return first:GetStatusBarColor()
    end

    return nil, nil, nil
end

local function WantsSecondaryClassColor(element, cur, max)
    if not PLAYER_CLASS_COLOR then
        return false, false
    end

    -- Paladin mode: always keep Holy Power base color.
    if PLAYER_CLASS == "PALADIN" then
        return false, true
    end

    local maxIsAccessible = not ns.CanAccessValue or ns.CanAccessValue(max)
    local curIsAccessible = not ns.CanAccessValue or ns.CanAccessValue(cur)
    local canEvaluateAtMax = maxIsAccessible and curIsAccessible and type(max) == "number" and type(cur) == "number"
    local isAtMax = canEvaluateAtMax and max > 0 and cur >= max

    local wantsClassColor = isAtMax
    if not wantsClassColor and not canEvaluateAtMax and element.__mcClassColorActive then
        wantsClassColor = true
    end

    return wantsClassColor, canEvaluateAtMax
end

local function CreateOverlayLayer(parent, levelOffset)
    local layer = CreateFrame("Frame", nil, parent)
    layer:SetAllPoints(parent)
    layer:SetFrameStrata(parent:GetFrameStrata())
    layer:SetFrameLevel((parent:GetFrameLevel() or 1) + (levelOffset or 1))
    return layer
end

local function CreateFrameBorder(owner, parent, r, g, b, alphaTop, alphaBottom, alphaLeft, alphaRight)
    owner.borderTop = parent:CreateTexture(nil, "OVERLAY")
    owner.borderTop:SetTexture(WHITE_TEXTURE)
    owner.borderTop:SetPoint("TOPLEFT", owner, "TOPLEFT", 0, 0)
    owner.borderTop:SetPoint("TOPRIGHT", owner, "TOPRIGHT", 0, 0)
    owner.borderTop:SetHeight(1)
    owner.borderTop:SetVertexColor(r, g, b, alphaTop or 1)

    owner.borderBottom = parent:CreateTexture(nil, "OVERLAY")
    owner.borderBottom:SetTexture(WHITE_TEXTURE)
    owner.borderBottom:SetPoint("BOTTOMLEFT", owner, "BOTTOMLEFT", 0, 0)
    owner.borderBottom:SetPoint("BOTTOMRIGHT", owner, "BOTTOMRIGHT", 0, 0)
    owner.borderBottom:SetHeight(1)
    owner.borderBottom:SetVertexColor(r, g, b, alphaBottom or 1)

    owner.borderLeft = parent:CreateTexture(nil, "OVERLAY")
    owner.borderLeft:SetTexture(WHITE_TEXTURE)
    owner.borderLeft:SetPoint("TOPLEFT", owner, "TOPLEFT", 0, 0)
    owner.borderLeft:SetPoint("BOTTOMLEFT", owner, "BOTTOMLEFT", 0, 0)
    owner.borderLeft:SetWidth(1)
    owner.borderLeft:SetVertexColor(r, g, b, alphaLeft or 1)

    owner.borderRight = parent:CreateTexture(nil, "OVERLAY")
    owner.borderRight:SetTexture(WHITE_TEXTURE)
    owner.borderRight:SetPoint("TOPRIGHT", owner, "TOPRIGHT", 0, 0)
    owner.borderRight:SetPoint("BOTTOMRIGHT", owner, "BOTTOMRIGHT", 0, 0)
    owner.borderRight:SetWidth(1)
    owner.borderRight:SetVertexColor(r, g, b, alphaRight or 1)
end

local function SetSecondaryResourceBorderThickness(container)
    if not container then
        return
    end

    local thickness = math.max(1, tonumber(cfg.secondaryBorderThickness) or 2)
    container.borderTop:SetHeight(thickness)
    container.borderBottom:SetHeight(thickness)
    container.borderLeft:SetWidth(thickness)
    container.borderRight:SetWidth(thickness)
end

local function UpdateSecondaryResourceTicks(container, maxPower)
    if not container then
        return
    end

    local maxValue = math.max(0, math.floor(tonumber(maxPower) or 0))
    container.__mcMaxPower = maxValue

    local tickThickness = math.max(2, tonumber(cfg.secondaryTickThickness) or 2)
    local width = container:GetWidth() or 0
    if width <= 0 then
        return
    end

    local tickParent = container.tickLayer or container
    if not container.ticks then
        container.ticks = {}
    end

    for i = 1, #container.ticks do
        container.ticks[i]:Hide()
    end

    if maxValue <= 1 then
        return
    end

    local segmentWidth = width / maxValue
    for i = 1, (maxValue - 1) do
        local tick = container.ticks[i]
        if not tick then
            tick = tickParent:CreateTexture(nil, "OVERLAY")
            tick:SetTexture(WHITE_TEXTURE)
            tick:SetVertexColor(secondaryLineColor, secondaryLineColor, secondaryLineColor, 1)
            container.ticks[i] = tick
        end

        local x = math.floor((segmentWidth * i) + 0.5) - math.floor(tickThickness * 0.5)
        tick:ClearAllPoints()
        tick:SetPoint("TOPLEFT", container, "TOPLEFT", x, 0)
        tick:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", x, 0)
        tick:SetWidth(tickThickness)
        tick:Show()
    end
end

local function LayoutSecondaryResourceBars(container, classPower, maxPower)
    if not container or not classPower then
        return
    end

    local maxValue = math.max(1, math.floor(tonumber(maxPower) or 1))
    local width = container:GetWidth() or 0
    local height = container:GetHeight() or 0
    if width <= 0 or height <= 0 then
        return
    end

    local segmentWidth = width / maxValue
    for i = 1, #classPower do
        local seg = classPower[i]
        seg:ClearAllPoints()

        if i <= maxValue then
            local left = math.floor(((i - 1) * segmentWidth) + 0.5)
            local right = math.floor((i * segmentWidth) + 0.5)
            local segWidth = math.max(1, right - left)
            seg:SetPoint("TOPLEFT", container, "TOPLEFT", left, 0)
            seg:SetSize(segWidth, height)
        else
            seg:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
            seg:SetSize(1, height)
        end
    end
end

local function IsSecondaryResourceSuppressed()
    if cfg.secondaryHideInVehicle and ns.IsPlayerInVehicle and ns.IsPlayerInVehicle() then
        return true
    end

    if cfg.secondaryHideMountedOutsideInstance and IsMounted and IsMounted() then
        local _, instanceType = IsInInstance()
        if instanceType ~= "party" and instanceType ~= "raid" then
            return true
        end
    end

    return false
end

function ns.ApplySecondaryResourceBarSize(container, width, height)
    if not container then
        return
    end

    local w = math.max(80, tonumber(width) or cfg.secondaryBarWidth)
    local h = math.max(6, tonumber(height) or cfg.secondaryBarHeight)
    container:SetSize(w, h)

    if ns.SecondaryResourceAnchor then
        ns.SecondaryResourceAnchor:SetSize(w, h)
    end

    SetSecondaryResourceBorderThickness(container)
    UpdateSecondaryResourceTicks(container, container.__mcMaxPower or 5)

    local playerFrame = ns.__mcPlayerFrame
    if playerFrame and playerFrame.ClassPower then
        LayoutSecondaryResourceBars(container, playerFrame.ClassPower, container.__mcMaxPower or 5)
    end
end

function ns.UpdateSecondaryResourceBar()
    if true then return end -- Temporarily disabled
    local container = ns.SecondaryResourceBar
    local playerFrame = ns.__mcPlayerFrame
    if not container or not playerFrame or not playerFrame.ClassPower then
        return
    end

    if container.__mcPreview then
        container:Show()
        return
    end

    if not playerFrame.ClassPower.__isEnabled then
        container:Hide()
        return
    end

    if IsSecondaryResourceSuppressed() then
        container:Hide()
        return
    end

    container:Show()
end

local function SecondaryClassPowerPostUpdate(element, cur, max, hasMaxChanged, powerType)
    local container = element.__container
    if not container then
        return
    end

    local maxIsAccessible = not ns.CanAccessValue or ns.CanAccessValue(max)
    local visibleMax = math.max(1, (maxIsAccessible and tonumber(max)) or 0)
    container.__mcMaxPower = visibleMax

    if hasMaxChanged then
        LayoutSecondaryResourceBars(container, element, visibleMax)
        UpdateSecondaryResourceTicks(container, visibleMax)
    end

    local fallback = holyPowerColor
    local colorObj = element.__owner and element.__owner.colors and element.__owner.colors.power and powerType and element.__owner.colors.power[powerType]
    local baseR, baseG, baseB = UnpackColor(colorObj, fallback.r, fallback.g, fallback.b)
    local wantsClassColor = WantsSecondaryClassColor(element, cur, max)
    if wantsClassColor then
        element.__mcClassColorActive = true
        SetSecondaryClassPowerColor(element, PLAYER_CLASS_COLOR.r, PLAYER_CLASS_COLOR.g, PLAYER_CLASS_COLOR.b)
    else
        element.__mcClassColorActive = false
        SetSecondaryClassPowerColor(element, baseR, baseG, baseB)
    end

    ns.UpdateSecondaryResourceBar()
end

local function SecondaryClassPowerPostUpdateColor(element)
    local wantsClassColor, canEvaluateAtMax = WantsSecondaryClassColor(element, element.__cur, element.__max)
    if wantsClassColor then
        element.__mcClassColorActive = true
        SetSecondaryClassPowerColor(element, PLAYER_CLASS_COLOR.r, PLAYER_CLASS_COLOR.g, PLAYER_CLASS_COLOR.b)
        return
    end

    if canEvaluateAtMax then
        element.__mcClassColorActive = false
    end

    local r, g, b = GetCurrentSecondaryClassPowerColor(element)
    if r and g and b then
        element.__mcColorR, element.__mcColorG, element.__mcColorB = r, g, b
    end
end

local function SecondaryClassPowerPostVisibility()
    ns.UpdateSecondaryResourceBar()
end

function ns.InitializeSecondaryResourceBar(owner)
    if true then return end -- Temporarily disabled
    if ns.SecondaryResourceBar then
        if owner then
            ns.__mcPlayerFrame = owner
        end
        ns.UpdateSecondaryResourceBar()
        return ns.SecondaryResourceBar
    end

    if not secondarySupportedClasses[PLAYER_CLASS] then
        return
    end

    local anchor = EnsureSecondaryResourceAnchor()
    local container = CreateFrame("Frame", nil, UIParent)
    container:SetPoint("CENTER", anchor, "CENTER", 0, 0)
    container:SetFrameStrata("MEDIUM")
    container:SetFrameLevel((anchor:GetFrameLevel() or 1) + 5)
    container:SetIgnoreParentAlpha(true)

    container.bg = container:CreateTexture(nil, "BACKGROUND")
    container.bg:SetAllPoints(container)
    container.bg:SetTexture(cfg.barTexture)
    container.bg:SetVertexColor(0, 0, 0, 0.55)

    container.tickLayer = CreateOverlayLayer(container, 25)
    container.borderLayer = CreateOverlayLayer(container, 30)
    CreateFrameBorder(container, container.borderLayer, secondaryLineColor, secondaryLineColor, secondaryLineColor, 1, 1, 1, 1)

    container:SetScript("OnSizeChanged", function(self)
        SetSecondaryResourceBorderThickness(self)
        UpdateSecondaryResourceTicks(self, self.__mcMaxPower or 5)
        if owner and owner.ClassPower then
            LayoutSecondaryResourceBars(self, owner.ClassPower, self.__mcMaxPower or 5)
        end
    end)

    local classPower = {}
    for i = 1, 10 do
        local seg = CreateFrame("StatusBar", nil, container)
        seg:SetStatusBarTexture(cfg.barTexture)
        seg:SetMinMaxValues(0, 1)
        seg:SetValue(0)
        seg.smoothing = SMOOTH_INTERPOLATION
        classPower[i] = seg
    end
    classPower.__container = container
    classPower.PostUpdate = SecondaryClassPowerPostUpdate
    classPower.PostUpdateColor = SecondaryClassPowerPostUpdateColor
    classPower.PostVisibility = SecondaryClassPowerPostVisibility

    if owner then
        owner.ClassPower = classPower
    end

    ns.ApplySecondaryResourceBarSize(container, cfg.secondaryBarWidth, cfg.secondaryBarHeight)
    ns.SecondaryResourceBar = container
    ns.__mcPlayerFrame = owner

    if not ns.__mcSecondaryResourceWatcher then
        local watcher = CreateFrame("Frame")
        watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
        watcher:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
        watcher:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        watcher:RegisterEvent("UNIT_ENTERED_VEHICLE")
        watcher:RegisterEvent("UNIT_EXITED_VEHICLE")
        watcher:RegisterEvent("VEHICLE_UPDATE")
        watcher:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR")
        watcher:SetScript("OnEvent", function(_, _, unit)
            if unit and unit ~= "player" then
                return
            end
            local frame = ns.__mcPlayerFrame
            if frame and frame.ClassPower and frame.ClassPower.ForceUpdate then
                frame.ClassPower:ForceUpdate()
            end
            ns.UpdateSecondaryResourceBar()
        end)
        ns.__mcSecondaryResourceWatcher = watcher
    end

    ns.UpdateSecondaryResourceBar()
    return container
end

function ns.HideBlizzardUnitFrames()
    DisableBossFramesViaEditMode()

    if PlayerFrame then
        PlayerFrame:SetParent(ns.hiddenParent)
    end

    if TargetFrame then
        TargetFrame:SetParent(ns.hiddenParent)
    end

    if FocusFrame then
        FocusFrame:SetParent(ns.hiddenParent)
    end

    HideFrameForever(TargetFrameToT)
    HideFrameForever(FocusFrameToT)

    if CastingBarFrame then
        CastingBarFrame:SetParent(ns.hiddenParent)
    end
    HideFrameForever(PlayerCastingBarFrame)
    HideFrameForever(PetCastingBarFrame)

    HideFrameForever(BossTargetFrameContainer, "__mcBossHiddenSetup")

    for i = 1, 5 do
        local bossFrame = _G["Boss" .. i .. "TargetFrame"]
        HideFrameForever(bossFrame, "__mcBossHiddenSetup")
    end
end

local function SetPowerVisible(self, visible)
    if not self or not self.Power or not self.Health then
        return
    end

    if self.__mcPowerVisible == visible then
        return
    end
    self.__mcPowerVisible = visible

    if visible then
        self.Power:Show()
        if self.Power.bg then
            self.Power.bg:Show()
        end
        self.Health:SetHeight(cfg.healthHeightWithPower)
    else
        self.Power:Hide()
        if self.Power.bg then
            self.Power.bg:Hide()
        end
        self.Health:SetHeight(cfg.healthHeightNoPower)
    end
end

local function UpdateNameDisplay(self, unit)
    if not self or not self.Name then
        return
    end

    if not self.Name:IsShown() then
        self.Name:Show()
    end

    local name = UnitName(unit) or ""
    self.Name:SetText(name)

    local r, g, b = ns.GetNameColor(unit)
    if self.__mcNameR ~= r or self.__mcNameG ~= g or self.__mcNameB ~= b then
        self.__mcNameR, self.__mcNameG, self.__mcNameB = r, g, b
        self.Name:SetTextColor(r, g, b, 1)
    end
end

--- Post-update handler for the Health element.
--- Manages unit name display, health value coloring, and absorb indicator states.
--- @param health table The health status bar element.
--- @param unit string The unit's ID.
--- @param cur number Current health value.
--- @param max number Maximum health value.
local function HealthPostUpdate(health, unit, cur, max)
    local self = health.__owner
    if self and self.HealthValue then
        UpdateNameDisplay(self, unit)

        local colorFunc = (unit == "target" or unit == "focus") and ns.GetNameColor or ns.GetClassColor
        local r, g, b = colorFunc(unit)
        if self.__mcHealthR ~= r or self.__mcHealthG ~= g or self.__mcHealthB ~= b then
            self.__mcHealthR, self.__mcHealthG, self.__mcHealthB = r, g, b
            self.HealthValue:SetTextColor(r, g, b, 1)
        end
    end

    -- Update visuals for the over-absorb indicator (Glow effect)
    if health.DamageAbsorb and health.OverDamageAbsorbIndicator then
        local isOverflowing = health.OverDamageAbsorbIndicator:IsShown()
        if isOverflowing then
            health.OverDamageAbsorbIndicator:SetVertexColor(0.2, 0.9, 1, 1)
        end
    end
end

local function PowerPostUpdate(power, unit, _, _, max)
    local self = power.__owner
    if self then
        local keepVisible = (unit == "player" and ns.IsPlayerInVehicle()) or ns.HasVisiblePower(max)
        SetPowerVisible(self, keepVisible)
    end

    ns.SetPowerColor(power, unit)
end

function ns.Style(self, unit)
    local frameWidth = cfg.frameWidth
    if unit == "focus" then
        frameWidth = math.floor(cfg.frameWidth * 0.5)
    end

    self:SetSize(frameWidth, cfg.frameHeight)
    self:SetFrameStrata("LOW")

    self.bg = self:CreateTexture(nil, "BACKGROUND")
    self.bg:SetAllPoints(self)
    self.bg:SetTexture(cfg.barTexture)
    self.bg:SetVertexColor(0, 0, 0, 0.2)

    self.borderTop = self:CreateTexture(nil, "BORDER")
    self.borderTop:SetTexture(WHITE_TEXTURE)
    self.borderTop:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
    self.borderTop:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, 0)
    self.borderTop:SetHeight(1)

    self.borderBottom = self:CreateTexture(nil, "BORDER")
    self.borderBottom:SetTexture(WHITE_TEXTURE)
    self.borderBottom:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, 0)
    self.borderBottom:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
    self.borderBottom:SetHeight(1)

    self.borderLeft = self:CreateTexture(nil, "BORDER")
    self.borderLeft:SetTexture(WHITE_TEXTURE)
    self.borderLeft:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
    self.borderLeft:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, 0)
    self.borderLeft:SetWidth(1)

    self.borderRight = self:CreateTexture(nil, "BORDER")
    self.borderRight:SetTexture(WHITE_TEXTURE)
    self.borderRight:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, 0)
    self.borderRight:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
    self.borderRight:SetWidth(1)

    self.borderTop:SetVertexColor(0, 0, 0, 1)
    self.borderBottom:SetVertexColor(0, 0, 0, 1)
    self.borderLeft:SetVertexColor(0, 0, 0, 1)
    self.borderRight:SetVertexColor(0, 0, 0, 1)

    -- Health Setup
    local health = CreateFrame("StatusBar", nil, self)
    health:SetPoint("TOPLEFT", self, "TOPLEFT", cfg.innerPadding, -cfg.innerPadding)
    health:SetPoint("TOPRIGHT", self, "TOPRIGHT", -cfg.innerPadding, -cfg.innerPadding)
    health:SetHeight(cfg.healthHeightWithPower)
    health:SetStatusBarTexture(cfg.barTexture)
    health:SetStatusBarColor(cfg.healthForeground[1], cfg.healthForeground[2], cfg.healthForeground[3], cfg.healthForeground[4])
    health.frequentUpdates = true
    health.smoothing = SMOOTH_INTERPOLATION
    health.PostUpdate = HealthPostUpdate
    
    -- Configure absorb clamping behavior
    health.damageAbsorbClampMode = 2
    health.healAbsorbClampMode = 1

    health.bg = health:CreateTexture(nil, "BACKGROUND")
    health.bg:SetAllPoints(health)
    health.bg:SetTexture(cfg.barTexture)
    health.bg:SetVertexColor(cfg.healthBackground[1], cfg.healthBackground[2], cfg.healthBackground[3], cfg.healthBackground[4])

    self.Health = health

    -- Absorb Overlays (Damage & Heal Absorb)
    local healthTexture = health:GetStatusBarTexture()

    -- Damage Absorb: Displays active shields, filling from right to left starting at the health edge.
    local damageAbsorb = CreateFrame("StatusBar", nil, health)
    damageAbsorb:SetPoint("TOP", health, "TOP")
    damageAbsorb:SetPoint("BOTTOM", health, "BOTTOM")
    damageAbsorb:SetPoint("RIGHT", healthTexture, "RIGHT")
    damageAbsorb:SetWidth(cfg.frameWidth)
    damageAbsorb:SetStatusBarTexture(cfg.barTexture)
    damageAbsorb:SetStatusBarColor(0.718, 0.953, 1, 0.8) -- #B7F3FFCD Ice-Blue
    damageAbsorb:SetReverseFill(true)
    damageAbsorb:SetFrameLevel(health:GetFrameLevel() + 2)

    -- Over-absorb Indicator: Glow effect shown when shields exceed maximum health.
    local overDamageAbsorbIndicator = health:CreateTexture(nil, "OVERLAY")
    overDamageAbsorbIndicator:SetPoint("TOPRIGHT", health, "TOPRIGHT", 0, 0)
    overDamageAbsorbIndicator:SetPoint("BOTTOMRIGHT", health, "BOTTOMRIGHT", 0, 0)
    overDamageAbsorbIndicator:SetWidth(16)
    overDamageAbsorbIndicator:SetTexture("Interface\\RaidFrame\\Shield-Overshield")
    overDamageAbsorbIndicator:SetBlendMode("ADD")
    overDamageAbsorbIndicator:SetVertexColor(0, 0.9, 1, 1)
    overDamageAbsorbIndicator:Hide()

    -- Heal Absorb: Displays anti-healing debts, anchored to the left of the frame.
    local healAbsorb = CreateFrame("StatusBar", nil, health)
    healAbsorb:SetPoint("TOPLEFT", health, "TOPLEFT")
    healAbsorb:SetPoint("BOTTOMLEFT", health, "BOTTOMLEFT")
    healAbsorb:SetWidth(cfg.frameWidth)
    healAbsorb:SetStatusBarTexture(cfg.barTexture)
    healAbsorb:SetStatusBarColor(1, 0.608, 0.996, 0.8) -- #FF9BFECC Neon-Pink
    healAbsorb:SetReverseFill(false)
    healAbsorb:SetFrameLevel(health:GetFrameLevel() + 2)
    healAbsorb:Hide()

    health.DamageAbsorb = damageAbsorb
    health.HealAbsorb = healAbsorb
    health.OverDamageAbsorbIndicator = overDamageAbsorbIndicator

    local power = CreateFrame("StatusBar", nil, self)
    power:SetPoint("TOPLEFT", health, "BOTTOMLEFT", 0, 0)
    power:SetPoint("TOPRIGHT", health, "BOTTOMRIGHT", 0, 0)
    power:SetHeight(cfg.powerHeight)
    power:SetStatusBarTexture(cfg.barTexture)
    power.frequentUpdates = true
    power.smoothing = SMOOTH_INTERPOLATION
    power.colorPower = false
    power.colorClass = false
    power.colorReaction = false
    power.PostUpdate = PowerPostUpdate

    power.bg = power:CreateTexture(nil, "BACKGROUND")
    power.bg:SetAllPoints(power)
    power.bg:SetTexture(cfg.barTexture)
    power.bg:SetVertexColor(0.15, 0.15, 0.15, 1)

    self.Power = power

    self.Name = health:CreateFontString(nil, "OVERLAY")
    self.Name:SetFont("Fonts\\FRIZQT__.TTF", 10, "THINOUTLINE")
    self.Name:SetPoint("LEFT", health, "LEFT", 4, 0)
    self.Name:SetJustifyH("LEFT")
    self.Name:SetTextColor(1, 1, 1, 1)
    self.Name:SetText("")

    self.Name:Show()

    self.HealthValue = health:CreateFontString(nil, "OVERLAY")
    self.HealthValue:SetFont("Fonts\\FRIZQT__.TTF", 10, "THINOUTLINE")
    self.HealthValue:SetPoint("RIGHT", health, "RIGHT", -3, 0)
    self.HealthValue:SetJustifyH("RIGHT")
    self.HealthValue:SetTextColor(0, 0, 0, 1)
    self.HealthValue:SetText("0")
    if self.Tag then
        self:Tag(self.HealthValue, "[mutecat:curhpabbr]")
    end

    if unit == "player" then
        local castbarAnchor = EnsureCastbarAnchor()
        local castbar = CreateFrame("StatusBar", nil, UIParent)
        castbar.__mcAnchor = castbarAnchor
        castbar:SetPoint("LEFT", castbarAnchor, "LEFT", cfg.castbarHeight, 0)
        ns.ApplyCastbarSize(castbar, cfg.castbarWidth, cfg.castbarHeight)
        castbar:SetStatusBarTexture(cfg.barTexture)
        ApplyCastbarClassColor(castbar)
        castbar:SetFrameStrata("MEDIUM")
        castbar:SetFrameLevel((castbarAnchor:GetFrameLevel() or 1) + 5)
        castbar:SetIgnoreParentAlpha(true)
        castbar.timeToHold = 0.15
        castbar.smoothing = IMMEDIATE_INTERPOLATION

        castbar.bg = castbar:CreateTexture(nil, "BACKGROUND")
        castbar.bg:SetAllPoints(castbar)
        castbar.bg:SetTexture(cfg.barTexture)
        castbar.bg:SetVertexColor(0, 0, 0, 0.55)

        CreateFrameBorder(castbar, castbar, secondaryLineColor, secondaryLineColor, secondaryLineColor, 1, 1, 0, 1)

        castbar.IconFrame = CreateFrame("Frame", nil, castbar)
        castbar.IconFrame:SetSize(cfg.castbarHeight, cfg.castbarHeight)
        castbar.IconFrame:SetPoint("RIGHT", castbar, "LEFT", 0, 0)

        castbar.IconFrame.bg = castbar.IconFrame:CreateTexture(nil, "BACKGROUND")
        castbar.IconFrame.bg:SetAllPoints(castbar.IconFrame)
        castbar.IconFrame.bg:SetTexture(WHITE_TEXTURE)
        castbar.IconFrame.bg:SetVertexColor(0, 0, 0, 0.55)

        CreateFrameBorder(castbar.IconFrame, castbar.IconFrame, secondaryLineColor, secondaryLineColor, secondaryLineColor, 1, 1, 1, 0)

        castbar.Icon = castbar.IconFrame:CreateTexture(nil, "ARTWORK")
        castbar.Icon:SetPoint("TOPLEFT", castbar.IconFrame, "TOPLEFT", 1, -1)
        castbar.Icon:SetPoint("BOTTOMRIGHT", castbar.IconFrame, "BOTTOMRIGHT", -1, 1)
        castbar.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        castbar.Icon:SetDrawLayer("OVERLAY", 2)

        castbar.Text = castbar:CreateFontString(nil, "OVERLAY")
        castbar.Text:SetFont("Fonts\\FRIZQT__.TTF", 10, "THINOUTLINE")
        castbar.Text:SetPoint("LEFT", castbar, "LEFT", 4, 0)
        castbar.Text:SetJustifyH("LEFT")

        castbar.Time = castbar:CreateFontString(nil, "OVERLAY")
        castbar.Time:SetFont("Fonts\\FRIZQT__.TTF", 10, "THINOUTLINE")
        castbar.Time:SetPoint("RIGHT", castbar, "RIGHT", -4, 0)
        castbar.Time:SetJustifyH("RIGHT")

        castbar.SafeZone = castbar:CreateTexture(nil, "OVERLAY")
        castbar.SafeZone:SetTexture(WHITE_TEXTURE)
        castbar.SafeZone:SetVertexColor(0.9, 0.2, 0.2, 0.4)
        castbar.PostCastStart = CastbarPostStart
        castbar.PostChannelStart = CastbarPostStart

        self.Castbar = castbar
        self.SecondaryResourceBar = ns.InitializeSecondaryResourceBar(self)

        self.IconOverlay = CreateFrame("Frame", nil, self)
        self.IconOverlay:SetAllPoints(self)
        self.IconOverlay:SetFrameLevel(self:GetFrameLevel() + 20)

        self.CombatIndicator = self.IconOverlay:CreateTexture(nil, "OVERLAY")
        self.CombatIndicator:SetSize(18, 18)
        self.CombatIndicator:SetPoint("TOP", self, "TOP", 0, -8)
        self.CombatIndicator:SetTexture(cfg.combatIcon)
        self.CombatIndicator:SetTexCoord(0, 1, 0, 1)
        self.CombatIndicator:SetDrawLayer("OVERLAY", 7)

        self.RestingIndicator = self.IconOverlay:CreateTexture(nil, "OVERLAY")
        self.RestingIndicator:SetSize(20, 20)
        self.RestingIndicator:SetPoint("TOPLEFT", self, "TOPLEFT", -6, 7)
        self.RestingIndicator:SetTexture(cfg.restingIcon)
        self.RestingIndicator:SetTexCoord(0, 1, 0, 1)
        self.RestingIndicator:SetDrawLayer("OVERLAY", 7)
    end
end
