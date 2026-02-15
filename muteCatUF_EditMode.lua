local _, ns = ...

local LEM = LibStub and LibStub("LibEditMode", true)
if not LEM then
    return
end

local cfg = ns.config
local ensureLayout
local PLAYER_CLASS_TOKEN = select(2, UnitClass("player")) or "UNKNOWN"
local cachedSpecToken

local function isEditModeActive()
    return LEM.IsInEditMode and LEM:IsInEditMode()
end

local function clamp(value, minValue, maxValue)
    if value > maxValue then
        return maxValue
    end
    if value < minValue then
        return minValue
    end
    return value
end

local function copyPosition(src)
    return {
        point = src.point,
        x = src.x,
        y = src.y,
    }
end

local function copySize(src)
    return {
        width = src.width,
        height = src.height,
    }
end

local defaults = {
    player = { point = "CENTER", x = -420, y = -266 },
    target = { point = "CENTER", x = 420, y = -266 },
    focus = { point = "CENTER", x = 420, y = -226 },
    castbar = { point = "CENTER", x = cfg.castbarCenterX or 0, y = cfg.castbarCenterY or 0 },
    castbarSize = { width = cfg.castbarWidth, height = cfg.castbarHeight },
    secondaryResource = { point = "CENTER", x = 0, y = -40 },
    secondaryResourceSize = { width = cfg.secondaryBarWidth, height = cfg.secondaryBarHeight },
}

local function getSecondaryDefaultsForLayout(layoutName)
    if layoutName == "DPS" then
        return {
            position = { point = "CENTER", x = 0, y = -204 },
            size = { width = 182, height = 8 },
        }
    end

    if layoutName == "Default" or layoutName == "Tank/Heal" then
        return {
            position = { point = "CENTER", x = -1, y = -239 },
            size = { width = 224, height = 15 },
        }
    end

    return {
        position = defaults.secondaryResource,
        size = defaults.secondaryResourceSize,
    }
end

local function getDefaultPosition(layoutName, key)
    if key == "secondaryResource" then
        return getSecondaryDefaultsForLayout(layoutName).position
    end

    return defaults[key]
end

local function getDefaultSize(layoutName, key)
    if key == "secondaryResourceSize" then
        return getSecondaryDefaultsForLayout(layoutName).size
    end

    return defaults[key]
end

local function getPlayerClassToken()
    return PLAYER_CLASS_TOKEN
end

local function getSpecToken()
    if cachedSpecToken then
        return cachedSpecToken
    end

    if not GetSpecialization then
        cachedSpecToken = "NOSPEC"
        return cachedSpecToken
    end

    local specIndex = GetSpecialization()
    if not specIndex then
        cachedSpecToken = "NOSPEC"
        return cachedSpecToken
    end

    if GetSpecializationInfo then
        local specID = GetSpecializationInfo(specIndex)
        if specID then
            cachedSpecToken = tostring(specID)
            return cachedSpecToken
        end
    end

    cachedSpecToken = tostring(specIndex)
    return cachedSpecToken
end

local function getFrameApplyToken(layoutName)
    return table.concat({ layoutName, getPlayerClassToken(), getSpecToken() }, ":")
end

local function getCastbarPositionKey()
    return "castbar_" .. getPlayerClassToken() .. "_" .. getSpecToken()
end

local function getCastbarSizeKey()
    return "castbarSize_" .. getPlayerClassToken() .. "_" .. getSpecToken()
end

local function getSecondaryResourcePositionKey()
    return "secondaryResource_" .. getPlayerClassToken() .. "_" .. getSpecToken()
end

local function getSecondaryResourceSizeKey()
    return "secondaryResourceSize_" .. getPlayerClassToken() .. "_" .. getSpecToken()
end

local function ensureSecondaryResourceLayoutData(layoutName)
    local layout = ensureLayout(layoutName)
    local posKey = getSecondaryResourcePositionKey()
    local sizeKey = getSecondaryResourceSizeKey()

    if type(layout[posKey]) ~= "table" then
        layout[posKey] = copyPosition(getDefaultPosition(layoutName, "secondaryResource"))
    end

    if type(layout[sizeKey]) ~= "table" then
        layout[sizeKey] = copySize(getDefaultSize(layoutName, "secondaryResourceSize"))
    end

    return layout, posKey, sizeKey
