local ImGui = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local THEME = {
    Background = Color3.fromRGB(32, 32, 32),
    Header = Color3.fromRGB(42, 42, 42),
    Field = Color3.fromRGB(51, 51, 51),
    FieldOff = Color3.fromRGB(46, 46, 46),
    Accent = Color3.fromRGB(255, 143, 208),
    AccentBright = Color3.fromRGB(255, 154, 217),
    Text = Color3.fromRGB(220, 220, 220),
    Muted = Color3.fromRGB(154, 154, 154),
    Stroke = Color3.fromRGB(58, 58, 58),
    StrokeLight = Color3.fromRGB(74, 74, 74),
    Track = Color3.fromRGB(61, 61, 61),
}

local function create(className, properties, parent)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do object[key] = value end
    object.Parent = parent
    return object
end

local function stroke(object, color)
    return create("UIStroke", { Color = color or THEME.Stroke, Thickness = 1 }, object)
end

local function call(callback, self, value)
    if typeof(callback) == "function" then
        task.spawn(function() callback(self, value) end)
    end
end

local function proxy(instance)
    return setmetatable({ Instance = instance, Frame = instance }, {
        __index = function(self, key)
            local own = rawget(self, key)
            if own ~= nil then return own end
            local ok, value = pcall(function() return instance[key] end)
            if ok then return value end
        end,
        __newindex = function(self, key, value)
            if not pcall(function() instance[key] = value end) then rawset(self, key, value) end
        end,
    })
end

local function guiParent()
    local ok, parent = pcall(function() return CoreGui end)
    if ok and parent then return parent end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function makeDraggable(frame, handle)
    local dragging, dragStart, startPosition = false, nil, nil

    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then return end

        if frame.AnchorPoint ~= Vector2.zero then
            local absolute = frame.AbsolutePosition
            frame.AnchorPoint = Vector2.zero
            frame.Position = UDim2.fromOffset(absolute.X, absolute.Y)
        end

        dragging = true
        dragStart = input.Position
        startPosition = frame.Position
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then return end

        local delta = input.Position - dragStart
        local viewport = workspace.CurrentCamera.ViewportSize
        frame.Position = UDim2.fromOffset(
            math.clamp(startPosition.X.Offset + delta.X, -(frame.AbsoluteSize.X - 80), viewport.X - 80),
            math.clamp(startPosition.Y.Offset + delta.Y, 0, viewport.Y - 30)
        )
    end)
end

local function fmt(value, max)
    if max >= 100 then return tostring(math.floor(value + 0.5)) end
    return string.format("%.2f", value)
end

