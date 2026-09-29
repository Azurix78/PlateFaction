-- Run from the project root: lua tests/run.lua
-- Contract simulation only: real rendering, taint and combat restrictions need WoW.
unpack = unpack or table.unpack
local checks = 0
local function eq(actual, expected, message)
    checks = checks + 1
    assert(actual == expected, (message or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local secret = {}
function issecretvalue(value) return rawequal(value, secret) end

local function Widget(kind, name)
    local w = { kind = kind, widgetName = name, shown = true, scripts = {}, textures = {}, color = {1, 1, 1, 1} }
    function w:IsForbidden() return self.forbidden or false end
    function w:GetName() return self.widgetName end
    function w:SetScript(event, fn) self.scripts[event] = fn end
    function w:HookScript(event, fn)
        local old = self.scripts[event]
        self.scripts[event] = function(...)
            if old then old(...) end
            fn(...)
        end
    end
    function w:Hide()
        local wasShown = self.shown
        self.shown = false
        if wasShown and self.scripts.OnHide then self.scripts.OnHide(self) end
    end
    function w:Show()
        local wasShown = self.shown
        self.shown = true
        if not wasShown and self.scripts.OnShow then self.scripts.OnShow(self) end
    end
    function w:SetShown(value) if value then self:Show() else self:Hide() end end
    function w:IsShown() return self.shown end
    function w:SetVertexColor(...) self.color = {...} end
    function w:GetTextColor() return unpack(self.color) end
    function w:SetPoint(...) self.point = {...} end
    function w:ClearAllPoints() self.point = nil end
    function w:SetSize(width, height) self.width, self.height = width, height end
    function w:SetWidth(width) self.width = width end
    function w:GetWidth() return self.width or 520 end
    function w:SetHeight(height) self.height = height end
    function w:SetScrollChild(child) self.child = child end
    function w:GetStringHeight()
        return math.max(14, math.ceil(#(self.text or "") * 7 / (self.width or 520)) * 14)
    end
    function w:SetJustifyH(value) self.justify = value end
    function w:SetText(value) self.text = value end
    function w:SetTexture(value) self.texture = value end
    function w:CreateTexture()
        assert(not self.forbidden, "Forbidden frame was modified")
        local texture = Widget("Texture")
        table.insert(self.textures, texture)
        return texture
    end
    function w:CreateFontString() return Widget("FontString") end
    function w:SetChecked(value) self.checked = value end
    function w:GetChecked() return self.checked end
    function w:SetMinMaxValues(low, high) self.min, self.max = low, high end
    function w:SetValueStep(value) self.step = value end
    function w:SetObeyStepOnDrag(value) self.obey = value end
    function w:SetValue(value)
        self.value = value
        if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, value) end
    end
    function w:RegisterEvent(event)
        self.events = self.events or {}
        self.events[event] = true
    end
    return w
end

local function Boot(saved, delayed, locale)
    local env = { plates = {}, data = {}, widgets = {} }
    PlateFactionDB = saved
    SlashCmdList = {}
    function GetLocale() return locale or "frFR" end
    function CreateFrame(kind, name, parent, template)
        local w = Widget(kind, name)
        w.parent = parent
        if kind == "CheckButton" then w.text = Widget("FontString") end
        if template == "OptionsSliderTemplate" then
            for _, suffix in ipairs({"Low", "High", "Text"}) do _G[name .. suffix] = Widget("FontString") end
        end
        table.insert(env.widgets, w)
        return w
    end
    function hooksecurefunc(target, method, callback)
        if type(target) == "string" then target, method, callback = _G, target, method end
        local original = assert(target[method], "Missing API: " .. method)
        target[method] = function(...)
            original(...)
            callback(...)
        end
    end
    function UnitIsPlayer(unit) return env.data[unit] and env.data[unit].player end
    function UnitIsUnit(unit, other)
        assert(other == "player")
        return env.data[unit] and env.data[unit].self
    end
    function UnitFactionGroup(unit)
        if env.data[unit].throws then error("Unit data unavailable") end
        return env.data[unit].faction
    end
    C_NamePlate = {
        GetNamePlateForUnit = function(unit) return env.plates[unit] end,
        GetNamePlates = function() return env.plates end,
    }
    local function UpdateName(frame)
        if frame.forbidden then return end -- Blizzard itself can update forbidden frames.
        if not frame.unit then return end
        local data = env.data[frame.unit]
        if data.hidden then frame.name:Hide() else
            frame.name:SetVertexColor(unpack(data.base or {0.2, 0.8, 0.3, 1}))
            frame.name:Show()
            if data.secretShown then frame.name.shown = secret end
        end
    end
    local function SetUnit(frame, unit)
        frame.unit = unit
        if unit then CompactUnitFrame_UpdateName(frame) end
    end
    CompactUnitFrame_UpdateName = not delayed and UpdateName or nil
    CompactUnitFrame_SetUnit = not delayed and SetUnit or nil
    Settings = {
        RegisterCanvasLayoutCategory = function(panel, title)
            env.panel = panel
            eq(title, "PlateFaction", "category title")
            return { GetID = function() return 73 end }
        end,
        RegisterAddOnCategory = function(category) env.category = category end,
        OpenToCategory = function(id) env.opened = id end,
    }
    local addon = {}
    assert(loadfile("PlateFaction/Locales.lua"))("PlateFaction", addon)
    assert(loadfile("PlateFaction/Core.lua"))("PlateFaction", addon)
    assert(loadfile("PlateFaction/Options.lua"))("PlateFaction", addon)
    env.addon = addon
    local events = env.widgets[1]
    function env:Event(event, unit) events.scripts.OnEvent(events, event, unit) end
    env:Event("ADDON_LOADED", "PlateFaction")
    if delayed then
        CompactUnitFrame_UpdateName, CompactUnitFrame_SetUnit = UpdateName, SetUnit
        env:Event("ADDON_LOADED", "Blizzard_NamePlates")
    end
    env:Event("PLAYER_LOGIN")
    function env:Add(unit, faction, fields)
        self.data[unit] = fields or {}
        self.data[unit].faction = faction
        if self.data[unit].player == nil then self.data[unit].player = true end
        local frame = Widget("Button")
        frame.name = Widget("FontString")
        frame.healthBar = setmetatable({}, { __index = function() error("Health bar accessed") end })
        frame.forbidden = self.data[unit].forbidden
        self.plates[unit] = Widget("Frame")
        self.plates[unit].UnitFrame = frame
        CompactUnitFrame_SetUnit(frame, unit)
        self:Event("NAME_PLATE_UNIT_ADDED", unit)
        return frame
    end
    function env:Click(text)
        self.panel:Sync() -- Opening the options refreshes controls from SavedVariables.
        for _, w in ipairs(self.widgets) do
            if w.kind == "CheckButton" and w.text.text == text then
                w:SetChecked(not w:GetChecked())
                w.scripts.OnClick(w)
                return
            end
        end
        error("Control missing: " .. text)
    end
    return env
end

local function visible(frame) return #frame.textures > 0 and frame.textures[1]:IsShown() end
local function color(frame, r, g, b)
    eq(frame.name.color[1], r, "red")
    eq(frame.name.color[2], g, "green")
    eq(frame.name.color[3], b, "blue")
end

local e = Boot()
eq(e.addon.db.enabled, true)
eq(e.addon.db.mode, "icon")
eq(e.addon.db.iconSize, 16)
local alliance = e:Add("nameplate1", "Alliance")
local horde = e:Add("nameplate2", "Horde")
eq(visible(alliance), true)
eq(visible(horde), true)
eq(alliance.textures[1].width, 16)
eq(alliance.textures[1].point[4], -4)
color(alliance, 0.2, 0.8, 0.3)
for _, a in ipairs({true, false}) do
    for _, h in ipairs({true, false}) do
        e.addon:SetOption("showAllianceIcon", a)
        e.addon:SetOption("showHordeIcon", h)
        eq(visible(alliance), a, "Alliance filter")
        eq(visible(horde), h, "Horde filter")
    end
end
e.addon:SetOption("mode", "both")
color(alliance, 51/255, 153/255, 1)
color(horde, 1, 64/255, 64/255)
eq(visible(alliance), false)
eq(visible(horde), false)
e:Click("Afficher l’icône Horde")
eq(visible(horde), true)
e.addon:SetOption("mode", "color")
eq(visible(horde), false)
color(horde, 1, 64/255, 64/255)
e.addon:SetOption("enabled", false)
color(horde, 0.2, 0.8, 0.3)
eq(visible(horde), false)
e.addon:SetOption("enabled", true)
e.addon:SetOption("mode", "icon")
color(horde, 0.2, 0.8, 0.3)
e.addon:SetOption("iconSize", 32)
eq(horde.textures[1].width, 32)
eq(#horde.textures, 1, "texture reused")

e.addon:SetOption("mode", "both")
e.data.nameplate2.base = {0.8, 0.2, 0.7, 1}
CompactUnitFrame_UpdateName(horde) -- e.g. targeting, hover or class color update
color(horde, 1, 64/255, 64/255)
e.addon:SetOption("mode", "icon")
color(horde, 0.8, 0.2, 0.7)
e.data.nameplate2.hidden = true
CompactUnitFrame_UpdateName(horde)
eq(visible(horde), false, "hidden name")
e.data.nameplate2.hidden = false
CompactUnitFrame_UpdateName(horde)
eq(visible(horde), true)
horde.name:Hide()
eq(visible(horde), false, "direct name hide")
CompactUnitFrame_UpdateName(horde)
horde.name:SetShown(false)
eq(visible(horde), false, "SetShown false")
CompactUnitFrame_UpdateName(horde)
horde:Hide()
eq(visible(horde), false, "frame hidden")
horde:Show()
eq(visible(horde), true, "frame shown again")

for _, fields in ipairs({{player=false}, {self=true}, {player=secret}, {self=secret}, {forbidden=true}}) do
    local ignored = e:Add("nameplate3", "Horde", fields)
    eq(visible(ignored), false, "excluded unit")
end
local unknown = e:Add("nameplate4", "Neutral")
eq(visible(unknown), false)
e.data.nameplate4.faction = secret
e:Event("UNIT_FACTION", "nameplate4")
eq(visible(unknown), false)
e.data.nameplate4.faction = "Horde"
e:Event("UNIT_FACTION", "nameplate4")
eq(visible(unknown), true, "faction becomes available")
e.data.nameplate4.throws = true
e:Event("UNIT_FACTION", "nameplate4")
eq(visible(unknown), false, "restricted API")
e:Event("UNIT_FACTION", secret)

e.addon:SetOption("mode", "both")
CompactUnitFrame_SetUnit(horde, nil)
horde:Hide()
e.plates.nameplate2 = nil -- client releases frame before removal notification
e:Event("NAME_PLATE_UNIT_REMOVED", "nameplate2")
eq(visible(horde), false, "removed after release")
e.data.nameplate5 = {player=false, faction="Horde", base={0.7, 0.7, 0.7, 1}}
e.plates.nameplate5 = Widget("Frame")
e.plates.nameplate5.UnitFrame = horde
CompactUnitFrame_SetUnit(horde, "nameplate5")
horde:Show()
eq(visible(horde), false, "pooled frame reused for NPC")
color(horde, 0.7, 0.7, 0.7)
e.data.nameplate5.player = true
e:Event("UNIT_NAME_UPDATE", "nameplate5")
eq(visible(horde), true)
eq(#horde.textures, 1, "no extra texture after pooling")
e:Event("NAME_PLATE_UNIT_REMOVED", "nameplate5") -- opposite event order
eq(visible(horde), false)
color(horde, 0.7, 0.7, 0.7)

local raidFrame = Widget("Button")
raidFrame.unit, raidFrame.name = "nameplate1", Widget("FontString")
CompactUnitFrame_UpdateName(raidFrame)
color(raidFrame, 0.2, 0.8, 0.3)
eq(#raidFrame.textures, 0, "unrelated compact frame unchanged")
SlashCmdList.PLATEFACTION()
eq(e.opened, 73, "slash opens category")
e:Click("Icône seule")
eq(e.addon.db.mode, "icon")
e:Click("Icône seule")
eq(e.addon.db.mode, "icon", "mode cannot be unchecked")
e:Click("Activer PlateFaction")
eq(e.addon.db.enabled, false)
e.addon:SetOption("iconSize", 100)
eq(e.addon.db.iconSize, 64)
e.addon:SetOption("iconSize", 0)
eq(e.addon.db.iconSize, 10)
for _, widget in ipairs(e.widgets) do
    if widget:GetName() == "PlateFactionIconSizeSlider" then
        widget:SetValue(23)
        eq(e.addon.db.iconSize, 23, "slider saves setting")
    end
end
e.addon:SetOption("enabled", true)
e.addon:SetOption("showAllianceIcon", true)
eq(alliance.textures[1].width, 23, "slider size applied after enabling")
e.addon:SetOption("mode", "both")
e.data.nameplate1.faction = secret
e:Event("UNIT_FACTION", "nameplate1")
eq(visible(alliance), false, "existing icon cleared for secret faction")
color(alliance, 0.2, 0.8, 0.3)
e.data.nameplate1.faction = "Alliance"
e:Event("UNIT_FACTION", "nameplate1")
eq(visible(alliance), true)
e.data.nameplate1.secretShown = true
e.addon:Refresh()
eq(visible(alliance), false, "secret visibility ignored")

local saved = {enabled=true, mode="both", showAllianceIcon=false, showHordeIcon=true, iconSize=22}
for _, ownFaction in ipairs({"Alliance", "Horde"}) do
    local session = Boot(saved, true)
    session.data.player = {faction=ownFaction, player=true, self=true}
    local a = session:Add("nameplate1", "Alliance")
    local h = session:Add("nameplate2", "Horde")
    session:Event("UNIT_FACTION", "player")
    session:Event("PLAYER_ENTERING_WORLD")
    eq(visible(a), false, "saved filter after character change")
    eq(visible(h), true)
    eq(h.textures[1].width, 22)
    eq(session.addon.db, saved, "SavedVariables reused")
    color(a, 51/255, 153/255, 1)
end
local invalid = Boot({enabled="bad", mode="bad", iconSize="bad", showHordeIcon=false})
eq(invalid.addon.db.enabled, true)
eq(invalid.addon.db.mode, "icon")
eq(invalid.addon.db.iconSize, 16)
eq(invalid.addon.db.showHordeIcon, false)
eq(invalid.addon.db.iconPosition, "LEFT", "old settings receive default position")
eq(invalid.addon.db.iconOffsetX, 0)
eq(invalid.addon.db.iconOffsetY, 0)
local positioned = invalid:Add("nameplate1", "Alliance")
invalid:Click("À droite")
eq(positioned.textures[1].point[1], "LEFT")
eq(positioned.textures[1].point[3], "RIGHT")
eq(positioned.textures[1].point[4], 4)
invalid:Click("Au-dessus")
eq(positioned.textures[1].point[1], "BOTTOM")
eq(positioned.textures[1].point[3], "TOP")
eq(positioned.textures[1].point[5], 4)
invalid:Click("En dessous")
eq(positioned.textures[1].point[1], "TOP")
eq(positioned.textures[1].point[3], "BOTTOM")
eq(positioned.textures[1].point[5], -4)
for _, widget in ipairs(invalid.widgets) do
    if widget:GetName() == "PlateFactionIconOffsetXSlider" then widget:SetValue(-20) end
    if widget:GetName() == "PlateFactionIconOffsetYSlider" then widget:SetValue(35) end
end
eq(positioned.textures[1].point[4], -20, "horizontal slider applies immediately")
eq(positioned.textures[1].point[5], 31, "vertical slider includes anchor spacing")
invalid.addon:SetOption("iconSize", 64)
eq(positioned.textures[1].width, 64)
eq(#positioned.textures, 1, "position edits reuse texture")
local restored = Boot(invalid.addon.db)
local restoredFrame = restored:Add("nameplate1", "Alliance")
eq(restoredFrame.textures[1].point[4], -20, "position restored across sessions")
eq(restoredFrame.textures[1].point[5], 31)
eq(restoredFrame.textures[1].width, 64)
restored.addon:SetOption("iconOffsetX", -200)
restored.addon:SetOption("iconOffsetY", 200)
eq(restored.addon.db.iconOffsetX, -100)
eq(restored.addon.db.iconOffsetY, 100)
restored.addon:SetOption("iconPosition", "invalid")
eq(restored.addon.db.iconPosition, "LEFT")
-- Every supported locale must supply every visible string without relying on fallback.
local english = Boot(nil, false, "enUS").addon.L
local localeCodes = {"enUS", "enGB", "frFR", "deDE", "esES", "esMX", "itIT", "ptBR", "ruRU", "koKR", "zhCN", "zhTW"}
for _, locale in ipairs(localeCodes) do
    local session = Boot(nil, false, locale)
    local L = session.addon.L
    for key in pairs(english) do
        eq(type(rawget(L, key)), "string", locale .. " has translation " .. key)
        eq(#L[key] > 0, true, locale .. " translation is not empty")
    end
    local plate = session:Add("nameplate1", "Horde")
    session:Click(L.SHOW_HORDE)
    eq(visible(plate), false, locale .. " translated filter works")
    session:Click(L.SHOW_HORDE)
    session:Click(L.RIGHT)
    eq(plate.textures[1].point[3], "RIGHT", locale .. " translated position works")
    for _, widget in ipairs(session.widgets) do
        if widget.kind == "ScrollFrame" then
            eq(widget.child.height > 520, true, "content is scrollable")
            widget:SetWidth(220)
            widget.scripts.OnSizeChanged(widget)
            eq(widget.child.width, 220, "layout adapts to viewport width")
        end
    end
    if locale ~= "enUS" and locale ~= "enGB" then
        L.ENABLED = nil
        eq(L.ENABLED, english.ENABLED, locale .. " missing translation falls back to English")
    end
end
local fallback = Boot(nil, false, "unknown").addon.L
eq(fallback.DESCRIPTION, english.DESCRIPTION, "unknown locale falls back to English")
local british = Boot(nil, false, "enGB").addon.L
for key, value in pairs(english) do eq(british[key], value, "British and US English share strings") end
print("PlateFaction: " .. checks .. " assertions passed (simulated WoW API).")
