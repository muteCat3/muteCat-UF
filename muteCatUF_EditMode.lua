local _, ns = ...

local LEM = LibStub and LibStub("LibEditMode", true)
if not LEM then
    return
end

local cfg = ns.config

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
}

local function resolveLayoutName(layoutName)
    if layoutName and layoutName ~= "" then
        return layoutName
    end

    if LEM and LEM.GetActiveLayoutName then
        local active = LEM:GetActiveLayoutName()
        if active and active ~= "" then
            return active
        end
    end

    return "Modern"
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

local function ensureLayout(layoutName)
    local db = ensureDB()
    local name = resolveLayoutName(layoutName)

    if type(db.layouts[name]) ~= "table" then
        db.layouts[name] = {}
    end

    for key, defaultPos in pairs(defaults) do
        if type(db.layouts[name][key]) ~= "table" then
            if key == "castbarSize" then
                db.layouts[name][key] = copySize(defaultPos)
            else
                db.layouts[name][key] = copyPosition(defaultPos)
            end
        end
    end

    return db.layouts[name]
end

local function getCastbarSize(layoutName)
    local layout = ensureLayout(resolveLayoutName(layoutName))
    if type(layout.castbarSize) ~= "table" then
        layout.castbarSize = copySize(defaults.castbarSize)
    end

    local width = tonumber(layout.castbarSize.width) or defaults.castbarSize.width
    local height = tonumber(layout.castbarSize.height) or defaults.castbarSize.height
    return width, height
end

local function setCastbarSize(layoutName, width, height)
    local layout = ensureLayout(resolveLayoutName(layoutName))
    layout.castbarSize = layout.castbarSize or {}
    layout.castbarSize.width = math.max(80, tonumber(width) or defaults.castbarSize.width)
    layout.castbarSize.height = math.max(10, tonumber(height) or defaults.castbarSize.height)
end

local function applyFramePosition(frame, layoutName)
    if not frame or not frame.__mcEditKey then
        return
    end

    local layout = ensureLayout(resolveLayoutName(layoutName))
    local pos = layout[frame.__mcEditKey] or defaults[frame.__mcEditKey]
    if not pos then
        return
    end

    local x = tonumber(pos.x) or defaults[frame.__mcEditKey].x
    local y = tonumber(pos.y) or defaults[frame.__mcEditKey].y

    if x ~= x or y ~= y then
        x = defaults[frame.__mcEditKey].x
        y = defaults[frame.__mcEditKey].y
    end

    local parentW = UIParent:GetWidth() or 1920
    local parentH = UIParent:GetHeight() or 1080
    local frameW = frame:GetWidth() or 0
    local frameH = frame:GetHeight() or 0
    local maxX = math.max(50, (parentW * 0.5) - (frameW * 0.5))
    local maxY = math.max(50, (parentH * 0.5) - (frameH * 0.5))

    if x > maxX then x = maxX end
    if x < -maxX then x = -maxX end
    if y > maxY then y = maxY end
    if y < -maxY then y = -maxY end

    -- Keep stored values normalized so broken old values cannot re-apply later.
    pos.point = "CENTER"
    pos.x = x
    pos.y = y

    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", x, y)
end

local function applyCastbarSize(frame, layoutName)
    if not frame or frame.__mcEditKey ~= "castbar" then
        return
    end

    local width, height = getCastbarSize(resolveLayoutName(layoutName))
    frame:SetSize(width, height)
    if frame.__mcCastbar and ns.ApplyCastbarSize then
        ns.ApplyCastbarSize(frame.__mcCastbar, width, height)
    end
end

local function onPositionChanged(frame, layoutName, point, x, y)
    if not frame or not frame.__mcEditKey then
        return
    end

    local resolvedLayout = resolveLayoutName(layoutName)
    local layout = ensureLayout(resolvedLayout)
    local key = frame.__mcEditKey
    layout[key].point = point
    layout[key].x = x
    layout[key].y = y

    if key == "castbar" and frame.__mcCastbar and LEM.IsInEditMode and LEM:IsInEditMode() then
        frame.__mcCastbar:Show()
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

