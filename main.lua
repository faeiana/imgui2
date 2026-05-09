local ImGui = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local THEME = {
    Background = Color3.fromRGB(5, 5, 6),
    Header = Color3.fromRGB(7, 7, 9),
    Border = Color3.fromRGB(26, 26, 28),
    Section = Color3.fromRGB(8, 8, 9),
    Control = Color3.fromRGB(48, 48, 48),
    ControlDark = Color3.fromRGB(30, 30, 31),
    Text = Color3.fromRGB(236, 236, 236),
    Muted = Color3.fromRGB(121, 121, 126),
    Disabled = Color3.fromRGB(70, 70, 74),
    Accent = Color3.fromRGB(255, 177, 232),
    AccentText = Color3.fromRGB(255, 255, 255)
}

local windows = {}
local themedObjects = {}

local function create(className, properties, parent)
    local object = Instance.new(className)

    for key, value in pairs(properties or {}) do
        object[key] = value
    end

    object.Parent = parent
    return object
end

local function applyTheme(object, property, themeKey)
    object[property] = THEME[themeKey]
    table.insert(themedObjects, {
        Object = object,
        Property = property,
        Key = themeKey
    })
end

function ImGui:SetTheme(theme)
    for key, value in pairs(theme or {}) do
        if THEME[key] ~= nil and typeof(value) == "Color3" then
            THEME[key] = value
        end
    end

    for _, item in ipairs(themedObjects) do
        if item.Object and item.Object.Parent and THEME[item.Key] then
            pcall(function()
                item.Object[item.Property] = THEME[item.Key]
            end)
        end
    end

    return self
end

local function theme(object, property, key)
    applyTheme(object, property, key)
    return object
end

local function round(object, radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius or 3)
    }, object)
end

local function stroke(object, key, transparency)
    local line = create("UIStroke", {
        Thickness = 1,
        Transparency = transparency or 0.25
    }, object)

    theme(line, "Color", key or "Border")
    return line
end

local function callback(fn, self, value)
    if typeof(fn) == "function" then
        task.spawn(function()
            fn(self, value)
        end)
    end
end

local function proxy(instance)
    local object = {
        Instance = instance
    }

    return setmetatable(object, {
        __index = function(self, key)
            local ownValue = rawget(self, key)
            if ownValue ~= nil then
                return ownValue
            end

            local ok, value = pcall(function()
                return instance[key]
            end)

            if ok then
                return value
            end

            return nil
        end,

        __newindex = function(self, key, value)
            local ok = pcall(function()
                instance[key] = value
            end)

            if not ok then
                rawset(self, key, value)
            end
        end
    })
end

local function getGuiParent()
    local ok, parent = pcall(function()
        return CoreGui
    end)

    if ok and parent then
        return parent
    end

    return LocalPlayer:WaitForChild("PlayerGui")
end

local function draggable(frame, handle)
    local dragging = false
    local dragStart
    local startPosition

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPosition = frame.Position
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)
end

