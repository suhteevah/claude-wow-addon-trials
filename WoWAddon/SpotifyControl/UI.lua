local ADDON_NAME, SC = ...

function SC:CreateControlFrame()
    if self.controlFrame then return end
    if not self.db.settings.showControlFrame then return end

    -- Main frame (BackdropTemplate required for TBC Anniversary modern client)
    local f = CreateFrame("Frame", "SpotifyControlFrame", UIParent, "BackdropTemplate")
    f:SetSize(260, 150)
    f:SetPoint(unpack(self.chardb.framePoint))
    f:SetScale(self.chardb.frameScale or 1.0)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:SetFrameStrata("MEDIUM")

    -- Dark backdrop
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4},
    })
    f:SetBackdropColor(0.05, 0.05, 0.05, 0.92)
    f:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)

    -- Dragging (only when not locked)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        if not SC.db.settings.locked then
            self:StartMoving()
        end
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        SC.chardb.framePoint = {point, nil, relPoint, x, y}
    end)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -2, -2)
    closeBtn:SetSize(20, 20)
    closeBtn:SetScript("OnClick", function() SC:HideControlFrame() end)

    -- Title: "Spotify" in green
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 10, -8)
    title:SetText("|cFF1DB954Spotify|r")

    -- Connection status dot
    local statusDot = f:CreateTexture(nil, "OVERLAY")
    statusDot:SetSize(8, 8)
    statusDot:SetPoint("LEFT", title, "RIGHT", 4, 0)
    f.statusDot = statusDot

    -- Track name (main display)
    local trackText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    trackText:SetPoint("TOPLEFT", 10, -28)
    trackText:SetPoint("TOPRIGHT", -10, -28)
    trackText:SetJustifyH("CENTER")
    trackText:SetWordWrap(false)
    trackText:SetText("No track info")
    trackText:SetTextColor(1, 1, 1)
    f.trackText = trackText

    -- Artist name (smaller, gray)
    local artistText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    artistText:SetPoint("TOP", trackText, "BOTTOM", 0, -2)
    artistText:SetPoint("LEFT", 10, 0)
    artistText:SetPoint("RIGHT", -10, 0)
    artistText:SetJustifyH("CENTER")
    artistText:SetWordWrap(false)
    artistText:SetTextColor(0.7, 0.7, 0.7)
    f.artistText = artistText

    -- Progress text (e.g., "2:30 / 5:45")
    local progressText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    progressText:SetPoint("TOP", artistText, "BOTTOM", 0, -4)
    progressText:SetJustifyH("CENTER")
    progressText:SetTextColor(0.5, 0.5, 0.5)
    f.progressText = progressText

    -- Progress bar background
    local progressBg = f:CreateTexture(nil, "ARTWORK")
    progressBg:SetPoint("TOPLEFT", progressText, "BOTTOMLEFT", -60, -4)
    progressBg:SetSize(180, 4)
    progressBg:SetColorTexture(0.2, 0.2, 0.2, 1)

    -- Progress bar fill (Spotify green)
    local progressFill = f:CreateTexture(nil, "OVERLAY")
    progressFill:SetPoint("TOPLEFT", progressBg, "TOPLEFT", 0, 0)
    progressFill:SetHeight(4)
    progressFill:SetWidth(1)
    progressFill:SetColorTexture(0.114, 0.725, 0.329, 1)  -- #1DB954
    f.progressBg = progressBg
    f.progressFill = progressFill

    -- Transport buttons container (centered row)
    local btnY = -100
    local btnSize = 24
    local btnSpacing = 36

    -- Previous button
    local prevBtn = self:CreateTransportButton(f, "prev",
        -btnSpacing * 1.5, btnY, btnSize,
        function() SC:QueueCommand("PREV") end, "Previous track")
    f.prevBtn = prevBtn

    -- Play/Pause button (larger)
    local ppBtn = self:CreateTransportButton(f, "play",
        -btnSpacing * 0.5, btnY, btnSize + 4,
        function() SC:QueueCommand("TOGGLE") end, "Play/Pause")
    f.playPauseBtn = ppBtn

    -- Next button
    local nextBtn = self:CreateTransportButton(f, "next",
        btnSpacing * 0.5, btnY, btnSize,
        function() SC:QueueCommand("NEXT") end, "Next track")
    f.nextBtn = nextBtn

    -- Volume down
    local volDownBtn = self:CreateTransportButton(f, "voldown",
        btnSpacing * 1.5, btnY, 20,
        function() SC:QueueCommand("VOL_DOWN") end, "Volume down")

    -- Volume up
    local volUpBtn = self:CreateTransportButton(f, "volup",
        btnSpacing * 2.2, btnY, 20,
        function() SC:QueueCommand("VOL_UP") end, "Volume up")

    -- Volume text
    local volText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    volText:SetPoint("LEFT", volUpBtn, "RIGHT", 4, 0)
    volText:SetTextColor(0.6, 0.6, 0.6)
    volText:SetText("--")
    f.volText = volText

    -- Sync button (bottom right)
    local syncBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
    syncBtn:SetSize(50, 18)
    syncBtn:SetPoint("BOTTOMRIGHT", -8, 8)
    syncBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    syncBtn:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
    syncBtn:SetScript("OnClick", function() SC:TriggerSync() end)
    syncBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Sync with Spotify")
        GameTooltip:AddLine("Reloads UI to send commands and\nrefresh track information.", 1, 1, 1)
        local pending = SC:GetPendingCommandCount()
        if pending > 0 then
            GameTooltip:AddLine(pending .. " command(s) pending", 1, 0.5, 0)
        end
        GameTooltip:Show()
    end)
    syncBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local syncLabel = syncBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    syncLabel:SetPoint("CENTER")
    syncLabel:SetText("Sync")
    syncLabel:SetTextColor(0.114, 0.725, 0.329)
    f.syncBtn = syncBtn
    f.syncLabel = syncLabel

    self.controlFrame = f
