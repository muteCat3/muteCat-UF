
local addonName, ns = ...

-- =============================================================================
-- MUTE CAT UNIT FRAMES: MEDIA REGISTRATION
-- =============================================================================

local TEXTURE_BETTERBLIZZ = [[Interface\AddOns\muteCat UF\Media\Textures\BetterBlizzard.blp]]
local TEXTURE_DFSOFT       = [[Interface\AddOns\muteCat UF\Media\Textures\DF_Soft.tga]]

-- Global storage for fallback or external access
_G.muteCatUF_Media = {
    BetterBlizzard = TEXTURE_BETTERBLIZZ,
    DFSoft         = TEXTURE_DFSOFT,
}

--- Registers custom textures and backgrounds with LibSharedMedia-3.0.
--- @return boolean success
local function RegisterMedia()
    local lsm = LibStub and LibStub("LibSharedMedia-3.0", true)
    if not lsm then return false end

    -- Register Statusbars
    lsm:Register("statusbar", "!muteCat DF Soft", TEXTURE_DFSOFT)
    lsm:Register("statusbar", "muteCat DF Soft",  TEXTURE_DFSOFT)
    lsm:Register("statusbar", "DF Soft",          TEXTURE_DFSOFT)
    lsm:Register("statusbar", "DF_Soft",          TEXTURE_DFSOFT)

    lsm:Register("statusbar", "!muteCat BetterBlizzard", TEXTURE_BETTERBLIZZ)
    lsm:Register("statusbar", "muteCat BetterBlizzard",  TEXTURE_BETTERBLIZZ)
    lsm:Register("statusbar", "BetterBlizzard",          TEXTURE_BETTERBLIZZ)

    -- Register Backgrounds
    lsm:Register("background", "!muteCat DF Soft",        TEXTURE_DFSOFT)
    lsm:Register("background", "muteCat DF Soft",         TEXTURE_DFSOFT)
    lsm:Register("background", "!muteCat BetterBlizzard", TEXTURE_BETTERBLIZZ)
    lsm:Register("background", "muteCat BetterBlizzard",  TEXTURE_BETTERBLIZZ)

    return true
end

-- Attempt immediate registration
if not RegisterMedia() then
    -- Fallback to event-based registration if LibSharedMedia is loading late
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
    -- Standard registration on login to ensure all entries are present
    local refresher = CreateFrame("Frame")
    refresher:RegisterEvent("PLAYER_LOGIN")
    refresher:SetScript("OnEvent", function()
        RegisterMedia()
        refresher:UnregisterAllEvents()
    end)
end