end

local function ensureUnitFrameLayoutData(layoutName, key)
    local layout = ensureLayout(layoutName)
    local posKey = key

    if type(layout[posKey]) ~= "table" then
        layout[posKey] = copyPosition(getDefaultPosition(layoutName, key))
    end

    return layout, posKey
end

local function ensureCastbarLayoutData(layoutName)
    local layout = ensureLayout(layoutName)
    local posKey = getCastbarPositionKey()
    local sizeKey = getCastbarSizeKey()

    if type(layout[posKey]) ~= "table" then
        layout[posKey] = copyPosition(getDefaultPosition(layoutName, "castbar"))
    end

    if type(layout[sizeKey]) ~= "table" then
        layout[sizeKey] = copySize(getDefaultSize(layoutName, "castbarSize"))
    end

    return layout, posKey, sizeKey
end

local function resolveLayoutName(layoutName)
    if layoutName and layoutName ~= "" then
        return layoutName
    end

    if LEM.GetActiveLayoutName then
        local active = LEM:GetActiveLayoutName()
        if active and active ~= "" then
            return active
        end
    end

    return "Modern"
end

local function getActiveResolvedLayoutName()
    if LEM.GetActiveLayoutName then
        return resolveLayoutName(LEM:GetActiveLayoutName())
    end

    return resolveLayoutName(nil)
end

local function ensureDB()
    if type(_G.muteCatUFDB) ~= "table" then
        _G.muteCatUFDB = {}
    end

    if type(_G.muteCatUFDB.layouts) ~= "table" then
        _G.muteCatUFDB.layouts = {}
    end

    return _G.muteCatUFDB
end

ensureLayout = function(layoutName)
    local db = ensureDB()
    local name = resolveLayoutName(layoutName)

    if type(db.layouts[name]) ~= "table" then
        db.layouts[name] = {}
    end

    for key in pairs(defaults) do
        if type(db.layouts[name][key]) ~= "table" then
            if key == "castbarSize" then
                db.layouts[name][key] = copySize(getDefaultSize(name, key))
            elseif key == "secondaryResourceSize" then
                db.layouts[name][key] = copySize(getDefaultSize(name, key))
            else
                db.layouts[name][key] = copyPosition(getDefaultPosition(name, key))
            end
        end
    end

    return db.layouts[name]
end

local function getCastbarSize(layoutName)
    local layout, _, sizeKey = ensureCastbarLayoutData(layoutName)
    local size = layout[sizeKey]
    local defaultSize = getDefaultSize(layoutName, "castbarSize")
    local width = tonumber(size.width) or defaultSize.width
    local height = tonumber(size.height) or defaultSize.height
    return width, height
end

local function setCastbarSize(layoutName, width, height)
    local layout, _, sizeKey = ensureCastbarLayoutData(layoutName)
    local defaultSize = getDefaultSize(layoutName, "castbarSize")
    local size = layout[sizeKey]
    size.width = math.max(80, tonumber(width) or defaultSize.width)
    size.height = math.max(10, tonumber(height) or defaultSize.height)
end

local function getSecondaryResourceSize(layoutName)
    local layout, _, sizeKey = ensureSecondaryResourceLayoutData(layoutName)
    local size = layout[sizeKey]
    local defaultSize = getDefaultSize(layoutName, "secondaryResourceSize")
    local width = tonumber(size.width) or defaultSize.width
    local height = tonumber(size.height) or defaultSize.height
    return width, height
end

local function setSecondaryResourceSize(layoutName, width, height)
    local layout, _, sizeKey = ensureSecondaryResourceLayoutData(layoutName)
    local defaultSize = getDefaultSize(layoutName, "secondaryResourceSize")
    local size = layout[sizeKey]
    size.width = math.max(80, tonumber(width) or defaultSize.width)
    size.height = math.max(6, tonumber(height) or defaultSize.height)
end

local function isUnitFrameKey(key)
    return key == "player" or key == "target" or key == "focus"
end