end

-- Transport button textures: use WoW built-ins as fallback if custom TGAs not found
local BUILTIN_TEXTURES = {
    prev = "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up",
    play = "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up",
    pause = "Interface\\TimeManager\\PauseButton",
    next = "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up",
    volup = "Interface\\Buttons\\UI-PlusButton-Up",
    voldown = "Interface\\Buttons\\UI-MinusButton-Up",
}

function SC:CreateTransportButton(parent, btnType, offsetX, offsetY, size, onClick, tooltip)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(size, size)
    btn:SetPoint("CENTER", parent, "CENTER", offsetX, offsetY)

    -- Try custom texture first, fall back to built-in
    local customTex = "Interface\\AddOns\\SpotifyControl\\Textures\\btn-" .. btnType
    local fallbackTex = BUILTIN_TEXTURES[btnType]
    btn:SetNormalTexture(fallbackTex or customTex)
    btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")

    btn:SetScript("OnClick", onClick)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(tooltip)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return btn
end

function SC:UpdateUI()
    if not self.controlFrame then return end
    local f = self.controlFrame
    local info = self.trackInfo

    if not info or not info.connected then
        f.trackText:SetText("|cFF888888Companion not connected|r")
        f.artistText:SetText("Start the companion app and /spotify sync")
        f.progressText:SetText("")
        f.progressFill:SetWidth(1)
        f.volText:SetText("--")
        f.statusDot:SetColorTexture(0.8, 0.1, 0.1, 1)  -- Red
        return
    end

    -- Connected: green dot
    f.statusDot:SetColorTexture(0.114, 0.725, 0.329, 1)

    -- Track info
    f.trackText:SetText(info.track_name or "Unknown Track")
    f.artistText:SetText(info.artist_name or "Unknown Artist")

    -- Progress
    local progress = self:FormatTime(info.track_progress_ms or 0)
    local duration = self:FormatTime(info.track_duration_ms or 0)
    f.progressText:SetText(progress .. " / " .. duration)

    -- Progress bar fill
    local totalDuration = info.track_duration_ms or 1
    local currentProgress = info.track_progress_ms or 0
    if totalDuration > 0 then
        local fraction = currentProgress / totalDuration
        local barWidth = math.max(1, fraction * 180)
        f.progressFill:SetWidth(barWidth)
    end

    -- Volume
    f.volText:SetText((info.volume_percent or "--") .. "%")

    -- Play/Pause button icon
    if info.is_playing then
        f.playPauseBtn:SetNormalTexture(
            BUILTIN_TEXTURES["pause"])
    else
        f.playPauseBtn:SetNormalTexture(
            BUILTIN_TEXTURES["play"])
    end
end

function SC:ShowControlFrame()
    if not self.controlFrame then
        self.db.settings.showControlFrame = true
        self:CreateControlFrame()
        self:UpdateUI()
    end
    if self.controlFrame then
        self.controlFrame:Show()
        self.db.settings.showControlFrame = true
    end
end

function SC:HideControlFrame()
    if self.controlFrame then
        self.controlFrame:Hide()
        self.db.settings.showControlFrame = false
    end
end
