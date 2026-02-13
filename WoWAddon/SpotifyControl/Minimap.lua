local ADDON_NAME, SC = ...

function SC:CreateMinimapButton()
    if not self.db.settings.showMinimapIcon then return end

    local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
    local LDBIcon = LibStub and LibStub("LibDBIcon-1.0", true)
    if not LDB or not LDBIcon then return end

    local dataObj = LDB:NewDataObject("SpotifyControl", {
        type = "launcher",
        icon = "Interface\\AddOns\\SpotifyControl\\Textures\\spotify-icon",
        label = "SpotifyControl",

        OnClick = function(self, button)
            if button == "LeftButton" then
                if SC.controlFrame and SC.controlFrame:IsShown() then
                    SC:HideControlFrame()
                else
                    SC:ShowControlFrame()
                end
            elseif button == "RightButton" then
                SC:ShowSettings()
            elseif button == "MiddleButton" then
                SC:QueueCommand("TOGGLE")
            end
        end,

        OnTooltipShow = function(tooltip)
            tooltip:AddLine("|cFF1DB954SpotifyControl|r")

            local info = SC.trackInfo
            if info and info.connected then
                if info.is_playing then
                    tooltip:AddLine("Playing: " .. (info.track_name or "Unknown"), 1, 1, 1)
                    tooltip:AddLine(info.artist_name or "", 0.7, 0.7, 0.7)
                else
                    tooltip:AddLine("Paused", 0.7, 0.7, 0.7)
                end
            else
                tooltip:AddLine("Companion not connected", 1, 0.3, 0.3)
            end

            tooltip:AddLine(" ")
            tooltip:AddLine("|cFFCCCCCCLeft-click:|r Toggle frame", 0.7, 0.7, 0.7)
            tooltip:AddLine("|cFFCCCCCCRight-click:|r Settings", 0.7, 0.7, 0.7)
            tooltip:AddLine("|cFFCCCCCCMiddle-click:|r Play/Pause", 0.7, 0.7, 0.7)
        end,
    })

    LDBIcon:Register("SpotifyControl", dataObj, self.db.minimap)
end
