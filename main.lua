-- Services
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player           = Players.LocalPlayer

-- Tween helper
local function createTween(obj, props, duration, style, dir)
    local info  = TweenInfo.new(
        duration or 0.4,
        style    or Enum.EasingStyle.Quart,
        dir      or Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(obj, info, props)
    tween:Play()
    return tween
end

local function createGUI()
    -- Container
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name           = "FakeLagUI"
    screenGui.Parent         = player:WaitForChild("PlayerGui")
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn   = false

    -- LOADING LABEL
    local loading = Instance.new("TextLabel")
    loading.Name               = "LoadingLabel"
    loading.Size               = UDim2.new(0, 150, 0, 40)
    loading.Position           = UDim2.new(0.5, -75, 0.5, -20)
    loading.BackgroundColor3   = Color3.fromRGB(40, 40, 40)
    loading.BackgroundTransparency = 0.3
    loading.TextColor3         = Color3.new(1, 1, 1)
    loading.Font               = Enum.Font.GothamBold
    loading.TextSize           = 18
    loading.Text               = "Loading…"
    loading.Parent             = screenGui

    local loadingCorner = Instance.new("UICorner", loading)
    loadingCorner.CornerRadius = UDim.new(0, 8)

    -- Pulse the loading label
    local pulsing = true
    task.spawn(function()
        while pulsing do
            createTween(loading, {TextTransparency = 1}, 0.8, Enum.EasingStyle.Sine)
            createTween(loading, {TextTransparency = 0}, 0.8, Enum.EasingStyle.Sine)
            task.wait(1.6)
        end
    end)

    -- MAIN FRAME (hidden until after loading)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name               = "MainFrame"
    mainFrame.Size               = UDim2.new(0, 300, 0, 200)
    mainFrame.Position           = UDim2.new(0.5, -150, 0.5, -100)
    mainFrame.BackgroundColor3   = Color3.fromRGB(25, 25, 25)
    mainFrame.BackgroundTransparency = 1
    mainFrame.Visible            = false
    mainFrame.Parent             = screenGui

    local mainCorner = Instance.new("UICorner", mainFrame)
    mainCorner.CornerRadius = UDim.new(0, 12)

    -- MAKE IT DRAGGABLE
    do
        local dragging, dragInput, dragStart, startPos
        local function update(input)
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end

        mainFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging  = true
                dragStart = input.Position
                startPos  = mainFrame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        mainFrame.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                dragInput = input
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and input == dragInput then
                update(input)
            end
        end)
    end

    -- TITLE
    local title = Instance.new("TextLabel", mainFrame)
    title.Size               = UDim2.new(1, 0, 0, 40)
    title.Position           = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text               = "FakeLag Control"
    title.TextColor3         = Color3.new(1, 1, 1)
    title.Font               = Enum.Font.GothamBold
    title.TextSize           = 20
    title.TextTransparency   = 1

    -- TOGGLE BUTTON
    local toggleBtn = Instance.new("TextButton", mainFrame)
    toggleBtn.Size              = UDim2.new(0, 260, 0, 40)
    toggleBtn.Position          = UDim2.new(0.5, -130, 0, 50)
    toggleBtn.BackgroundColor3  = Color3.fromRGB(40, 40, 40)
    toggleBtn.TextColor3        = Color3.new(1, 1, 1)
    toggleBtn.Font              = Enum.Font.Gotham
    toggleBtn.TextSize          = 18
    toggleBtn.Text              = "FakeLag: OFF"
    toggleBtn.BackgroundTransparency = 1

    local toggleCorner = Instance.new("UICorner", toggleBtn)
    toggleCorner.CornerRadius = UDim.new(0, 8)

    -- DELAY INPUT
    local delayInput = Instance.new("TextBox", mainFrame)
    delayInput.Size                 = UDim2.new(0, 260, 0, 30)
    delayInput.Position             = UDim2.new(0.5, -130, 0, 100)
    delayInput.BackgroundColor3     = Color3.fromRGB(35, 35, 35)
    delayInput.TextColor3           = Color3.new(1, 1, 1)
    delayInput.Font                 = Enum.Font.Gotham
    delayInput.TextSize             = 16
    delayInput.PlaceholderText      = "Lag Delay (sec)"
    delayInput.Text                 = "2.0"
    delayInput.ClearTextOnFocus     = false
    delayInput.BackgroundTransparency = 1
    delayInput.TextTransparency     = 1

    local delayCorner = Instance.new("UICorner", delayInput)
    delayCorner.CornerRadius = UDim.new(0, 6)

    -- DESTROY BUTTON
    local destroyBtn = Instance.new("TextButton", mainFrame)
    destroyBtn.Size               = UDim2.new(0, 260, 0, 30)
    destroyBtn.Position           = UDim2.new(0.5, -130, 0, 140)
    destroyBtn.BackgroundColor3   = Color3.fromRGB(50, 0, 0)
    destroyBtn.TextColor3         = Color3.new(1, 1, 1)
    destroyBtn.Font               = Enum.Font.GothamBold
    destroyBtn.TextSize           = 16
    destroyBtn.Text               = "Destroy UI"
    destroyBtn.BackgroundTransparency = 1
    destroyBtn.TextTransparency   = 1

    local destroyCorner = Instance.new("UICorner", destroyBtn)
    destroyCorner.CornerRadius = UDim.new(0, 6)

    -- LOGIC
    local fakeLag   = false
    local delayTime = 2.0

    toggleBtn.MouseButton1Click:Connect(function()
        fakeLag = not fakeLag
        toggleBtn.Text = fakeLag and "FakeLag: ON" or "FakeLag: OFF"
        createTween(toggleBtn, {
            BackgroundTransparency = fakeLag and 0 or 1,
            BackgroundColor3       = fakeLag and Color3.fromRGB(0,150,0) or Color3.fromRGB(40,40,40)
        }, 0.3)
    end)

    delayInput.FocusLost:Connect(function()
        local v = tonumber(delayInput.Text)
        if v and v >= 0.1 and v <= 5 then
            delayTime = v
        else
            delayInput.Text = tostring(delayTime)
        end
    end)

    destroyBtn.MouseButton1Click:Connect(function()
        pulsing = false
        createTween(mainFrame, {BackgroundTransparency = 1, Size = UDim2.new(0,0,0,0)}, 0.5, Enum.EasingStyle.Back)
        task.delay(0.5, function()
            screenGui:Destroy()
        end)
    end)

    -- FakeLag coroutine
    task.spawn(function()
        while true do
            task.wait(0.05)
            if fakeLag then
                local char = player.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    local root = char.HumanoidRootPart
                    root:SetNetworkOwner(nil)
                    root.Velocity = Vector3.new(math.random(-10,10), 0, math.random(-10,10))
                    task.wait(delayTime)
                    root:SetNetworkOwner(player)
                end
            end
        end
    end)

    -- AFTER 2s → SHOW MAINFRAME
    task.delay(2, function()
        pulsing = false
        createTween(loading, {TextTransparency = 1, BackgroundTransparency = 1}, 0.4)
        task.delay(0.4, function()
            loading:Destroy()
            mainFrame.Visible = true
            mainFrame.Size               = UDim2.new(0,0,0,0)
            mainFrame.BackgroundTransparency = 1

            createTween(mainFrame, {Size = UDim2.new(0,300,0,200), BackgroundTransparency = 0}, 0.5, Enum.EasingStyle.Back)

            -- fade in children
            for _, v in ipairs(mainFrame:GetChildren()) do
                if v:IsA("TextButton") or v:IsA("TextLabel") or v:IsA("TextBox") then
                    createTween(v, {
                        TextTransparency       = 0,
                        BackgroundTransparency = 0
                    }, 0.4, Enum.EasingStyle.Quad)
                end
            end
        end)
    end)
end

createGUI()
