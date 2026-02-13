local ADDON_NAME, SC = ...
SC.version = "1.0.0"
SC.loaded = false

-- Default database structures
SC.DB_DEFAULTS = {
    commandQueue = {},
    lastCommandId = 0,
    lastAckId = 0,
    settings = {
        autoReload = true,
        reloadDelay = 0.5,
        showMinimapIcon = true,
        showControlFrame = true,
        volumeStep = 10,
        locked = false,
    },
    minimap = {
        hide = false,
    },
}

SC.CHARDB_DEFAULTS = {
    framePoint = {"CENTER", nil, "CENTER", 0, 0},
    frameScale = 1.0,
}

-- Event frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_LOGOUT")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == ADDON_NAME then
            SC:OnAddonLoaded()
        end
    elseif event == "PLAYER_LOGIN" then
        SC:OnPlayerLogin()
    elseif event == "PLAYER_LOGOUT" then
        SC:OnPlayerLogout()
    end
end)

function SC:OnAddonLoaded()
    -- Initialize SavedVariables with defaults if first load
    if not SpotifyControlDB then
        SpotifyControlDB = {}
    end
    self.db = SpotifyControlDB

    -- Merge defaults (only set missing keys, preserve existing)
    for k, v in pairs(self.DB_DEFAULTS) do
        if self.db[k] == nil then
            if type(v) == "table" then
                self.db[k] = self:DeepCopy(v)
            else
                self.db[k] = v
            end
        end
    end
    -- Merge settings sub-table defaults
    if type(self.db.settings) == "table" then
        for k, v in pairs(self.DB_DEFAULTS.settings) do
            if self.db.settings[k] == nil then
                self.db.settings[k] = v
            end
        end
    end

    -- Initialize per-character DB
    if not SpotifyControlCharDB then
        SpotifyControlCharDB = {}
    end
    self.chardb = SpotifyControlCharDB
    for k, v in pairs(self.CHARDB_DEFAULTS) do
        if self.chardb[k] == nil then
            if type(v) == "table" then
                self.chardb[k] = self:DeepCopy(v)
            else
                self.chardb[k] = v
            end
        end
    end

    -- Read companion data (set by SpotifyControlData.lua loading)
    self:ReadCompanionData()

    -- Process acknowledgments (prune old commands)
    self:ProcessAcknowledgments()

    self.loaded = true
end

function SC:OnPlayerLogin()
    local status = "not connected"
    if self.trackInfo and self.trackInfo.connected then
        if self.trackInfo.is_playing then
            status = "playing: " .. (self.trackInfo.track_name or "Unknown")
                     .. " - " .. (self.trackInfo.artist_name or "Unknown")
        else
            status = "paused"
        end
    end
    self:Print("|cFF1DB954SpotifyControl|r v" .. self.version .. " loaded. Status: " .. status)
    self:Print("Type |cFFFFFF00/spotify help|r for commands.")

    -- Create UI
    SC:CreateControlFrame()
    SC:CreateMinimapButton()
    SC:UpdateUI()
end

function SC:OnPlayerLogout()
    -- SavedVariables will be flushed automatically by the client
end

function SC:ReadCompanionData()
    -- SpotifyControlData is a global set by SpotifyControlData.lua (loaded via TOC)
    if SpotifyControlData and type(SpotifyControlData) == "table" then
        self.trackInfo = SpotifyControlData
    else
        self.trackInfo = {connected = false}
    end
end

function SC:ProcessAcknowledgments()
    if self.trackInfo and self.trackInfo.last_ack_id then
        local ackId = self.trackInfo.last_ack_id
        if ackId > (self.db.lastAckId or 0) then
            self.db.lastAckId = ackId
        end
        -- Prune acknowledged commands from queue
        local newQueue = {}
        for _, cmd in ipairs(self.db.commandQueue or {}) do
            if cmd.id > self.db.lastAckId then
                table.insert(newQueue, cmd)
            end
        end
        self.db.commandQueue = newQueue
    end
end

function SC:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF1DB954[Spotify]|r " .. msg)
end

function SC:FormatTime(ms)
    local totalSec = math.floor((ms or 0) / 1000)
    local min = math.floor(totalSec / 60)
    local sec = totalSec % 60
    return string.format("%d:%02d", min, sec)
end

function SC:DeepCopy(orig)
    local copy = {}
    for k, v in pairs(orig) do
        if type(v) == "table" then
            copy[k] = self:DeepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end
