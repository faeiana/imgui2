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
