local _, addon = ...
local L = addon.L

function addon:CreateOptions()
    if self.category then return end
    local panel = CreateFrame("Frame")
    panel:Hide()
    local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 0, -8)
    scroll:SetPoint("BOTTOMRIGHT", -28, 8)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(520, 1)
    scroll:SetScrollChild(content)

    local rows, controls, choices, sliders = {}, {}, {}, {}
    local function Label(text, font)
        local label = content:CreateFontString(nil, "ARTWORK", font or "GameFontHighlight")
        label:SetText(text)
        label:SetJustifyH("LEFT")
        rows[#rows + 1] = { kind = "label", widget = label }
    end
    local function Checkbox(text, key, choice)
        local button = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
        button.text = button.text or button.Text or button:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        button.text:ClearAllPoints()
        button.text:SetPoint("LEFT", button, "RIGHT", 2, 0)
        button.text:SetJustifyH("LEFT")
        button.text:SetText(text)
        button:SetScript("OnClick", function()
            addon:SetOption(key, choice or not not button:GetChecked())
            panel:Sync()
        end)
        if choice then
            choices[key] = choices[key] or {}
            choices[key][choice] = button
        else
            controls[key] = button
        end
        rows[#rows + 1] = { kind = "check", widget = button }
    end
    local function Slider(key, name, title, low, high)
        local label = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        label:SetJustifyH("LEFT")
        local slider = CreateFrame("Slider", name, content, "OptionsSliderTemplate")
        slider:SetMinMaxValues(low, high)
        slider:SetValueStep(1)
        slider:SetObeyStepOnDrag(true)
        _G[name .. "Low"]:SetText(tostring(low))
        _G[name .. "High"]:SetText(tostring(high))
        _G[name .. "Text"]:SetText("")
        slider:SetScript("OnValueChanged", function(_, value)
            if panel.syncing then return end
            addon:SetOption(key, value)
            panel:Sync()
        end)
        local row = { kind = "slider", widget = slider, label = label, title = title }
        sliders[key] = row
        rows[#rows + 1] = row
    end

    Label("PlateFaction", "GameFontNormalLarge")
    Label(L.DESCRIPTION)
    Checkbox(L.ENABLED, "enabled")
    Label(L.DISPLAY_MODE, "GameFontNormal")
    Checkbox(L.ICON_ONLY, "mode", "icon")
    Checkbox(L.NAME_COLOR, "mode", "color")
    Checkbox(L.ICON_AND_COLOR, "mode", "both")
    Checkbox(L.SHOW_ALLIANCE, "showAllianceIcon")
    Checkbox(L.SHOW_HORDE, "showHordeIcon")
    Label(L.POSITION, "GameFontNormal")
    Checkbox(L.LEFT, "iconPosition", "LEFT")
    Checkbox(L.RIGHT, "iconPosition", "RIGHT")
    Checkbox(L.TOP, "iconPosition", "TOP")
    Checkbox(L.BOTTOM, "iconPosition", "BOTTOM")
    Slider("iconSize", "PlateFactionIconSizeSlider", L.ICON_SIZE, 10, 64)
    Slider("iconOffsetX", "PlateFactionIconOffsetXSlider", L.OFFSET_X, -100, 100)
    Slider("iconOffsetY", "PlateFactionIconOffsetYSlider", L.OFFSET_Y, -100, 100)
    Label(L.HELP)

    function panel:Layout()
        local width = math.max(180, scroll:GetWidth())
        content:SetWidth(width)
        local y = 12
        for _, row in ipairs(rows) do
            local widget = row.widget
            widget:ClearAllPoints()
            if row.kind == "label" then
                widget:SetPoint("TOPLEFT", 16, -y)
                widget:SetWidth(width - 32)
                y = y + widget:GetStringHeight() + 16
            elseif row.kind == "check" then
                widget.text:SetWidth(width - 76)
                local height = math.max(32, widget.text:GetStringHeight() + 8)
                widget:SetPoint("TOPLEFT", 16, -y - (height - 32) / 2)
                y = y + height + 4
            else
                row.label:ClearAllPoints()
                row.label:SetPoint("TOPLEFT", 16, -y)
                row.label:SetWidth(width - 32)
                y = y + row.label:GetStringHeight() + 12
                widget:SetPoint("TOPLEFT", 20, -y)
                widget:SetSize(math.min(400, width - 48), 16)
                y = y + 48
            end
        end
        content:SetHeight(y + 12)
    end

    function panel:Sync()
        self.syncing = true
        for key, control in pairs(controls) do control:SetChecked(addon.db[key]) end
        for key, group in pairs(choices) do
            for choice, control in pairs(group) do control:SetChecked(addon.db[key] == choice) end
        end
        for key, control in pairs(sliders) do
            control.widget:SetValue(addon.db[key])
            control.label:SetText(control.title .. ": " .. addon.db[key])
        end
        self.syncing = false
        self:Layout()
    end
    scroll:SetScript("OnSizeChanged", function() panel:Layout() end)
    panel:SetScript("OnShow", panel.Sync)
    panel:Sync()
    self.category = Settings.RegisterCanvasLayoutCategory(panel, "PlateFaction")
    Settings.RegisterAddOnCategory(self.category)

    SLASH_PLATEFACTION1 = "/platefaction"
    SlashCmdList.PLATEFACTION = function()
        Settings.OpenToCategory(addon.category:GetID())
    end
end