local function resolvePositionRef(layoutName, key)
    local layout = ensureLayout(layoutName)
    local defaultPos = getDefaultPosition(layoutName, key)
    local pos = layout[key] or defaultPos

    if isUnitFrameKey(key) then
        local unitLayout, posKey = ensureUnitFrameLayoutData(layoutName, key)
        layout = unitLayout
        pos = layout[posKey] or defaultPos
    elseif key == "castbar" then
        local castbarLayout, posKey = ensureCastbarLayoutData(layoutName)
        layout = castbarLayout
        pos = layout[posKey] or defaultPos
    elseif key == "secondaryResource" then
        local secondaryLayout, posKey = ensureSecondaryResourceLayoutData(layoutName)
        layout = secondaryLayout
        pos = layout[posKey] or defaultPos
    end

    return layout, pos, defaultPos
end

local function applyFramePosition(frame, layoutName)
    if not frame or not frame.__mcEditKey then
        return
    end

    local _, pos, defaultPos = resolvePositionRef(layoutName, frame.__mcEditKey)
    if not pos then
        return
    end

    local x = tonumber(pos.x) or defaultPos.x
    local y = tonumber(pos.y) or defaultPos.y

    if x ~= x or y ~= y then
        x = defaultPos.x
        y = defaultPos.y
    end

    local parentW = UIParent:GetWidth() or 1920
    local parentH = UIParent:GetHeight() or 1080
    local frameW = frame:GetWidth() or 0
    local frameH = frame:GetHeight() or 0
    local maxX = math.max(50, (parentW * 0.5) - (frameW * 0.5))
    local maxY = math.max(50, (parentH * 0.5) - (frameH * 0.5))

    x = clamp(x, -maxX, maxX)
    y = clamp(y, -maxY, maxY)

    -- Keep stored values normalized so broken old values cannot re-apply later.
    pos.point = "CENTER"
    pos.x = x
    pos.y = y

    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", x, y)
end

local function applyFrameSize(frame, layoutName)
    if not frame or not frame.__mcEditKey then
        return
    end

    if frame.__mcEditKey == "castbar" then
        local width, height = getCastbarSize(resolveLayoutName(layoutName))
        if frame.__mcCastbar and ns.ApplyCastbarSize then
            ns.ApplyCastbarSize(frame.__mcCastbar, width, height)
        else
            frame:SetSize(width, height)
        end
        return
    end

    if frame.__mcEditKey == "secondaryResource" then
        local width, height = getSecondaryResourceSize(resolveLayoutName(layoutName))
        frame:SetSize(width, height)
        if frame.__mcSecondaryResourceBar and ns.ApplySecondaryResourceBarSize then
            ns.ApplySecondaryResourceBarSize(frame.__mcSecondaryResourceBar, width, height)
        end
    end
end

local function onPositionChanged(frame, layoutName, _, x, y)
    if not frame or not frame.__mcEditKey then
        return
    end

    local key = frame.__mcEditKey
    local _, pos = resolvePositionRef(layoutName, key)

    local cx, cy = frame:GetCenter()
    local pcx, pcy = UIParent:GetCenter()
    local newX, newY

    pos.point = "CENTER"
    if cx and cy and pcx and pcy then
        newX = cx - pcx
        newY = cy - pcy
    else
        newX = x
        newY = y
    end

    if pos.x ~= newX or pos.y ~= newY then
        pos.x = newX
        pos.y = newY
    end

    if key == "castbar" and frame.__mcCastbar and isEditModeActive() then
        frame.__mcCastbar:Show()
        frame:Show()
    elseif key == "secondaryResource" and frame.__mcSecondaryResourceBar and isEditModeActive() then
        frame.__mcSecondaryResourceBar:Show()
        frame:Show()
    end
end

local function setCastbarPreview(frames, enabled)
    local castbar = frames and frames.castbar
    local anchor = frames and frames.castbarAnchor
    if not castbar then
        return
    end

    if enabled then
        castbar.__mcPreview = true
        castbar.__mcPreviewOnUpdate = castbar.__mcPreviewOnUpdate or castbar:GetScript("OnUpdate")
        castbar:SetScript("OnUpdate", nil)
        castbar:SetMinMaxValues(0, 1)
        castbar:SetValue(0.6)
        if castbar.Text then
            castbar.Text:SetText("Castbar")
        end
        if castbar.Time then
            castbar.Time:SetText("1.2")
        end
        if castbar.Icon and not castbar.Icon:GetTexture() then
            castbar.Icon:SetTexture(136243)
        end
        castbar:Show()
        if anchor then
            if anchor.preview then
                anchor.preview:SetVertexColor(1, 1, 1, 0.08)
            end
            anchor:Show()
        end
    else
        castbar.__mcPreview = nil
        if castbar.__mcPreviewOnUpdate then
            castbar:SetScript("OnUpdate", castbar.__mcPreviewOnUpdate)
            castbar.__mcPreviewOnUpdate = nil
        end
        if castbar.Text then
            castbar.Text:SetText("")
        end
        if castbar.Time then
            castbar.Time:SetText("")
        end

        if not (castbar.casting or castbar.channeling or castbar.empowering) then
            castbar:Hide()
        end
        if anchor then
            if anchor.preview then
                anchor.preview:SetVertexColor(1, 1, 1, 0)
            end
        end
    end
