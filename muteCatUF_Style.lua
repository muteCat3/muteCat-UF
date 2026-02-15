local _, ns = ...
local cfg = ns.config

local holyPowerColor = (PowerBarColor and (PowerBarColor.HOLY_POWER or (Enum and Enum.PowerType and PowerBarColor[Enum.PowerType.HolyPower]))) or {
    r = 0.95,
    g = 0.9,
    b = 0.6,
}

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

    castbar:SetAlpha(1)
    castbar:Show()
end

local function EnsureCastbarAnchor()
    if ns.CastbarAnchor then
        return ns.CastbarAnchor
    end

    local anchor = CreateFrame("Frame", "muteCatUF_CastbarAnchor", UIParent)
    anchor:SetPoint("CENTER", UIParent, "CENTER", cfg.castbarCenterX, cfg.castbarCenterY)
    anchor:SetSize(cfg.castbarWidth, cfg.castbarHeight)
    anchor:SetFrameStrata("MEDIUM")
    anchor:EnableMouse(false)

    anchor.preview = anchor:CreateTexture(nil, "BACKGROUND")
    anchor.preview:SetAllPoints(anchor)
    anchor.preview:SetTexture("Interface\\Buttons\\WHITE8x8")
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
    if ns.CastbarAnchor then
        ns.CastbarAnchor:SetSize(w, h)
    end
    if castbar.Icon then
        castbar.Icon:SetSize(h, h)
    end
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

    if unit == "player" then
        if self.Name:IsShown() then
            self.Name:Hide()
        end
        self.Name:SetText("")
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

local function HealthPostUpdate(health, unit, cur)
    local self = health.__owner
    if self and self.HealthValue then
        UpdateNameDisplay(self, unit)

        local r, g, b
        if unit == "target" or unit == "focus" then
            r, g, b = 1, 1, 1
        else
            r, g, b = ns.GetClassColor(unit)
        end
        if self.__mcHealthR ~= r or self.__mcHealthG ~= g or self.__mcHealthB ~= b then
            self.__mcHealthR, self.__mcHealthG, self.__mcHealthB = r, g, b
            self.HealthValue:SetTextColor(r, g, b, 1)
        end

        self.HealthValue:SetText(ns.ShortValue(cur or 0))
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
    self.borderTop:SetTexture("Interface\\Buttons\\WHITE8x8")
    self.borderTop:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
    self.borderTop:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, 0)
    self.borderTop:SetHeight(1)

    self.borderBottom = self:CreateTexture(nil, "BORDER")
    self.borderBottom:SetTexture("Interface\\Buttons\\WHITE8x8")
    self.borderBottom:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, 0)
    self.borderBottom:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
    self.borderBottom:SetHeight(1)

    self.borderLeft = self:CreateTexture(nil, "BORDER")
    self.borderLeft:SetTexture("Interface\\Buttons\\WHITE8x8")
    self.borderLeft:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
    self.borderLeft:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, 0)
    self.borderLeft:SetWidth(1)

    self.borderRight = self:CreateTexture(nil, "BORDER")
    self.borderRight:SetTexture("Interface\\Buttons\\WHITE8x8")
    self.borderRight:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, 0)
    self.borderRight:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
    self.borderRight:SetWidth(1)

    self.borderTop:SetVertexColor(0, 0, 0, 1)
    self.borderBottom:SetVertexColor(0, 0, 0, 1)
    self.borderLeft:SetVertexColor(0, 0, 0, 1)
    self.borderRight:SetVertexColor(0, 0, 0, 1)

    local health = CreateFrame("StatusBar", nil, self)
    health:SetPoint("TOPLEFT", self, "TOPLEFT", cfg.innerPadding, -cfg.innerPadding)
    health:SetPoint("TOPRIGHT", self, "TOPRIGHT", -cfg.innerPadding, -cfg.innerPadding)
    health:SetHeight(cfg.healthHeightWithPower)
    health:SetStatusBarTexture(cfg.barTexture)
    health:SetStatusBarColor(cfg.healthForeground[1], cfg.healthForeground[2], cfg.healthForeground[3], cfg.healthForeground[4])
    health.frequentUpdates = true
    health.PostUpdate = HealthPostUpdate

    health.bg = health:CreateTexture(nil, "BACKGROUND")
    health.bg:SetAllPoints(health)
    health.bg:SetTexture(cfg.barTexture)
    health.bg:SetVertexColor(cfg.healthBackground[1], cfg.healthBackground[2], cfg.healthBackground[3], cfg.healthBackground[4])

    self.Health = health

    local power = CreateFrame("StatusBar", nil, self)
    power:SetPoint("TOPLEFT", health, "BOTTOMLEFT", 0, 0)
    power:SetPoint("TOPRIGHT", health, "BOTTOMRIGHT", 0, 0)
    power:SetHeight(cfg.powerHeight)
    power:SetStatusBarTexture(cfg.barTexture)
    power.frequentUpdates = true
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

    if unit == "player" then
        self.Name:Hide()
    else
        self.Name:Show()
    end

    self.HealthValue = health:CreateFontString(nil, "OVERLAY")
    self.HealthValue:SetFont("Fonts\\FRIZQT__.TTF", 10, "THINOUTLINE")
    self.HealthValue:SetPoint("RIGHT", health, "RIGHT", -3, 0)
    self.HealthValue:SetJustifyH("RIGHT")
    self.HealthValue:SetTextColor(0, 0, 0, 1)
    self.HealthValue:SetText("0")

    if unit == "player" then
        local castbarAnchor = EnsureCastbarAnchor()
        local castbar = CreateFrame("StatusBar", nil, UIParent)
        castbar:SetPoint("CENTER", castbarAnchor, "CENTER", 0, 0)
        ns.ApplyCastbarSize(castbar, cfg.castbarWidth, cfg.castbarHeight)
        castbar:SetStatusBarTexture(cfg.barTexture)
        castbar:SetStatusBarColor(holyPowerColor.r, holyPowerColor.g, holyPowerColor.b, 1)
        castbar:SetFrameStrata("MEDIUM")
        castbar:SetFrameLevel((castbarAnchor:GetFrameLevel() or 1) + 5)
        castbar:SetIgnoreParentAlpha(true)
        castbar.timeToHold = 0.15
        castbar.smoothing = (Enum and Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.Immediate) or 0

        castbar.bg = castbar:CreateTexture(nil, "BACKGROUND")
        castbar.bg:SetAllPoints(castbar)
        castbar.bg:SetTexture(cfg.barTexture)
        castbar.bg:SetVertexColor(0, 0, 0, 0.55)

        castbar.Icon = castbar:CreateTexture(nil, "ARTWORK")
        castbar.Icon:SetSize(cfg.castbarHeight, cfg.castbarHeight)
        castbar.Icon:SetPoint("RIGHT", castbar, "LEFT", 0, 0)
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
        castbar.SafeZone:SetTexture("Interface\\Buttons\\WHITE8x8")
        castbar.SafeZone:SetVertexColor(0.9, 0.2, 0.2, 0.4)
        castbar.PostCastStart = CastbarPostStart
        castbar.PostChannelStart = CastbarPostStart

        self.Castbar = castbar

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
