-- Services
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player           = Players.LocalPlayer

-- Tween helper
local function tween(obj, props, time, style, dir)
    local info = TweenInfo.new(
        time  or 0.4,
        style or Enum.EasingStyle.Quint,
        dir   or Enum.EasingDirection.Out
    )
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

-- Build GUI
local function createGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name           = "FakeLagUI"
    screenGui.Parent         = player:WaitForChild("PlayerGui")
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn   = false

    -- “Open” button
    local showBtn = Instance.new("TextButton", screenGui)
    showBtn.Name             = "ShowButton"
    showBtn.Size             = UDim2.new(0,100,0,40)
    showBtn.Position         = UDim2.new(0.5,-50,1,-60)
    showBtn.Text             = "Open FakeLag"
    showBtn.Font             = Enum.Font.GothamBold
    showBtn.TextSize         = 16
    showBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
    showBtn.TextColor3       = Color3.new(1,1,1)
    showBtn.Visible          = false
    local showCorner = Instance.new("UICorner", showBtn)
    showCorner.CornerRadius = UDim.new(0,8)

    -- Main window
    local mainFrame = Instance.new("Frame", screenGui)
    mainFrame.Name               = "MainFrame"
    mainFrame.Size               = UDim2.new(0,320,0,220)
    mainFrame.Position           = UDim2.new(0.5,-160,0.5,-110)
    mainFrame.BackgroundColor3   = Color3.fromRGB(25,25,25)
    mainFrame.BackgroundTransparency = 1
    mainFrame.Active            = true  -- enable input capture
    mainFrame.ZIndex            = 1
    local frameCorner = Instance.new("UICorner", mainFrame)
    frameCorner.CornerRadius = UDim.new(0,12)

    -- Drop shadow
    local shadow = Instance.new("ImageLabel", mainFrame)
    shadow.Name               = "Shadow"
    shadow.Image              = "rbxassetid://1316045217"
    shadow.BackgroundTransparency = 1
    shadow.ImageTransparency      = 0.5
    shadow.ZIndex             = 0
    shadow.Size               = UDim2.new(1,20,1,20)
    shadow.Position           = UDim2.new(0,-10,0,-10)

    -- Title bar (draggable region)
    local titleBar = Instance.new("Frame", mainFrame)
    titleBar.Name               = "TitleBar"
    titleBar.Size               = UDim2.new(1,0,0,36)
    titleBar.Position           = UDim2.new(0,0,0,0)
    titleBar.BackgroundTransparency = 1
    titleBar.Active            = true  -- now it can capture input
    titleBar.ZIndex            = 2

    local titleLabel = Instance.new("TextLabel", titleBar)
    titleLabel.Size               = UDim2.new(1,-60,1,0)
    titleLabel.Position           = UDim2.new(0,12,0,0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text               = "FakeLag Control"
    titleLabel.TextColor3         = Color3.new(1,1,1)
    titleLabel.Font               = Enum.Font.GothamBold
    titleLabel.TextSize           = 18
    titleLabel.TextXAlignment     = Enum.TextXAlignment.Left

    local closeBtn = Instance.new("TextButton", titleBar)
    closeBtn.Name             = "CloseBtn"
    closeBtn.Size             = UDim2.new(0,40,0,24)
    closeBtn.Position         = UDim2.new(1,-48,0,6)
    closeBtn.Text             = "✕"
    closeBtn.Font             = Enum.Font.GothamBold
    closeBtn.TextSize         = 18
    closeBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    closeBtn.TextColor3       = Color3.new(1,1,1)
    closeBtn.ZIndex           = 2
    local closeCorner = Instance.new("UICorner", closeBtn)
    closeCorner.CornerRadius = UDim.new(0,6)

    -- Toggle button
    local toggleBtn = Instance.new("TextButton", mainFrame)
    toggleBtn.Name             = "ToggleBtn"
    toggleBtn.Size             = UDim2.new(0,280,0,40)
    toggleBtn.Position         = UDim2.new(0.5,-140,0,50)
    toggleBtn.Text             = "FakeLag: OFF"
    toggleBtn.Font             = Enum.Font.Gotham
    toggleBtn.TextSize         = 18
    toggleBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    toggleBtn.TextColor3       = Color3.new(1,1,1)
    local tCorner = Instance.new("UICorner", toggleBtn)
    tCorner.CornerRadius = UDim.new(0,8)

    -- Delay input
    local delayBox = Instance.new("TextBox", mainFrame)
    delayBox.Name               = "DelayBox"
    delayBox.Size               = UDim2.new(0,160,0,28)
    delayBox.Position           = UDim2.new(0.5,-80,0,110)
    delayBox.PlaceholderText    = "Delay (0.1–100s or inf)"
    delayBox.Text               = "2.0"
    delayBox.Font               = Enum.Font.Gotham
    delayBox.TextSize           = 16
    delayBox.BackgroundColor3   = Color3.fromRGB(35,35,35)
    delayBox.TextColor3         = Color3.new(1,1,1)
    delayBox.ClearTextOnFocus   = false
    local dCorner = Instance.new("UICorner", delayBox)
    dCorner.CornerRadius = UDim.new(0,6)

    -- Logic vars
    local fakeLag   = false
    local delayTime = 2.0

    -- Toggle click
    toggleBtn.MouseButton1Click:Connect(function()
        fakeLag = not fakeLag
        toggleBtn.Text = fakeLag and "FakeLag: ON" or "FakeLag: OFF"
        tween(toggleBtn, {
            BackgroundColor3 = fakeLag
                and Color3.fromRGB(0,150,0)
                or Color3.fromRGB(40,40,40)
        }, 0.3)
    end)

    -- Validate delay input
    delayBox.FocusLost:Connect(function()
        local txt = delayBox.Text:lower()
        if txt == "inf" then
            delayTime = math.huge
        else
            local v = tonumber(txt)
            if v and v >= 0.1 then
                delayTime = math.min(v, 100)
            end
        end
        delayBox.Text = (delayTime == math.huge)
            and "inf"
            or tostring(delayTime)
    end)

    -- Close → collapse
    closeBtn.MouseButton1Click:Connect(function()
        tween(mainFrame, {
            Size = UDim2.new(0,0,0,0),
            BackgroundTransparency = 1
        }, 0.4, Enum.EasingStyle.Back)
        task.delay(0.4, function()
            mainFrame.Visible = false
            showBtn.Visible  = true
        end)
    end)

    -- Show → expand
    showBtn.MouseButton1Click:Connect(function()
        showBtn.Visible   = false
        mainFrame.Visible = true
        mainFrame.Size    = UDim2.new(0,0,0,0)
        mainFrame.BackgroundTransparency = 1
        tween(mainFrame, {
            Size = UDim2.new(0,320,0,220),
            BackgroundTransparency = 0
        }, 0.5, Enum.EasingStyle.Back)
    end)

    -- Drag logic (works on TitleBar and MainFrame)
    do
        local dragging, dragInput, dragStart, startPos

        local function startDrag(input)
            dragging  = true
            dragStart = input.Position
            startPos  = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end

        local function updateDrag(input)
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end

        for _, region in ipairs({titleBar, mainFrame}) do
            region.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    startDrag(input)
                end
            end)
            region.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement then
                    dragInput = input
                end
            end)
        end

        UserInputService.InputChanged:Connect(function(input)
            if dragging and input == dragInput then
                updateDrag(input)
            end
        end)
    end

    -- Cosmetic FakeLag via NetworkOwnership
    task.spawn(function()
        while true do
            task.wait(0.05)
            if fakeLag and player.Character then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp:SetNetworkOwner(nil)
                    task.wait(delayTime)
                    hrp:SetNetworkOwner(player)
                end
            end
        end
    end)

    -- Animate entrance
    mainFrame.Size               = UDim2.new(0,0,0,0)
    mainFrame.BackgroundTransparency = 1
    tween(mainFrame, {
        Size = UDim2.new(0,320,0,220),
        BackgroundTransparency = 0
    }, 0.5, Enum.EasingStyle.Back)
end

createGUI()
