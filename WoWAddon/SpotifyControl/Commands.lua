local ADDON_NAME, SC = ...

SLASH_SPOTIFYCONTROL1 = "/spotify"
SLASH_SPOTIFYCONTROL2 = "/sp"

SlashCmdList["SPOTIFYCONTROL"] = function(msg)
    local args = {}
    for word in msg:gmatch("%S+") do
        table.insert(args, word:lower())
    end

    local cmd = args[1] or "help"

    if cmd == "play" then
        SC:QueueCommand("PLAY")
    elseif cmd == "pause" then
        SC:QueueCommand("PAUSE")
    elseif cmd == "toggle" or cmd == "pp" then
        SC:QueueCommand("TOGGLE")
    elseif cmd == "next" or cmd == "skip" then
        SC:QueueCommand("NEXT")
    elseif cmd == "prev" or cmd == "previous" or cmd == "back" then
        SC:QueueCommand("PREV")
    elseif cmd == "vol" or cmd == "volume" then
        local subcmd = args[2]
        if subcmd == "up" then
            SC:QueueCommand("VOL_UP")
        elseif subcmd == "down" then
            SC:QueueCommand("VOL_DOWN")
        elseif tonumber(subcmd) then
            local vol = math.max(0, math.min(100, tonumber(subcmd)))
            SC:QueueCommand("VOL_SET", tostring(vol))
        else
            SC:Print("Usage: /spotify vol <up|down|0-100>")
        end
    elseif cmd == "shuffle" then
        local subcmd = args[2]
        if subcmd == "on" then
            SC:QueueCommand("SHUFFLE_ON")
        elseif subcmd == "off" then
            SC:QueueCommand("SHUFFLE_OFF")
        else
            SC:Print("Usage: /spotify shuffle <on|off>")
        end
    elseif cmd == "repeat" then
        local subcmd = args[2]
        if subcmd == "off" then
            SC:QueueCommand("REPEAT_OFF")
        elseif subcmd == "track" then
            SC:QueueCommand("REPEAT_TRACK")
        elseif subcmd == "context" or subcmd == "playlist" then
            SC:QueueCommand("REPEAT_CONTEXT")
        else
            SC:Print("Usage: /spotify repeat <off|track|context>")
        end
    elseif cmd == "sync" or cmd == "refresh" then
        SC:TriggerSync()
    elseif cmd == "status" then
        SC:PrintStatus()
    elseif cmd == "show" then
        SC:ShowControlFrame()
    elseif cmd == "hide" then
        SC:HideControlFrame()
    elseif cmd == "settings" or cmd == "config" or cmd == "options" then
        SC:ShowSettings()
    elseif cmd == "help" then
        SC:PrintHelp()
    else
        SC:Print("Unknown command: " .. cmd .. ". Type /spotify help for usage.")
    end
end

function SC:PrintStatus()
    local info = self.trackInfo
    if not info or not info.connected then
        self:Print("Companion app is not connected.")
        self:Print("Make sure the companion is running and you have synced (/spotify sync).")
        return
    end

    if info.is_playing then
        self:Print("Now playing: |cFFFFFFFF" .. (info.track_name or "Unknown") .. "|r")
        self:Print("Artist: |cFFCCCCCC" .. (info.artist_name or "Unknown") .. "|r")
        self:Print("Album: |cFFCCCCCC" .. (info.album_name or "Unknown") .. "|r")

        local progress = self:FormatTime(info.track_progress_ms or 0)
        local duration = self:FormatTime(info.track_duration_ms or 0)
        self:Print("Progress: " .. progress .. " / " .. duration)
        self:Print("Volume: " .. (info.volume_percent or "?") .. "%")
    else
        self:Print("Spotify is paused.")
        if info.track_name then
            self:Print("Last track: " .. info.track_name)
        end
    end

    local pending = self:GetPendingCommandCount()
    if pending > 0 then
        self:Print("|cFFFF8800" .. pending .. " command(s) pending sync.|r")
    end
end

function SC:PrintHelp()
    self:Print("=== SpotifyControl Commands ===")
    self:Print("|cFFFFFF00/spotify play|r - Start playback")
    self:Print("|cFFFFFF00/spotify pause|r - Pause playback")
    self:Print("|cFFFFFF00/spotify toggle|r (or pp) - Toggle play/pause")
    self:Print("|cFFFFFF00/spotify next|r (or skip) - Next track")
    self:Print("|cFFFFFF00/spotify prev|r (or back) - Previous track")
    self:Print("|cFFFFFF00/spotify vol up|r - Volume up")
    self:Print("|cFFFFFF00/spotify vol down|r - Volume down")
    self:Print("|cFFFFFF00/spotify vol <0-100>|r - Set volume")
    self:Print("|cFFFFFF00/spotify shuffle <on|off>|r - Toggle shuffle")
    self:Print("|cFFFFFF00/spotify repeat <off|track|context>|r - Repeat mode")
    self:Print("|cFFFFFF00/spotify sync|r - Sync with companion (reloads UI)")
    self:Print("|cFFFFFF00/spotify status|r - Show current track info")
    self:Print("|cFFFFFF00/spotify show|r / |cFFFFFF00hide|r - Toggle control frame")
    self:Print("|cFFFFFF00/spotify settings|r - Open settings panel")
end