function ImGui:CreateWindow(config)
    config = config or {}

    local screenGui = create("ScreenGui", {
        Name = "FaeianaImGui",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, guiParent())

    local main = create("Frame", {
        Size = config.Size or UDim2.fromOffset(400, 480),
        Position = config.Position or UDim2.fromScale(0.5, 0.2),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = THEME.Background,
        BorderSizePixel = 0,
    }, screenGui)
    stroke(main, THEME.AccentBright)

    local titleBar = create("Frame", {
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundColor3 = THEME.Header,
        BorderSizePixel = 0,
    }, main)
    create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = THEME.Stroke,
        BorderSizePixel = 0,
    }, titleBar)

    local cutout = create("ImageLabel", {
        Size = UDim2.fromOffset(16, 16),
        Position = UDim2.fromOffset(6, 4),
        BackgroundColor3 = Color3.fromRGB(17, 17, 17),
        BorderSizePixel = 0,
        Image = "rbxassetid://110546829570407",
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 2,
    }, titleBar)
    stroke(cutout, THEME.StrokeLight)

    create("TextLabel", {
        Size = UDim2.new(1, -34, 1, 0),
        Position = UDim2.fromOffset(28, 0),
        BackgroundTransparency = 1,
        Text = config.Title or "Window",
        TextColor3 = THEME.AccentBright,
        Font = Enum.Font.Code,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, titleBar)

    makeDraggable(main, titleBar)

    local tabHolder = create("ScrollingFrame", {
        Size = UDim2.new(1, -12, 0, 20),
        Position = UDim2.fromOffset(6, 26),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.X,
        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.X,
    }, main)
    create("UIListLayout", {
        Padding = UDim.new(0, 11),
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, tabHolder)

    local pageHolder = create("Frame", {
        Size = UDim2.new(1, -12, 1, -52),
        Position = UDim2.fromOffset(6, 48),
        BackgroundTransparency = 1,
    }, main)

    local window = { Gui = screenGui, Main = main, Visible = true, Tabs = {} }

    function window:SetVisible(state)
        self.Visible = state == true
        screenGui.Enabled = self.Visible
        return self
    end

    function window:CreateTab(tabConfig)
        local name = "Tab"
        if typeof(tabConfig) == "table" then
            name = tabConfig.Name or "Tab"
        elseif tabConfig ~= nil then
            name = tostring(tabConfig)
        end

        local button = create("TextButton", {
            Size = UDim2.new(0, 0, 0, 16),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            AutomaticSize = Enum.AutomaticSize.X,
            Text = name,
            TextColor3 = THEME.Muted,
            Font = Enum.Font.Code,
            TextSize = 11,
        }, tabHolder)

        local underline = create("Frame", {
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 1, 0),
            BackgroundColor3 = THEME.AccentBright,
            BorderSizePixel = 0,
            Visible = false,
        }, button)

        local page = create("ScrollingFrame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            CanvasSize = UDim2.fromOffset(0, 0),
            Visible = false,
        }, pageHolder)

        local layout = create("UIListLayout", {
            Padding = UDim.new(0, 5),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, page)
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 10)
        end)

        local tab = { Name = name, Button = button, Page = page }

        local function selectTab()
            for _, other in ipairs(window.Tabs) do
                other.Page.Visible = false
                other.Button.TextColor3 = THEME.Muted
                other.Underline.Visible = false
            end
            page.Visible = true
            button.TextColor3 = THEME.AccentBright
            underline.Visible = true
        end

        tab.Underline = underline
        button.MouseButton1Click:Connect(selectTab)

        -- every control set is bound to a container ref, so a section keeps
        -- receiving its own controls even when created long after BuildUI
        local function controls(ref)
            local api = {}

            local function row(height)
                return create("Frame", {
                    Size = UDim2.new(1, -12, 0, height),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                }, ref.value)
            end

            function api.Label(cfg)
                local text = typeof(cfg) == "table" and (cfg.Text or cfg.Label or "") or tostring(cfg)
                local r = row(13)
                create("TextLabel", {
                    Size = UDim2.new(1, -8, 1, 0),
                    Position = UDim2.fromOffset(4, 0),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = THEME.Muted,
                    Font = Enum.Font.Code,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }, r)
                return proxy(r)
            end

            function api.Button(cfg)
                cfg = cfg or {}
                local r = row(20)
                local object = proxy(r)
                local b = create("TextButton", {
                    Size = UDim2.new(1, -8, 1, 0),
                    Position = UDim2.fromOffset(4, 0),
                    BackgroundColor3 = cfg.Color or cfg.ButtonColor or cfg.BackgroundColor3 or THEME.Field,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Text = cfg.Label or cfg.Text or "Button",
                    TextColor3 = THEME.Text,
                    Font = Enum.Font.Code,
                    TextSize = 11,
                }, r)
                stroke(b)
                b.MouseButton1Click:Connect(function() call(cfg.Callback, object, true) end)
                return object
            end

            function api.Checkbox(cfg)
                cfg = cfg or {}
                local value = cfg.Value == true
                local r = row(14)
                local object = proxy(r)

                local circle = create("TextButton", {
                    Size = UDim2.fromOffset(11, 11),
                    Position = UDim2.new(0, 4, 0.5, -5.5),
                    BackgroundColor3 = value and THEME.Accent or THEME.FieldOff,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Text = "",
                }, r)
                create("UICorner", { CornerRadius = UDim.new(1, 0) }, circle)
                local circleStroke = stroke(circle, value and THEME.AccentBright or THEME.StrokeLight)

                local label = create("TextLabel", {
                    Size = UDim2.new(1, -26, 1, 0),
                    Position = UDim2.fromOffset(20, 0),
                    BackgroundTransparency = 1,
                    Text = cfg.Label or "Checkbox",
                    TextColor3 = value and THEME.Text or THEME.Muted,
                    Font = Enum.Font.Code,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }, r)

                local function paint(state)
                    circle.BackgroundColor3 = state and THEME.Accent or THEME.FieldOff
                    circleStroke.Color = state and THEME.AccentBright or THEME.StrokeLight
                    label.TextColor3 = state and THEME.Text or THEME.Muted
                end

                function object:Set(newValue)
                    value = newValue == true
                    paint(value)
                    call(cfg.Callback, object, value)
                    return object
                end

                function object:Get() return value end

                circle.MouseButton1Click:Connect(function() object:Set(not value) end)
                return object
            end

            function api.Slider(cfg)
                cfg = cfg or {}
                local min = cfg.MinValue or cfg.Min or 0
                local max = cfg.MaxValue or cfg.Max or 100
                local value = math.clamp(cfg.Value or min, min, max)
                local r = row(32)
                local object = proxy(r)

                create("TextLabel", {
                    Size = UDim2.new(1, -72, 0, 13),
                    Position = UDim2.fromOffset(4, 0),
                    BackgroundTransparency = 1,
                    Text = cfg.Label or "Slider",
                    TextColor3 = THEME.Text,
                    Font = Enum.Font.Code,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }, r)

                local valueLabel = create("TextLabel", {
                    Size = UDim2.fromOffset(66, 13),
                    Position = UDim2.new(1, -70, 0, 0),
                    BackgroundTransparency = 1,
                    TextColor3 = THEME.AccentBright,
                    Font = Enum.Font.Code,
                    TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Right,
                }, r)

                local bar = create("TextButton", {
                    Size = UDim2.new(1, -8, 0, 5),
                    Position = UDim2.fromOffset(4, 17),
                    BackgroundColor3 = THEME.Track,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Text = "",
                }, r)
                stroke(bar)

                local fill = create("Frame", {
                    Size = UDim2.fromScale(0, 1),
                    BackgroundColor3 = THEME.Accent,
                    BorderSizePixel = 0,
                }, bar)

                local function refresh()
                    local span = max - min
                    local alpha = span == 0 and 0 or (value - min) / span
                    fill.Size = UDim2.fromScale(math.clamp(alpha, 0, 1), 1)
                    valueLabel.Text = fmt(value, max) .. "/" .. fmt(max, max)
                end

                function object:Set(newValue)
                    value = math.clamp(tonumber(newValue) or min, min, max)
                    refresh()
                    call(cfg.Callback, object, value)
                    return object
                end

                function object:Get() return value end

                local dragging = false
                local function fromMouse()
                    local width = math.max(bar.AbsoluteSize.X, 1)
                    local alpha = math.clamp((UserInputService:GetMouseLocation().X - bar.AbsolutePosition.X) / width, 0, 1)
                    object:Set(min + ((max - min) * alpha))
                end

                bar.MouseButton1Down:Connect(function() dragging = true; fromMouse() end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then fromMouse() end
                end)

                refresh()
                return object
            end

            function api.Combo(cfg)
                cfg = cfg or {}
                local items = cfg.Items or cfg.Options or {}
                local value = cfg.Value or items[1] or "None"
                local r = row(18)
                local object = proxy(r)
                local open = false

                local b = create("TextButton", {
                    Size = UDim2.new(1, -8, 0, 18),
                    Position = UDim2.fromOffset(4, 0),
                    BackgroundColor3 = THEME.Field,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Text = "",
                }, r)
                stroke(b)

                local shown = create("TextLabel", {
                    Size = UDim2.new(1, -18, 1, 0),
                    Position = UDim2.fromOffset(5, 0),
                    BackgroundTransparency = 1,
                    Text = tostring(value),
                    TextColor3 = THEME.Text,
                    Font = Enum.Font.Code,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }, b)

                create("TextLabel", {
                    Size = UDim2.fromOffset(12, 18),
                    Position = UDim2.new(1, -14, 0, 0),
                    BackgroundTransparency = 1,
                    Text = "v",
                    TextColor3 = THEME.Accent,
                    Font = Enum.Font.Code,
                    TextSize = 9,
                }, b)

                local list = create("Frame", {
                    Size = UDim2.new(1, -8, 0, #items * 18),
                    Position = UDim2.fromOffset(4, 20),
                    BackgroundColor3 = THEME.Field,
                    BorderSizePixel = 0,
                    Visible = false,
                    ZIndex = 5,
                }, r)
                stroke(list)
                create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, list)

                local function setOpen(state)
                    open = state == true
                    list.Visible = open
                    r.Size = open and UDim2.new(1, -12, 0, 20 + (#items * 18)) or UDim2.new(1, -12, 0, 18)
                end

                function object:Set(newValue)
                    value = newValue
                    shown.Text = tostring(value)
                    call(cfg.Callback, object, value)
                    return object
                end

                function object:Get() return value end

                for _, item in ipairs(items) do
                    local option = create("TextButton", {
                        Size = UDim2.new(1, 0, 0, 18),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        AutoButtonColor = false,
                        Text = tostring(item),
                        TextColor3 = THEME.Text,
                        Font = Enum.Font.Code,
                        TextSize = 11,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 6,
                    }, list)
                    create("UIPadding", { PaddingLeft = UDim.new(0, 5) }, option)
                    option.MouseButton1Click:Connect(function() object:Set(item); setOpen(false) end)
                end

                b.MouseButton1Click:Connect(function() setOpen(not open) end)
                return object
            end

            function api.Keybind(cfg)
                cfg = cfg or {}
                local value = cfg.Value or Enum.KeyCode.Unknown
                local r = row(14)
                local object = proxy(r)
                local waiting = false

                create("TextLabel", {
                    Size = UDim2.new(1, -70, 1, 0),
                    Position = UDim2.fromOffset(4, 0),
                    BackgroundTransparency = 1,
                    Text = cfg.Label or "Keybind",
                    TextColor3 = THEME.Text,
                    Font = Enum.Font.Code,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }, r)

                local b = create("TextButton", {
                    Size = UDim2.fromOffset(62, 13),
                    Position = UDim2.new(1, -66, 0.5, -6.5),
                    BackgroundColor3 = THEME.Field,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Text = value.Name or "None",
                    TextColor3 = THEME.Text,
                    Font = Enum.Font.Code,
                    TextSize = 10,
                }, r)
                stroke(b)

                function object:Set(newValue)
                    value = newValue or Enum.KeyCode.Unknown
                    b.Text = value.Name or "None"
                    call(cfg.Callback, object, value)
                    return object
                end

                function object:Get() return value end

                b.MouseButton1Click:Connect(function() waiting = true; b.Text = "..." end)
                UserInputService.InputBegan:Connect(function(input, processed)
                    if processed or not waiting then return end
                    if input.KeyCode == Enum.KeyCode.Unknown then return end
                    waiting = false
                    object:Set(input.KeyCode)
                end)

                return object
            end

            return api
        end

        local tabRef = { value = page }
        local tabApi = controls(tabRef)
        for key, fn in pairs(tabApi) do tab[key] = fn end

        function tab:Section(sectionName)
            local section = create("Frame", {
                Size = UDim2.new(1, -12, 0, 18),
                BackgroundColor3 = THEME.Background,
                BorderSizePixel = 0,
            }, page)
            stroke(section)

            create("TextLabel", {
                Size = UDim2.new(1, 0, 0, 18),
                BackgroundColor3 = THEME.Header,
                BorderSizePixel = 0,
                Text = tostring(sectionName or "Section"),
                TextColor3 = THEME.AccentBright,
                Font = Enum.Font.Code,
                TextSize = 11,
            }, section)

            local body = create("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.fromOffset(0, 18),
                BackgroundColor3 = THEME.Background,
                BorderSizePixel = 0,
            }, section)

            local bodyLayout = create("UIListLayout", {
                Padding = UDim.new(0, 3),
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder,
            }, body)
            bodyLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                local height = bodyLayout.AbsoluteContentSize.Y + 7
                body.Size = UDim2.new(1, 0, 0, height)
                section.Size = UDim2.new(1, -12, 0, 18 + height)
            end)

            local sectionProxy = proxy(section)
            for key, fn in pairs(controls({ value = body })) do
                sectionProxy[key] = fn
            end
            return sectionProxy
        end

        function tab:Rebuild() return self end

        table.insert(window.Tabs, tab)
        if #window.Tabs == 1 then selectTab() end
        return tab
    end

    function window:TabCreate(name) return self:CreateTab({ Name = name }) end
    return window
end

function ImGui:Window(config) return self:CreateWindow(config) end
ImGui.Window = ImGui.CreateWindow

return ImGui