end

local function setSecondaryResourcePreview(frames, enabled)
    local bar = frames and frames.secondaryResource
    local anchor = frames and frames.secondaryResourceAnchor
    if not bar then
        return
    end

    if enabled then
        bar.__mcPreview = true
        if ns.ApplySecondaryResourceBarSize then
            ns.ApplySecondaryResourceBarSize(bar, bar:GetWidth(), bar:GetHeight())
        end
        local classPower = bar.__mcClassPower or (ns.__mcPlayerFrame and ns.__mcPlayerFrame.ClassPower)
        if classPower then
            for i = 1, #classPower do
                local seg = classPower[i]
                if i <= 5 then
                    seg:SetMinMaxValues(0, 1)
                    seg:SetValue(i <= 3 and 1 or 0)
                    seg:Show()
                else
                    seg:Hide()
                end
            end
        end
        bar:Show()
        if anchor then
            if anchor.preview then
                anchor.preview:SetVertexColor(1, 1, 1, 0.08)
            end
            anchor:Show()
        end
    else
        bar.__mcPreview = nil
        if ns.UpdateSecondaryResourceBar then
            ns.UpdateSecondaryResourceBar()
        else
            bar:Hide()
        end
        if anchor and anchor.preview then
            anchor.preview:SetVertexColor(1, 1, 1, 0)
        end
    end
end

local callbacksRegistered = false
local roleWatcherRegistered = false

local function applyFramesForCurrentRoleLayout(frames)
    local layoutName = getActiveResolvedLayoutName()
    local token = getFrameApplyToken(layoutName)
    if ns.__mcLastFrameApplyToken == token then
        return
    end
    ns.__mcLastFrameApplyToken = token

    for _, frame in pairs(frames) do
        applyFramePosition(frame, layoutName)
        applyFrameSize(frame, layoutName)
    end
end

local function registerCallbacks(frames)
    if callbacksRegistered then
        return
    end

    LEM:RegisterCallback("layout", function()
        ns.__mcLastFrameApplyToken = nil
        applyFramesForCurrentRoleLayout(frames)
    end)

    LEM:RegisterCallback("create", function(layoutName, _, sourceLayoutName)
        local db = ensureDB()
        if sourceLayoutName and type(db.layouts[sourceLayoutName]) == "table" then
            local src = db.layouts[sourceLayoutName]
            local castPosKey = getCastbarPositionKey()
            local castSizeKey = getCastbarSizeKey()
            local posKey = getSecondaryResourcePositionKey()
            local sizeKey = getSecondaryResourceSizeKey()
            db.layouts[layoutName] = {
                player = copyPosition(src.player or defaults.player),
                target = copyPosition(src.target or defaults.target),
                focus = copyPosition(src.focus or defaults.focus),
                castbar = copyPosition(src.castbar or defaults.castbar),
                secondaryResource = copyPosition(src.secondaryResource or getDefaultPosition(layoutName, "secondaryResource")),
                castbarSize = {
                    width = (src.castbarSize and src.castbarSize.width) or defaults.castbarSize.width,
                    height = (src.castbarSize and src.castbarSize.height) or defaults.castbarSize.height,
                },
                secondaryResourceSize = {
                    width = (src.secondaryResourceSize and src.secondaryResourceSize.width) or getDefaultSize(layoutName, "secondaryResourceSize").width,
                    height = (src.secondaryResourceSize and src.secondaryResourceSize.height) or getDefaultSize(layoutName, "secondaryResourceSize").height,
                },
                [posKey] = copyPosition(src[posKey] or getDefaultPosition(layoutName, "secondaryResource")),
                [sizeKey] = copySize(src[sizeKey] or getDefaultSize(layoutName, "secondaryResourceSize")),
                [castPosKey] = copyPosition(src[castPosKey] or getDefaultPosition(layoutName, "castbar")),
                [castSizeKey] = copySize(src[castSizeKey] or getDefaultSize(layoutName, "castbarSize")),
            }
        else
            ensureLayout(layoutName)
        end
    end)

    LEM:RegisterCallback("rename", function(oldLayoutName, newLayoutName)
        local db = ensureDB()
        if type(db.layouts[oldLayoutName]) == "table" then
            db.layouts[newLayoutName] = db.layouts[oldLayoutName]
            db.layouts[oldLayoutName] = nil
        else
            ensureLayout(newLayoutName)
        end
    end)

    LEM:RegisterCallback("delete", function(layoutName)
        local db = ensureDB()
        db.layouts[layoutName] = nil
    end)

    LEM:RegisterCallback("enter", function()
        setCastbarPreview(frames, true)
        setSecondaryResourcePreview(frames, true)
    end)

    LEM:RegisterCallback("exit", function()
        setCastbarPreview(frames, false)
        setSecondaryResourcePreview(frames, false)
    end)

    if isEditModeActive() then
        setCastbarPreview(frames, true)
        setSecondaryResourcePreview(frames, true)
    end

    if not roleWatcherRegistered then
        local roleWatcher = CreateFrame("Frame")
        roleWatcher:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
        roleWatcher:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
        roleWatcher:SetScript("OnEvent", function(_, _, unit)
            if unit and unit ~= "player" then
                return
            end
            cachedSpecToken = nil
            applyFramesForCurrentRoleLayout(frames)
        end)
        roleWatcherRegistered = true
    end

    callbacksRegistered = true
