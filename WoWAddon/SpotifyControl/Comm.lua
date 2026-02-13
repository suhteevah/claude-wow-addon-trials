local ADDON_NAME, SC = ...

SC.reloadTimerFrame = nil
SC.pendingReload = false

function SC:QueueCommand(command, args)
    if not self.db then
        self:Print("Error: Addon not initialized yet.")
        return
    end

    self.db.lastCommandId = (self.db.lastCommandId or 0) + 1

    local entry = {
        id = self.db.lastCommandId,
        cmd = command,
        args = args or "",
        ts = time(),
    }

    if not self.db.commandQueue then
        self.db.commandQueue = {}
    end
    table.insert(self.db.commandQueue, entry)

    -- Optimistic UI feedback
    local displayCmd = command
    if args and args ~= "" then
        displayCmd = command .. " " .. args
    end
    self:Print("Command queued: " .. displayCmd)

    -- Update UI optimistically (toggle play/pause icon, etc.)
    self:OptimisticUIUpdate(command)

    -- Trigger reload if auto-reload is enabled
    if self.db.settings.autoReload then
        self:ScheduleReload()
    else
        self:Print("Click Sync or type |cFFFFFF00/spotify sync|r to send.")
    end
end

function SC:ScheduleReload()
    -- If a reload is already scheduled, do nothing (batching)
    if self.pendingReload then return end
    self.pendingReload = true

    local delay = self.db.settings.reloadDelay or 0.5

    if not self.reloadTimerFrame then
        self.reloadTimerFrame = CreateFrame("Frame")
    end

    self.reloadTimerFrame.elapsed = 0
    self.reloadTimerFrame.delay = delay
    self.reloadTimerFrame:SetScript("OnUpdate", function(f, elapsed)
        f.elapsed = f.elapsed + elapsed
        if f.elapsed >= f.delay then
            f:SetScript("OnUpdate", nil)
            SC.pendingReload = false
            ReloadUI()
        end
    end)
end

function SC:TriggerSync()
    -- Immediate sync (no delay)
    self.pendingReload = false
    if self.reloadTimerFrame then
        self.reloadTimerFrame:SetScript("OnUpdate", nil)
    end
    ReloadUI()
end

function SC:CancelPendingReload()
    self.pendingReload = false
    if self.reloadTimerFrame then
        self.reloadTimerFrame:SetScript("OnUpdate", nil)
    end
end

function SC:GetPendingCommandCount()
    if not self.db or not self.db.commandQueue then return 0 end
    local count = 0
    for _, cmd in ipairs(self.db.commandQueue) do
        if cmd.id > (self.db.lastAckId or 0) then
            count = count + 1
        end
    end
    return count
end

function SC:OptimisticUIUpdate(command)
    if not self.controlFrame then return end

    if command == "PLAY" or command == "TOGGLE" then
        if self.controlFrame.playPauseBtn then
            self.controlFrame.playPauseBtn:SetNormalTexture(
                "Interface\\AddOns\\SpotifyControl\\Textures\\btn-pause"
            )
        end
    elseif command == "PAUSE" then
        if self.controlFrame.playPauseBtn then
            self.controlFrame.playPauseBtn:SetNormalTexture(
                "Interface\\AddOns\\SpotifyControl\\Textures\\btn-play"
            )
        end
    end
end
