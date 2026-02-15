local addonName = ...
local texturePath = "Interface\\AddOns\\" .. addonName .. "\\Media\\Textures\\BetterBlizzard.blp"

_G.muteCatUF_Media = _G.muteCatUF_Media or {}
_G.muteCatUF_Media.BetterBlizzard = texturePath

local function RegisterMedia()
    if type(LibStub) ~= "function" then
        return false
    end

    local lsm = LibStub("LibSharedMedia-3.0", true)
    if not lsm then
        return false
    end

    -- Multiple aliases to improve discoverability in addon media dropdowns.
    lsm:Register("statusbar", "muteCat BetterBlizzard", texturePath)
    lsm:Register("statusbar", "BetterBlizzard", texturePath)
    lsm:Register("statusbar", "Better Blizzard", texturePath)

    -- Some addons browse a different media class for bar-like textures.
    lsm:Register("background", "muteCat BetterBlizzard", texturePath)
    lsm:Register("background", "BetterBlizzard", texturePath)
    lsm:Register("background", "Better Blizzard", texturePath)

    return true
end

if not RegisterMedia() then
    local waiter = CreateFrame("Frame")
    waiter:RegisterEvent("PLAYER_LOGIN")
    waiter:RegisterEvent("ADDON_LOADED")
    waiter:SetScript("OnEvent", function(_, event, loadedName)
        if event == "ADDON_LOADED" and loadedName ~= addonName and loadedName ~= "LibSharedMedia-3.0" then
            return
        end

        if RegisterMedia() then
            waiter:UnregisterAllEvents()
            waiter:SetScript("OnEvent", nil)
        end
    end)
else
    local refresher = CreateFrame("Frame")
    refresher:RegisterEvent("PLAYER_LOGIN")
    refresher:SetScript("OnEvent", function()
        RegisterMedia()
        refresher:UnregisterAllEvents()
        refresher:SetScript("OnEvent", nil)
    end)
end
