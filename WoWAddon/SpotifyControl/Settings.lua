local ADDON_NAME, SC = ...

function SC:ShowSettings()
    if self.settingsFrame then
        if self.settingsFrame:IsShown() then
            self.settingsFrame:Hide()
        else
            self.settingsFrame:Show()
        end
        return
    end

    local f = CreateFrame("Frame", "SpotifyControlSettings", UIParent, "BackdropTemplate")
    f:SetSize(300, 280)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:SetFrameStrata("DIALOG")
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4},
    })
    f:SetBackdropColor(0.1, 0.1, 0.1, 0.95)

    -- Close button
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)

    -- Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -12)
    title:SetText("|cFF1DB954SpotifyControl|r Settings")

    local yOff = -40

    -- Auto-reload checkbox
    local autoReloadCB = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    autoReloadCB:SetPoint("TOPLEFT", 16, yOff)
    autoReloadCB:SetChecked(self.db.settings.autoReload)
    autoReloadCB:SetScript("OnClick", function(cb)
        SC.db.settings.autoReload = cb:GetChecked()
    end)
    local autoReloadLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    autoReloadLabel:SetPoint("LEFT", autoReloadCB, "RIGHT", 4, 0)
    autoReloadLabel:SetText("Auto-sync on command (triggers UI reload)")

    yOff = yOff - 30

    -- Reload delay slider
    local delayLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    delayLabel:SetPoint("TOPLEFT", 16, yOff)
    delayLabel:SetText("Sync delay: " .. string.format("%.1fs", self.db.settings.reloadDelay))

    yOff = yOff - 20
    local delaySlider = CreateFrame("Slider", nil, f, "OptionsSliderTemplate")
    delaySlider:SetPoint("TOPLEFT", 20, yOff)
    delaySlider:SetSize(200, 16)
    delaySlider:SetMinMaxValues(0.2, 3.0)
    delaySlider:SetValueStep(0.1)
    delaySlider:SetObeyStepOnDrag(true)
    delaySlider:SetValue(self.db.settings.reloadDelay)
    delaySlider:SetScript("OnValueChanged", function(slider, value)
        SC.db.settings.reloadDelay = value
        delayLabel:SetText("Sync delay: " .. string.format("%.1fs", value))
    end)

    yOff = yOff - 40

    -- Volume step slider
    local volLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    volLabel:SetPoint("TOPLEFT", 16, yOff)
    volLabel:SetText("Volume step: " .. self.db.settings.volumeStep .. "%")

    yOff = yOff - 20
    local volSlider = CreateFrame("Slider", nil, f, "OptionsSliderTemplate")
    volSlider:SetPoint("TOPLEFT", 20, yOff)
    volSlider:SetSize(200, 16)
    volSlider:SetMinMaxValues(5, 25)
    volSlider:SetValueStep(5)
    volSlider:SetObeyStepOnDrag(true)
    volSlider:SetValue(self.db.settings.volumeStep)
    volSlider:SetScript("OnValueChanged", function(slider, value)
        SC.db.settings.volumeStep = value
        volLabel:SetText("Volume step: " .. math.floor(value) .. "%")
    end)

    yOff = yOff - 40

    -- Lock frame checkbox
    local lockCB = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    lockCB:SetPoint("TOPLEFT", 16, yOff)
    lockCB:SetChecked(self.db.settings.locked)
    lockCB:SetScript("OnClick", function(cb)
        SC.db.settings.locked = cb:GetChecked()
    end)
    local lockLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lockLabel:SetPoint("LEFT", lockCB, "RIGHT", 4, 0)
    lockLabel:SetText("Lock control frame position")

    yOff = yOff - 30

    -- Show minimap icon checkbox
    local mmCB = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    mmCB:SetPoint("TOPLEFT", 16, yOff)
    mmCB:SetChecked(self.db.settings.showMinimapIcon)
    mmCB:SetScript("OnClick", function(cb)
        SC.db.settings.showMinimapIcon = cb:GetChecked()
        local LDBIcon = LibStub and LibStub("LibDBIcon-1.0", true)
        if LDBIcon then
            if cb:GetChecked() then
                SC.db.minimap.hide = false
                LDBIcon:Show("SpotifyControl")
            else
                SC.db.minimap.hide = true
                LDBIcon:Hide("SpotifyControl")
            end
        end
    end)
    local mmLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    mmLabel:SetPoint("LEFT", mmCB, "RIGHT", 4, 0)
    mmLabel:SetText("Show minimap button")

    self.settingsFrame = f
    f:Show()
end