end

local function registerFrame(frame, key, label)
    if not frame or frame.__mcEditRegistered then
        if frame and not frame.__mcEditKey then
            frame.__mcEditKey = key
        end
        return
    end

    frame.__mcEditKey = key
    LEM:AddFrame(frame, onPositionChanged, defaults[key], label)
    frame.__mcEditRegistered = true
end

local function addCastbarSettings(castbarFrame)
    if not LEM.SettingType or not castbarFrame or castbarFrame.__mcSettingsRegistered then
        return
    end

    LEM:AddFrameSettings(castbarFrame, {
        {
            name = "X",
            kind = LEM.SettingType.Slider,
            default = defaults.castbar.x,
            get = function(layoutName)
                local layout, posKey = ensureCastbarLayoutData(layoutName)
                return tonumber(layout[posKey].x) or defaults.castbar.x
            end,
            set = function(layoutName, value)
                local layout, posKey = ensureCastbarLayoutData(layoutName)
                local pos = layout[posKey]
                pos.point = "CENTER"
                pos.x = tonumber(value) or defaults.castbar.x
                pos.y = tonumber(pos.y) or defaults.castbar.y
                applyFramePosition(castbarFrame, layoutName)
            end,
            minValue = -1200,
            maxValue = 1200,
            valueStep = 0.5,
            formatter = function(value)
                return string.format("%.1f", value)
            end,
        },
        {
            name = "Y",
            kind = LEM.SettingType.Slider,
            default = defaults.castbar.y,
            get = function(layoutName)
                local layout, posKey = ensureCastbarLayoutData(layoutName)
                return tonumber(layout[posKey].y) or defaults.castbar.y
            end,
            set = function(layoutName, value)
                local layout, posKey = ensureCastbarLayoutData(layoutName)
                local pos = layout[posKey]
                pos.point = "CENTER"
                pos.x = tonumber(pos.x) or defaults.castbar.x
                pos.y = tonumber(value) or defaults.castbar.y
                applyFramePosition(castbarFrame, layoutName)
            end,
            minValue = -800,
            maxValue = 800,
            valueStep = 0.5,
            formatter = function(value)
                return string.format("%.1f", value)
            end,
        },
        {
            name = "Width",
            kind = LEM.SettingType.Slider,
            default = defaults.castbarSize.width,
            get = function(layoutName)
                local width = getCastbarSize(layoutName)
                return width
            end,
            set = function(layoutName, value)
                local _, height = getCastbarSize(layoutName)
                setCastbarSize(layoutName, value, height)
                applyFrameSize(castbarFrame, layoutName)
            end,
            minValue = 120,
            maxValue = 400,
            valueStep = 0.5,
            formatter = function(value)
                return string.format("%.1f", value)
            end,
        },
        {
            name = "Height",
            kind = LEM.SettingType.Slider,
            default = defaults.castbarSize.height,
            get = function(layoutName)
                local _, height = getCastbarSize(layoutName)
                return height
            end,
            set = function(layoutName, value)
                local width = getCastbarSize(layoutName)
                setCastbarSize(layoutName, width, value)
                applyFrameSize(castbarFrame, layoutName)
            end,
            minValue = 10,
            maxValue = 40,
            valueStep = 0.5,
            formatter = function(value)
                return string.format("%.1f", value)
            end,
        },
    })
    castbarFrame.__mcSettingsRegistered = true
