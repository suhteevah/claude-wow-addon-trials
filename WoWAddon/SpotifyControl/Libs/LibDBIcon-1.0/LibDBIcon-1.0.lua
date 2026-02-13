-- LibDBIcon-1.0 - Minimal implementation for minimap icon management
-- Based on the official LibDBIcon-1.0 by Rabbit
-- License: Public Domain
-- This is a simplified version sufficient for SpotifyControl

local DBICON_MAJOR, DBICON_MINOR = "LibDBIcon-1.0", 48
local lib = LibStub:NewLibrary(DBICON_MAJOR, DBICON_MINOR)
if not lib then return end

lib.objects = lib.objects or {}
lib.callbackRegistered = lib.callbackRegistered or {}
lib.callbacks = lib.callbacks or LibStub("CallbackHandler-1.0"):New(lib)
lib.radius = lib.radius or 80
local minimapShapes = lib.minimapShapes or {}
lib.minimapShapes = minimapShapes

local math_sqrt = math.sqrt
local math_sin = math.sin
local math_cos = math.cos
local math_atan2 = math.atan2 or math.atan
local math_max = math.max
local math_pi = math.pi

local function getAnchors(frame)
    local x, y = frame:GetCenter()
    if not x or not y then return "CENTER" end
    local hhalf = (x > UIParent:GetWidth()*2/3) and "RIGHT" or (x < UIParent:GetWidth()/3) and "LEFT" or ""
    local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
    return vhalf..hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
end

local function onEnter(self)
    if self.isMoving then return end
    local obj = self.dataObject
    if obj.OnTooltipShow then
        GameTooltip:SetOwner(self, "ANCHOR_NONE")
        GameTooltip:SetPoint(getAnchors(self))
        obj.OnTooltipShow(GameTooltip)
        GameTooltip:Show()
    elseif obj.OnEnter then
        obj.OnEnter(self)
    end
end

local function onLeave(self)
    GameTooltip:Hide()
    local obj = self.dataObject
    if obj.OnLeave then
        obj.OnLeave(self)
    end
end

local function onClick(self, b)
    local obj = self.dataObject
    if obj.OnClick then
        obj.OnClick(self, b)
    end
end

local function onDragStart(self)
    self:LockHighlight()
    self.isMoving = true
    self:SetScript("OnUpdate", function(self)
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        px, py = px / scale, py / scale
        local angle = math_atan2(py - my, px - mx)
        local x = math_cos(angle) * lib.radius
        local y = math_sin(angle) * lib.radius
        self:ClearAllPoints()
        self:SetPoint("CENTER", Minimap, "CENTER", x, y)
        -- Save angle in degrees
        if self.db then
            self.db.minimapPos = math.deg(angle) % 360
        end
    end)
    GameTooltip:Hide()
end

local function onDragStop(self)
    self:SetScript("OnUpdate", nil)
    self.isMoving = false
    self:UnlockHighlight()
end

local function updatePosition(button, db)
    local angle = math.rad(db and db.minimapPos or 225)
    local x = math_cos(angle) * lib.radius
    local y = math_sin(angle) * lib.radius
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function lib:Register(name, obj, db)
    if self.objects[name] then return end

    db = db or {}
    if not db.minimapPos then db.minimapPos = 225 end

    local button = CreateFrame("Button", "LibDBIcon10_"..name, Minimap)
    button:SetFrameStrata("MEDIUM")
    button:SetSize(31, 31)
    button:SetFrameLevel(8)
    button:RegisterForClicks("anyUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture(136477) -- Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight

    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(53, 53)
    overlay:SetTexture(136430) -- Interface\\Minimap\\MiniMap-TrackingBorder
    overlay:SetPoint("TOPLEFT")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetSize(20, 20)
    background:SetTexture(136467) -- Interface\\Minimap\\UI-Minimap-Background
    background:SetPoint("TOPLEFT", 7, -5)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(17, 17)
    icon:SetPoint("TOPLEFT", 7, -6)
    button.icon = icon

    button.dataObject = obj
    button.db = db

    button:SetScript("OnEnter", onEnter)
    button:SetScript("OnLeave", onLeave)
    button:SetScript("OnClick", onClick)
    button:SetScript("OnDragStart", onDragStart)
    button:SetScript("OnDragStop", onDragStop)

    if obj.icon then
        icon:SetTexture(obj.icon)
    end

    updatePosition(button, db)

    if db.hide then
        button:Hide()
    else
        button:Show()
    end

    self.objects[name] = button
    lib.callbacks:Fire("LibDBIcon_IconCreated", button, name)
end

function lib:Show(name)
    local button = self.objects[name]
    if button then
        button:Show()
        if button.db then button.db.hide = false end
    end
end

function lib:Hide(name)
    local button = self.objects[name]
    if button then
        button:Hide()
        if button.db then button.db.hide = true end
    end
end

function lib:IsRegistered(name)
    return self.objects[name] and true or false
end

function lib:Refresh(name, db)
    local button = self.objects[name]
    if button then
        if db then button.db = db end
        updatePosition(button, button.db)
    end
end

function lib:GetMinimapButton(name)
    return self.objects[name]
end