local callbacksRegistered = false
local function registerCallbacks(frames)
    if callbacksRegistered then
        return
    end

    LEM:RegisterCallback("layout", function(layoutName)
        for _, frame in pairs(frames) do
            applyFramePosition(frame, layoutName)
            applyCastbarSize(frame, layoutName)
        end
    end)

    LEM:RegisterCallback("create", function(layoutName, _, sourceLayoutName)
        local db = ensureDB()
        if sourceLayoutName and type(db.layouts[sourceLayoutName]) == "table" then
            local src = db.layouts[sourceLayoutName]
            db.layouts[layoutName] = {
                player = copyPosition(src.player or defaults.player),
                target = copyPosition(src.target or defaults.target),
                focus = copyPosition(src.focus or defaults.focus),
                castbar = copyPosition(src.castbar or defaults.castbar),
                castbarSize = {
                    width = (src.castbarSize and src.castbarSize.width) or defaults.castbarSize.width,
                    height = (src.castbarSize and src.castbarSize.height) or defaults.castbarSize.height,
                },
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
    end)

    LEM:RegisterCallback("exit", function()
        setCastbarPreview(frames, false)
    end)

    if LEM.IsInEditMode and LEM:IsInEditMode() then
        setCastbarPreview(frames, true)
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
                local layout = ensureLayout(layoutName)
                return tonumber(layout.castbar.x) or defaults.castbar.x
            end,
            set = function(layoutName, value)
                local layout = ensureLayout(layoutName)
                layout.castbar.point = "CENTER"
                layout.castbar.x = tonumber(value) or defaults.castbar.x
                layout.castbar.y = tonumber(layout.castbar.y) or defaults.castbar.y
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
                local layout = ensureLayout(layoutName)
                return tonumber(layout.castbar.y) or defaults.castbar.y
            end,
            set = function(layoutName, value)
                local layout = ensureLayout(layoutName)
                layout.castbar.point = "CENTER"
                layout.castbar.x = tonumber(layout.castbar.x) or defaults.castbar.x
                layout.castbar.y = tonumber(value) or defaults.castbar.y
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
                applyCastbarSize(castbarFrame, layoutName)
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
                applyCastbarSize(castbarFrame, layoutName)
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

function ns.SetupEditMode(playerFrame, targetFrame, focusFrame, castbarFrame)
    if not playerFrame or not targetFrame or not castbarFrame then
        return
    end
    local castbarAnchor = ns.CastbarAnchor or castbarFrame

    registerFrame(playerFrame, "player", "muteCat UF: Player")
    registerFrame(targetFrame, "target", "muteCat UF: Target")
    if focusFrame then
        registerFrame(focusFrame, "focus", "muteCat UF: Focus")
    end
    registerFrame(castbarAnchor, "castbar", "muteCat UF: Castbar")
    castbarAnchor.__mcCastbar = castbarFrame
    addCastbarSettings(castbarAnchor)

    local frames = {
        player = playerFrame,
        target = targetFrame,
        focus = focusFrame,
        castbar = castbarFrame,
        castbarAnchor = castbarAnchor,
    }

    registerCallbacks(frames)

    local layoutName = resolveLayoutName(LEM:GetActiveLayoutName())
    applyFramePosition(playerFrame, layoutName)
    applyFramePosition(targetFrame, layoutName)
    if focusFrame then
        applyFramePosition(focusFrame, layoutName)
    end
    applyFramePosition(castbarAnchor, layoutName)
    applyCastbarSize(castbarAnchor, layoutName)
end

function ns.RefreshCastbarFromEditMode(castbarFrame)
    if not castbarFrame then
        return
    end

    local layoutName = resolveLayoutName(LEM:GetActiveLayoutName())
    local anchor = ns.CastbarAnchor or castbarFrame
    anchor.__mcCastbar = castbarFrame
    anchor.__mcEditKey = "castbar"
    applyFramePosition(anchor, layoutName)
    applyCastbarSize(anchor, layoutName)
end