end

local function addUnitFramePositionSettings(frame, key, minX, maxX, minY, maxY)
    if not LEM.SettingType or not frame or frame.__mcUnitPositionSettingsRegistered or not key then
        return
    end

    local defaultPos = defaults[key]
    if not defaultPos then
        return
    end

    LEM:AddFrameSettings(frame, {
        {
            name = "X",
            kind = LEM.SettingType.Slider,
            default = defaultPos.x,
            get = function(layoutName)
                local layout, posKey = ensureUnitFrameLayoutData(layoutName, key)
                return tonumber(layout[posKey].x) or defaultPos.x
            end,
            set = function(layoutName, value)
                local layout, posKey = ensureUnitFrameLayoutData(layoutName, key)
                local pos = layout[posKey]
                pos.point = "CENTER"
                pos.x = tonumber(value) or defaultPos.x
                pos.y = tonumber(pos.y) or defaultPos.y
                applyFramePosition(frame, layoutName)
            end,
            minValue = minX or -1200,
            maxValue = maxX or 1200,
            valueStep = 0.5,
            formatter = function(value)
                return string.format("%.1f", value)
            end,
        },
        {
            name = "Y",
            kind = LEM.SettingType.Slider,
            default = defaultPos.y,
            get = function(layoutName)
                local layout, posKey = ensureUnitFrameLayoutData(layoutName, key)
                return tonumber(layout[posKey].y) or defaultPos.y
            end,
            set = function(layoutName, value)
                local layout, posKey = ensureUnitFrameLayoutData(layoutName, key)
                local pos = layout[posKey]
                pos.point = "CENTER"
                pos.x = tonumber(pos.x) or defaultPos.x
                pos.y = tonumber(value) or defaultPos.y
                applyFramePosition(frame, layoutName)
            end,
            minValue = minY or -800,
            maxValue = maxY or 800,
            valueStep = 0.5,
            formatter = function(value)
                return string.format("%.1f", value)
            end,
        },
    })

    frame.__mcUnitPositionSettingsRegistered = true
end