local function getTextWidth(text)
    return math.clamp((#tostring(text) * 7) + 20, 48, 110)
end

local function setButtonHover(button, baseKey)
    button.MouseEnter:Connect(function()
        button.BackgroundTransparency = 0.1
    end)

    button.MouseLeave:Connect(function()
        button.BackgroundTransparency = 0
        if baseKey then
            theme(button, "BackgroundColor3", baseKey)
        end
    end)
end

local function formatNumber(value)
    local rounded = math.floor((value * 100) + 0.5) / 100

    if math.abs(rounded - math.floor(rounded)) < 0.001 then
        return tostring(math.floor(rounded))
    end

    return string.format("%.2f", rounded)
end

local function createKeybindList(config)
    config = config or {}

    local gui = create("ScreenGui", {
        Name = config.Name or "MatchaKeybindList",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, getGuiParent())

    local frame = create("Frame", {
        Size = config.Size or UDim2.fromOffset(110, 38),
        Position = config.Position or UDim2.fromOffset(20, 195),
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0
    }, gui)
    theme(frame, "BackgroundColor3", "Background")
    stroke(frame, "Border", 0.35)

    local icon = create("TextLabel", {
        Size = UDim2.fromOffset(24, 38),
        BackgroundTransparency = 1,
        Text = config.Icon or "@",
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = THEME.Accent,
        TextXAlignment = Enum.TextXAlignment.Center
    }, frame)
    theme(icon, "TextColor3", "Accent")

    local label = create("TextLabel", {
        Size = UDim2.new(1, -28, 1, 0),
        Position = UDim2.fromOffset(28, 0),
        BackgroundTransparency = 1,
        Text = config.Title or "Keybind List",
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left
    }, frame)
    theme(label, "TextColor3", "Text")

    draggable(frame, frame)

    return {
        Gui = gui,
        Frame = frame,
        SetVisible = function(self, visible)
            gui.Enabled = visible == true
            return self
        end,
        Destroy = function()
            gui:Destroy()
        end
    }
end

function ImGui:CreateKeybindList(config)
    return createKeybindList(config)
end

function ImGui:CreateWindow(config)
    config = config or {}

    local gui = create("ScreenGui", {
        Name = config.Name or "MatchaStyleImGui",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, getGuiParent())
    table.insert(windows, gui)

    local main = create("Frame", {
        Name = "Window",
        Size = config.Size or UDim2.fromOffset(525, 650),
        Position = config.Position or UDim2.fromScale(0.5, 0.08),
        AnchorPoint = config.AnchorPoint or Vector2.new(0.5, 0),
        BackgroundTransparency = config.BackgroundTransparency or 0.12,
        BorderSizePixel = 0,
        ClipsDescendants = true
    }, gui)
    theme(main, "BackgroundColor3", "Background")
    stroke(main, "Border", 0.25)
    round(main, 4)

    local titleBar = create("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundTransparency = 0.06,
        BorderSizePixel = 0
    }, main)
    theme(titleBar, "BackgroundColor3", "Header")

    local titleIcon = create("TextLabel", {
        Size = UDim2.fromOffset(24, 26),
        Position = UDim2.fromOffset(3, 0),
        BackgroundTransparency = 1,
        Text = config.Icon or "M",
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Center
    }, titleBar)
    theme(titleIcon, "TextColor3", "Accent")

    local title = create("TextLabel", {
        Size = UDim2.new(1, -34, 1, 0),
        Position = UDim2.fromOffset(27, 0),
        BackgroundTransparency = 1,
        Text = config.Title or "matcha @mynameiscloudy   discord.gg/matchaiol",
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left
    }, titleBar)
    theme(title, "TextColor3", "Muted")

    local divider = create("Frame", {
        Size = UDim2.new(1, -8, 0, 1),
        Position = UDim2.new(0, 4, 1, -1),
        BorderSizePixel = 0,
        BackgroundTransparency = 0.2
    }, titleBar)
    theme(divider, "BackgroundColor3", "Border")

    local tabBar = create("Frame", {
        Name = "TabBar",
        Size = UDim2.new(1, -14, 0, 27),
        Position = UDim2.fromOffset(7, 27),
        BackgroundTransparency = 1
    }, main)

    local tabLayout = create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 14),
        VerticalAlignment = Enum.VerticalAlignment.Center
    }, tabBar)

    local pages = create("Frame", {
        Name = "Pages",
        Size = UDim2.new(1, -14, 1, -58),
        Position = UDim2.fromOffset(7, 55),
        BackgroundTransparency = 1
    }, main)

    draggable(main, titleBar)

    local window = {
        Gui = gui,
        Main = main,
        Visible = true,
        Tabs = {},
        KeybindList = nil
    }

    function window:SetVisible(visible)
        self.Visible = visible == true
        gui.Enabled = self.Visible
        return self
    end

    function window:SetTheme(themeTable)
        ImGui:SetTheme(themeTable)
        return self
    end

    function window:CreateKeybindList(keybindConfig)
        self.KeybindList = createKeybindList(keybindConfig)
        return self.KeybindList
    end

    function window:Destroy()
        gui:Destroy()
        return self
    end

    function window:CreateTab(tabConfig)
        local tabName = "Tab"

        if typeof(tabConfig) == "table" then
            tabName = tabConfig.Name or tabConfig.Title or "Tab"
        elseif tabConfig ~= nil then
            tabName = tostring(tabConfig)
        end

        local tabButton = create("TextButton", {
            Name = tabName .. "Tab",
            Size = UDim2.fromOffset(getTextWidth(tabName), 22),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = tabName,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left
        }, tabBar)
        theme(tabButton, "TextColor3", "Muted")

        local page = create("ScrollingFrame", {
            Name = tabName .. "Page",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 2,
            ScrollBarImageTransparency = 0.45,
            CanvasSize = UDim2.fromOffset(0, 0),
            Visible = false
        }, pages)

        local columns = create("Frame", {
            Name = "Columns",
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1
        }, page)

        local leftColumn = create("Frame", {
            Name = "Left",
            Size = UDim2.new(0.5, -4, 0, 0),
            BackgroundTransparency = 1
        }, columns)

        local rightColumn = create("Frame", {
            Name = "Right",
            Size = UDim2.new(0.5, -4, 0, 0),
            Position = UDim2.new(0.5, 4, 0, 0),
            BackgroundTransparency = 1
        }, columns)

        local leftLayout = create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 5)
        }, leftColumn)

        local rightLayout = create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 5)
        }, rightColumn)

        local tab = {
            Name = tabName,
            Button = tabButton,
            Page = page,
            LeftColumn = leftColumn,
            RightColumn = rightColumn,
            Sections = {},
            DefaultSection = nil,
            NextSide = "Left"
        }

        local function refreshCanvas()
            local leftHeight = leftLayout.AbsoluteContentSize.Y
            local rightHeight = rightLayout.AbsoluteContentSize.Y
            local height = math.max(leftHeight, rightHeight) + 8

            leftColumn.Size = UDim2.new(0.5, -4, 0, leftHeight)
            rightColumn.Size = UDim2.new(0.5, -4, 0, rightHeight)
            columns.Size = UDim2.new(1, 0, 0, height)
            page.CanvasSize = UDim2.fromOffset(0, height)
        end

        leftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshCanvas)
        rightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshCanvas)

        local function selectTab()
            for _, other in ipairs(window.Tabs) do
                other.Page.Visible = false
                theme(other.Button, "TextColor3", "Muted")
            end

            page.Visible = true
            theme(tabButton, "TextColor3", "Text")
        end

        tabButton.MouseButton1Click:Connect(selectTab)

        function tab:Section(sectionConfig)
            local sectionName = "Section"
            local side = self.NextSide

            if typeof(sectionConfig) == "table" then
                sectionName = sectionConfig.Name or sectionConfig.Title or "Section"
                side = sectionConfig.Side or sectionConfig.Column or side
            elseif sectionConfig ~= nil then
                sectionName = tostring(sectionConfig)
            end

            side = tostring(side):lower() == "right" and "Right" or "Left"
            self.NextSide = side == "Left" and "Right" or "Left"

            local parent = side == "Left" and leftColumn or rightColumn

            local sectionFrame = create("Frame", {
                Name = sectionName .. "Section",
                Size = UDim2.new(1, 0, 0, 28),
                BackgroundTransparency = 0.16,
                BorderSizePixel = 0
            }, parent)
            theme(sectionFrame, "BackgroundColor3", "Section")
            stroke(sectionFrame, "Border", 0.65)
            round(sectionFrame, 3)

            local sectionLayout = create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 2)
            }, sectionFrame)

            local header = create("TextLabel", {
                Size = UDim2.new(1, -12, 0, 23),
                Position = UDim2.fromOffset(6, 0),
                BackgroundTransparency = 1,
                Text = sectionName,
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left
            }, sectionFrame)
            theme(header, "TextColor3", "Text")

            local section = {
                Name = sectionName,
                Frame = sectionFrame,
                Layout = sectionLayout
            }

            local function refreshSection()
                sectionFrame.Size = UDim2.new(1, 0, 0, sectionLayout.AbsoluteContentSize.Y + 5)
                refreshCanvas()
            end

            sectionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshSection)

            local function makeControlRow(height)
                local row = create("Frame", {
                    Size = UDim2.new(1, -10, 0, height),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0
                }, sectionFrame)
                return row
            end

            function section:Label(config)
                local text = typeof(config) == "table" and (config.Text or config.Label or "") or tostring(config)
                local row = makeControlRow(18)

                local label = create("TextLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = text,
                    Font = Enum.Font.GothamSemibold,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left
                }, row)
                theme(label, "TextColor3", "Muted")

                refreshSection()
                return proxy(row)
            end

            function section:Button(config)
                config = config or {}

                local label = typeof(config) == "table" and (config.Label or config.Text or config.Name or "Button") or tostring(config)
                local row = makeControlRow(26)

                local button = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 22),
                    Position = UDim2.fromOffset(0, 2),
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Text = label,
                    Font = Enum.Font.GothamSemibold,
                    TextSize = 11
                }, row)
                theme(button, "BackgroundColor3", "Control")
                theme(button, "TextColor3", "Text")
                round(button, 9)
                setButtonHover(button, "Control")

                local object = proxy(row)
                button.MouseButton1Click:Connect(function()
                    callback(config.Callback, object, nil)
                end)

                refreshSection()
                return object
            end

            function section:Checkbox(config)
                config = config or {}

                local value = config.Value == true
                local row = makeControlRow(22)
                local object = proxy(row)

                local circle = create("TextButton", {
                    Size = UDim2.fromOffset(18, 18),
                    Position = UDim2.fromOffset(0, 2),
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Text = ""
                }, row)
                theme(circle, "BackgroundColor3", value and "Accent" or "ControlDark")
                round(circle, 9)

                local label = create("TextLabel", {
                    Size = UDim2.new(1, config.Keybind and -76 or -22, 1, 0),
                    Position = UDim2.fromOffset(24, 0),
                    BackgroundTransparency = 1,
                    Text = config.Label or "Enabled",
                    Font = Enum.Font.GothamSemibold,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left
                }, row)
                theme(label, "TextColor3", config.Disabled and "Disabled" or "Muted")

                local bindButton
                if config.Keybind then
                    bindButton = create("TextButton", {
                        Size = UDim2.fromOffset(60, 20),
                        Position = UDim2.new(1, -60, 0, 1),
                        BackgroundTransparency = 0,
                        BorderSizePixel = 0,
                        AutoButtonColor = false,
                        Text = tostring(config.Keybind),
                        Font = Enum.Font.GothamBold,
                        TextSize = 10
                    }, row)
                    theme(bindButton, "BackgroundColor3", "ControlDark")
                    theme(bindButton, "TextColor3", "Text")
                    round(bindButton, 2)
                end

                function object:Set(newValue)
                    value = newValue == true
                    theme(circle, "BackgroundColor3", value and "Accent" or "ControlDark")
                    callback(config.Callback, object, value)
                    return object
                end

                function object:Get()
                    return value
                end

                circle.MouseButton1Click:Connect(function()
                    object:Set(not value)
                end)

                label.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        object:Set(not value)
                    end
                end)

                refreshSection()
                return object
            end

            function section:Slider(config)
                config = config or {}

                local minValue = config.MinValue or config.Min or 0
                local maxValue = config.MaxValue or config.Max or 100
                local value = math.clamp(config.Value or minValue, minValue, maxValue)
                local row = makeControlRow(40)
                local object = proxy(row)

                local label = create("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 16),
                    BackgroundTransparency = 1,
                    Text = config.Label or "Slider",
                    Font = Enum.Font.GothamBold,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left
                }, row)
                theme(label, "TextColor3", "Text")

                local bar = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 18),
                    Position = UDim2.fromOffset(0, 18),
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Text = ""
                }, row)
                theme(bar, "BackgroundColor3", "Control")
                round(bar, 9)

                local fill = create("Frame", {
                    Size = UDim2.fromScale(0, 1),
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0
                }, bar)
                theme(fill, "BackgroundColor3", "Accent")
                round(fill, 9)

                local knob = create("Frame", {
                    Size = UDim2.fromOffset(14, 14),
                    Position = UDim2.fromOffset(0, 2),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BorderSizePixel = 0
                }, bar)
                round(knob, 7)

                local valueText = create("TextLabel", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextSize = 11,
                    TextStrokeTransparency = 0.25,
                    TextColor3 = Color3.fromRGB(255, 255, 255)
                }, bar)

                local function update()
                    local range = maxValue - minValue
                    local alpha = range == 0 and 0 or (value - minValue) / range
                    alpha = math.clamp(alpha, 0, 1)
                    fill.Size = UDim2.fromScale(alpha, 1)
                    knob.Position = UDim2.new(alpha, -7, 0, 2)
                    valueText.Text = formatNumber(value) .. "/" .. formatNumber(maxValue)
                end

                function object:Set(newValue)
                    value = math.clamp(tonumber(newValue) or minValue, minValue, maxValue)
                    update()
                    callback(config.Callback, object, value)
                    return object
                end

                function object:Get()
                    return value
                end

                local dragging = false

                local function updateFromMouse()
                    local width = math.max(bar.AbsoluteSize.X, 1)
                    local alpha = math.clamp((UserInputService:GetMouseLocation().X - bar.AbsolutePosition.X) / width, 0, 1)
                    object:Set(minValue + ((maxValue - minValue) * alpha))
                end

                bar.MouseButton1Down:Connect(function()
                    dragging = true
                    updateFromMouse()
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        updateFromMouse()
                    end
                end)

                update()
                refreshSection()
                return object
            end

            function section:Combo(config)
                config = config or {}

                local items = config.Items or config.Options or {}
                local value = config.Value or items[1] or "None"
                local row = makeControlRow(44)
                local object = proxy(row)
                local open = false

                local label = create("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 16),
                    BackgroundTransparency = 1,
                    Text = config.Label or "Combo",
                    Font = Enum.Font.GothamBold,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left
                }, row)
                theme(label, "TextColor3", "Text")

                local button = create("TextButton", {
                    Size = UDim2.new(1, -22, 0, 22),
                    Position = UDim2.fromOffset(0, 18),
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Text = tostring(value),
                    Font = Enum.Font.GothamBold,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left
                }, row)
                theme(button, "BackgroundColor3", "Control")
                theme(button, "TextColor3", "Text")
                round(button, 9)

                local buttonPadding = create("UIPadding", {
                    PaddingLeft = UDim.new(0, 9),
                    PaddingRight = UDim.new(0, 9)
                }, button)

                local arrow = create("TextLabel", {
                    Size = UDim2.fromOffset(18, 22),
                    Position = UDim2.new(1, -18, 0, 18),
                    BackgroundTransparency = 1,
                    Text = "v",
                    Font = Enum.Font.GothamBold,
                    TextSize = 12
                }, row)
                theme(arrow, "TextColor3", "Text")

                local list = create("Frame", {
                    Size = UDim2.new(1, -22, 0, #items * 22),
                    Position = UDim2.fromOffset(0, 43),
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,
                    Visible = false
                }, row)
                theme(list, "BackgroundColor3", "ControlDark")
                stroke(list, "Border", 0.4)
                round(list, 5)

                create("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder
                }, list)

                local function setOpen(state)
                    open = state == true
                    list.Visible = open
                    arrow.Text = open and "^" or "v"
                    row.Size = open and UDim2.new(1, -10, 0, 48 + (#items * 22)) or UDim2.new(1, -10, 0, 44)
                    refreshSection()
                end

                function object:Set(newValue)
                    value = newValue
                    button.Text = tostring(value)
                    callback(config.Callback, object, value)
                    return object
                end

                function object:Get()
                    return value
                end

                for _, item in ipairs(items) do
                    local option = create("TextButton", {
                        Size = UDim2.new(1, 0, 0, 22),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        AutoButtonColor = false,
                        Text = tostring(item),
                        Font = Enum.Font.GothamSemibold,
                        TextSize = 11,
                        TextXAlignment = Enum.TextXAlignment.Left
                    }, list)
                    theme(option, "TextColor3", "Text")

                    create("UIPadding", {
                        PaddingLeft = UDim.new(0, 8)
                    }, option)

                    option.MouseButton1Click:Connect(function()
                        object:Set(item)
                        setOpen(false)
                    end)
                end

                button.MouseButton1Click:Connect(function()
                    setOpen(not open)
                end)

                refreshSection()
                return object
            end

            function section:Keybind(config)
                config = config or {}

                local value = config.Value or Enum.KeyCode.Unknown
                local row = makeControlRow(24)
                local object = proxy(row)
                local waiting = false

                local label = create("TextLabel", {
                    Size = UDim2.new(1, -70, 1, 0),
                    BackgroundTransparency = 1,
                    Text = config.Label or "Keybind",
                    Font = Enum.Font.GothamSemibold,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left
                }, row)
                theme(label, "TextColor3", "Muted")

                local button = create("TextButton", {
                    Size = UDim2.fromOffset(60, 20),
                    Position = UDim2.new(1, -60, 0, 2),
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Text = value.Name or "none",
                    Font = Enum.Font.GothamBold,
                    TextSize = 10
                }, row)
                theme(button, "BackgroundColor3", "ControlDark")
                theme(button, "TextColor3", "Text")
                round(button, 2)

                function object:Set(newValue)
                    value = newValue or Enum.KeyCode.Unknown
                    button.Text = value.Name or "none"
                    callback(config.Callback, object, value)
                    return object
                end

                function object:Get()
                    return value
                end

                button.MouseButton1Click:Connect(function()
                    waiting = true
                    button.Text = "..."
                end)

                UserInputService.InputBegan:Connect(function(input, processed)
                    if processed or not waiting then
                        return
                    end

                    if input.KeyCode == Enum.KeyCode.Unknown then
                        return
                    end

                    waiting = false
                    object:Set(input.KeyCode)
                end)

                refreshSection()
                return object
            end

            function section:ColorBox(config)
                config = config or {}

                local row = makeControlRow(24)
                local object = proxy(row)
                local color = config.Value or Color3.fromRGB(255, 255, 255)

                local label = create("TextLabel", {
                    Size = UDim2.new(1, -54, 1, 0),
                    BackgroundTransparency = 1,
                    Text = config.Label or "Color",
                    Font = Enum.Font.GothamSemibold,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left
                }, row)
                theme(label, "TextColor3", "Muted")

                local box = create("TextButton", {
                    Size = UDim2.fromOffset(18, 18),
                    Position = UDim2.new(1, -42, 0, 3),
                    BackgroundColor3 = color,
                    BorderSizePixel = 0,
                    Text = "",
                    AutoButtonColor = false
                }, row)
                round(box, 3)

                local checker = create("TextButton", {
                    Size = UDim2.fromOffset(18, 18),
                    Position = UDim2.new(1, -20, 0, 3),
                    BackgroundColor3 = Color3.fromRGB(205, 205, 205),
                    BorderSizePixel = 0,
                    Text = "",
                    AutoButtonColor = false
                }, row)
                round(checker, 3)

                function object:Set(newColor)
                    if typeof(newColor) == "Color3" then
                        color = newColor
                        box.BackgroundColor3 = color
                        callback(config.Callback, object, color)
                    end
                    return object
                end

                function object:Get()
                    return color
                end

                box.MouseButton1Click:Connect(function()
                    callback(config.Callback, object, color)
                end)

                refreshSection()
                return object
            end

            table.insert(self.Sections, section)
            refreshSection()
            refreshCanvas()
            return section
        end

        local function getDefaultSection()
            if not tab.DefaultSection then
                tab.DefaultSection = tab:Section({
                    Name = tab.Name,
                    Side = "Left"
                })
            end

            return tab.DefaultSection
        end

        function tab:Label(config)
            return getDefaultSection():Label(config)
        end

        function tab:Button(config)
            return getDefaultSection():Button(config)
        end

        function tab:Checkbox(config)
            return getDefaultSection():Checkbox(config)
        end

        function tab:Slider(config)
            return getDefaultSection():Slider(config)
        end

        function tab:Combo(config)
            return getDefaultSection():Combo(config)
        end

        function tab:Keybind(config)
            return getDefaultSection():Keybind(config)
        end

        function tab:ColorBox(config)
            return getDefaultSection():ColorBox(config)
        end

        function tab:Rebuild()
            return self
        end

        table.insert(window.Tabs, tab)

        if #window.Tabs == 1 then
            selectTab()
        end

        refreshCanvas()
        return tab
    end

    function window:TabCreate(name)
        return self:CreateTab({ Name = name })
    end

    if config.KeybindList then
        window:CreateKeybindList(config.KeybindList)
    end

    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tabBar.Size = UDim2.new(1, -14, 0, 27)
    end)

    return window
end

function ImGui:Window(config)
    return self:CreateWindow(config)
end

ImGui.Window = ImGui.CreateWindow

return ImGui
