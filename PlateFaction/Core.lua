local addonName, addon = ...

local defaults = {
    enabled = true,
    mode = "icon",
    showAllianceIcon = true,
    showHordeIcon = true,
    iconSize = 16,
    iconPosition = "LEFT",
    iconOffsetX = 0,
    iconOffsetY = 0,
}
local anchors = {
    LEFT = { "RIGHT", "LEFT", -4, 0 },
    RIGHT = { "LEFT", "RIGHT", 4, 0 },
    TOP = { "BOTTOM", "TOP", 0, 4 },
    BOTTOM = { "TOP", "BOTTOM", 0, -4 },
}
local ranges = { iconSize = {10, 64}, iconOffsetX = {-100, 100}, iconOffsetY = {-100, 100} }
local factions = {
    Alliance = { r = 51 / 255, g = 153 / 255, b = 1,
        texture = "Interface\\TargetingFrame\\UI-PVP-Alliance", setting = "showAllianceIcon" },
    Horde = { r = 1, g = 64 / 255, b = 64 / 255,
        texture = "Interface\\TargetingFrame\\UI-PVP-Horde", setting = "showHordeIcon" },
}

-- Keep addon state outside Blizzard frames, which are pooled by the client.
local states = setmetatable({}, { __mode = "k" })
local units = {}
local hooked = false
local events = CreateFrame("Frame")
local RefreshUnit

local function IsSecret(value)
    return issecretvalue and issecretvalue(value)
end

local function IsAccessible(frame)
    return not IsSecret(frame) and frame and not frame:IsForbidden()
end

local function IsPlateUnit(unit)
    return not IsSecret(unit) and type(unit) == "string" and unit:match("^nameplate%d+$")
end

local function HideIcon(state)
    if state.icon then
        state.icon:Hide()
    end
end

local function RestoreName(frame, state)
    if state.colored and state.originalColor and IsAccessible(frame) then
        frame.name:SetVertexColor(unpack(state.originalColor))
    end
    state.colored = nil
end

local function Detach(frame, state)
    HideIcon(state)
    RestoreName(frame, state)
    if state.unit and units[state.unit] == frame then
        units[state.unit] = nil
    end
    state.unit = nil
    state.originalColor = nil
end

local function GetFaction(unit)
    -- Check each result before branching: beta clients can restrict unit data.
    local ok, player = pcall(UnitIsPlayer, unit)
    if not ok or IsSecret(player) or not player then return end
    local selfOK, isSelf = pcall(UnitIsUnit, unit, "player")
    if not selfOK or IsSecret(isSelf) or isSelf then return end
    local factionOK, faction = pcall(UnitFactionGroup, unit)
    if not factionOK or IsSecret(faction) or type(faction) ~= "string" then return end
    return factions[faction]
end

local function Apply(frame, state)
    if not IsAccessible(frame) then return end
    HideIcon(state)
    local unit = frame.unit
    if not addon.db or not addon.db.enabled or not IsPlateUnit(unit) or state.unit ~= unit then
        RestoreName(frame, state)
        return
    end
    local faction = GetFaction(unit)
    if not faction then
        RestoreName(frame, state)
        return
    end
    local nameShown = frame.name:IsShown()
    if IsSecret(nameShown) then
        RestoreName(frame, state)
        return
    end

    local colorEnabled = addon.db.mode == "color" or addon.db.mode == "both"
    if colorEnabled and state.originalColor then
        frame.name:SetVertexColor(faction.r, faction.g, faction.b)
        state.colored = true
    else
        RestoreName(frame, state)
    end

    if not nameShown then return end
    if addon.db.mode == "color" or not addon.db[faction.setting] then return end

    if not state.icon then
        state.icon = frame:CreateTexture(nil, "OVERLAY")
    end
    local anchor = anchors[addon.db.iconPosition]
    state.icon:ClearAllPoints()
    state.icon:SetPoint(anchor[1], frame.name, anchor[2],
        anchor[3] + addon.db.iconOffsetX, anchor[4] + addon.db.iconOffsetY)
    state.icon:SetTexture(faction.texture)
    state.icon:SetSize(addon.db.iconSize, addon.db.iconSize)
    state.icon:Show()
end