local function addSecondaryResourceSettings(secondaryFrame)
    if not LEM.SettingType or not secondaryFrame or secondaryFrame.__mcSettingsRegistered then
        return
    end

    LEM:AddFrameSettings(secondaryFrame, {
        {
            name = "X",
            kind = LEM.SettingType.Slider,
            default = defaults.secondaryResource.x,
            get = function(layoutName)
                local layout, posKey = ensureSecondaryResourceLayoutData(layoutName)
                local defaultPos = getDefaultPosition(layoutName, "secondaryResource")
                return tonumber(layout[posKey].x) or defaultPos.x
            end,
            set = function(layoutName, value)
                local layout, posKey = ensureSecondaryResourceLayoutData(layoutName)
                local pos = layout[posKey]
                local defaultPos = getDefaultPosition(layoutName, "secondaryResource")
                pos.point = "CENTER"
                pos.x = tonumber(value) or defaultPos.x
                pos.y = tonumber(pos.y) or defaultPos.y
                applyFramePosition(secondaryFrame, layoutName)
            end,
            minValue = -1200,
            maxValue = 1200,
            valueStep = 0.5,
            formatter = function(value)
                return string.format("%.1f", value)
            end,
        },
        {
            name = "Y",
            kind = LEM.SettingType.Slider,
            default = defaults.secondaryResource.y,
            get = function(layoutName)
                local layout, posKey = ensureSecondaryResourceLayoutData(layoutName)
                local defaultPos = getDefaultPosition(layoutName, "secondaryResource")
                return tonumber(layout[posKey].y) or defaultPos.y
            end,
            set = function(layoutName, value)
                local layout, posKey = ensureSecondaryResourceLayoutData(layoutName)
                local pos = layout[posKey]
                local defaultPos = getDefaultPosition(layoutName, "secondaryResource")
                pos.point = "CENTER"
                pos.x = tonumber(pos.x) or defaultPos.x
                pos.y = tonumber(value) or defaultPos.y
                applyFramePosition(secondaryFrame, layoutName)
            end,
            minValue = -800,
            maxValue = 800,
            valueStep = 0.5,
            formatter = function(value)
                return string.format("%.1f", value)
            end,
        },
        {
            name = "Width",
            kind = LEM.SettingType.Slider,
            default = defaults.secondaryResourceSize.width,
            get = function(layoutName)
                local width = getSecondaryResourceSize(layoutName)
                return width
            end,
            set = function(layoutName, value)
                local _, height = getSecondaryResourceSize(layoutName)
                setSecondaryResourceSize(layoutName, value, height)
                applyFrameSize(secondaryFrame, layoutName)
            end,
            minValue = 120,
            maxValue = 400,
            valueStep = 0.5,
            formatter = function(value)
                return string.format("%.1f", value)
            end,
        },
        {
            name = "Height",
            kind = LEM.SettingType.Slider,
            default = defaults.secondaryResourceSize.height,
            get = function(layoutName)
                local _, height = getSecondaryResourceSize(layoutName)
                return height
            end,
            set = function(layoutName, value)
                local width = getSecondaryResourceSize(layoutName)
                setSecondaryResourceSize(layoutName, width, value)
                applyFrameSize(secondaryFrame, layoutName)
            end,
            minValue = 6,
            maxValue = 40,
            valueStep = 0.5,
            formatter = function(value)
                return string.format("%.1f", value)
            end,
        },
    })
    secondaryFrame.__mcSettingsRegistered = true
end

function ns.SetupEditMode(playerFrame, targetFrame, focusFrame, castbarFrame, secondaryResourceFrame)
    if not playerFrame or not targetFrame or not castbarFrame then
        return
    end
    local castbarAnchor = ns.CastbarAnchor or castbarFrame
    local secondaryResourceAnchor = ns.SecondaryResourceAnchor or secondaryResourceFrame

    registerFrame(playerFrame, "player", "muteCat UF: Player")
    registerFrame(targetFrame, "target", "muteCat UF: Target")
    if focusFrame then
        registerFrame(focusFrame, "focus", "muteCat UF: Focus")
    end
    registerFrame(castbarAnchor, "castbar", "muteCat UF: Castbar")
    addUnitFramePositionSettings(playerFrame, "player", -1200, 1200, -800, 800)
    addUnitFramePositionSettings(targetFrame, "target", -1200, 1200, -800, 800)
    castbarAnchor.__mcCastbar = castbarFrame
    addCastbarSettings(castbarAnchor)
    if secondaryResourceAnchor and secondaryResourceFrame then
        registerFrame(secondaryResourceAnchor, "secondaryResource", "muteCat UF: Secondary Resource")
        secondaryResourceAnchor.__mcSecondaryResourceBar = secondaryResourceFrame
        secondaryResourceFrame.__mcClassPower = playerFrame and playerFrame.ClassPower
        addSecondaryResourceSettings(secondaryResourceAnchor)
    end

    local frames = {
        player = playerFrame,
        target = targetFrame,
        focus = focusFrame,
        castbar = castbarFrame,
        castbarAnchor = castbarAnchor,
        secondaryResource = secondaryResourceFrame,
        secondaryResourceAnchor = secondaryResourceAnchor,
    }

    registerCallbacks(frames)
    ns.__mcLastFrameApplyToken = nil
    applyFramesForCurrentRoleLayout(frames)
end

function ns.RefreshCastbarFromEditMode(castbarFrame)
    if not castbarFrame then
        return
    end

    local layoutName = getActiveResolvedLayoutName()
    local anchor = ns.CastbarAnchor or castbarFrame
    anchor.__mcCastbar = castbarFrame
    anchor.__mcEditKey = "castbar"
    applyFramePosition(anchor, layoutName)
    applyFrameSize(anchor, layoutName)
end