local function Track(frame, unit)
    if not IsAccessible(frame) or not IsAccessible(frame.name) then return end
    local state = states[frame]
    if not state then
        state = {}
        states[frame] = state
        frame:HookScript("OnHide", function() Detach(frame, state) end)
        frame:HookScript("OnShow", function() RefreshUnit(frame.unit) end)
        -- FontStrings have no OnHide script. Hook visibility methods instead.
        hooksecurefunc(frame.name, "Hide", function() HideIcon(state) end)
        hooksecurefunc(frame.name, "SetShown", function(_, shown)
            if IsSecret(shown) or not shown then HideIcon(state) end
        end)
    end
    if state.unit ~= unit then
        -- The Blizzard update already established the new unit's name color.
        HideIcon(state)
        state.colored = nil
        state.originalColor = nil
        if state.unit and units[state.unit] == frame then units[state.unit] = nil end
        state.unit = unit
    end
    units[unit] = frame
    return state
end

local function AfterNameUpdate(frame)
    if not IsAccessible(frame) then return end
    local unit = frame.unit
    if not IsPlateUnit(unit) then
        if states[frame] then Detach(frame, states[frame]) end
        return
    end
    local plate = C_NamePlate.GetNamePlateForUnit(unit)
    -- CompactUnitFrame_UpdateName also updates raid/group frames: exclude them.
    if not IsAccessible(plate) or plate.UnitFrame ~= frame then return end
    local state = Track(frame, unit)
    if not state then return end
    local shown = frame.name:IsShown()
    if not IsSecret(shown) and shown then
        local r, g, b, a = frame.name:GetTextColor()
        if not IsSecret(r) and not IsSecret(g) and not IsSecret(b) and not IsSecret(a)
            and type(r) == "number" and type(g) == "number" and type(b) == "number" then
            state.originalColor = { r, g, b, a }
        else
            state.originalColor = nil
        end
        state.colored = nil
    end
    Apply(frame, state)
end

RefreshUnit = function(unit)
    if not hooked or not IsPlateUnit(unit) then return end
    local plate = C_NamePlate.GetNamePlateForUnit(unit)
    if IsAccessible(plate) and IsAccessible(plate.UnitFrame) then
        local frame = plate.UnitFrame
        if not IsSecret(frame.unit) and frame.unit == unit then
            -- Recompute the current Blizzard color, then our post-hook applies settings.
            CompactUnitFrame_UpdateName(frame)
        end
    end
end

function addon:Refresh()
    if not hooked then return end
    for _, plate in pairs(C_NamePlate.GetNamePlates()) do
        if IsAccessible(plate) and IsAccessible(plate.UnitFrame) then
            RefreshUnit(plate.UnitFrame.unit)
        end
    end
end

local function InstallHooks()
    if hooked or not C_NamePlate or type(CompactUnitFrame_UpdateName) ~= "function" then return end
    hooksecurefunc("CompactUnitFrame_UpdateName", AfterNameUpdate)
    hooksecurefunc("CompactUnitFrame_SetUnit", function(frame, unit)
        if IsAccessible(frame) and not IsPlateUnit(unit) and states[frame] then
            Detach(frame, states[frame])
        end
    end)
    hooked = true
end

local function Normalize(key, value)
    if key == "mode" then
        if value == "icon" or value == "color" or value == "both" then return value end
    elseif key == "iconPosition" then
        if type(value) == "string" and anchors[value] then return value end
    elseif ranges[key] then
        if type(value) == "number" and value == value then
            return math.max(ranges[key][1], math.min(ranges[key][2], math.floor(value + 0.5)))
        end
    elseif type(defaults[key]) == "boolean" and type(value) == "boolean" then
        return value
    end
    return defaults[key]
end

function addon:SetOption(key, value)
    if defaults[key] == nil then return end
    self.db[key] = Normalize(key, value)
    self:Refresh()
end

events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("NAME_PLATE_UNIT_ADDED")
events:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
events:RegisterEvent("UNIT_FACTION")
events:RegisterEvent("UNIT_NAME_UPDATE")
events:SetScript("OnEvent", function(_, event, unit)
    if event == "ADDON_LOADED" then
        if unit == addonName then
            if type(PlateFactionDB) ~= "table" then PlateFactionDB = {} end
            for key in pairs(defaults) do
                PlateFactionDB[key] = Normalize(key, PlateFactionDB[key])
            end
            addon.db = PlateFactionDB
        end
        InstallHooks()
    elseif event == "PLAYER_LOGIN" then
        InstallHooks()
        addon:CreateOptions()
        addon:Refresh()
    elseif event == "PLAYER_ENTERING_WORLD" then
        addon:Refresh()
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        if not IsSecret(unit) and units[unit] then
            local frame = units[unit]
            Detach(frame, states[frame])
        end
    elseif event == "UNIT_FACTION" and not IsSecret(unit) and unit == "player" then
        addon:Refresh()
    else
        RefreshUnit(unit)
    end
end)
