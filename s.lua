--[[ 
    FakeLag Control UI (draggable, minimize, close) + working cosmetic fake lag
    - Apple-style gradient + grow animation with outline glow
    - Drag anywhere on the title bar
    - [-] minimize to "Open FakeLag" button at bottom center
    - [×] completely destroys UI and restores character
    - Delay: 0.1 to 100 or "inf"
    - Cosmetic fake lag: you keep smooth local control via a client-side ghost rig; 
      other players see you freeze then snap to your new position at the chosen interval.
]]

-- Services
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")

local player            = Players.LocalPlayer
local cam               = workspace.CurrentCamera

-- Tween helper
local function tween(obj, props, time, style, dir)
    local info = TweenInfo.new(time or 0.4, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

-- Draggable helper (title-bar)
local function makeDraggable(handle, root)
    handle.Active = true
    root.Active = true
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        root.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = root.Position
            root.ZIndex = (root.ZIndex or 1) + 1
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            update(input)
        end
    end)
end

-- Character visual helpers
local function setLocalVisibility(model, visible)
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") then
            d.LocalTransparencyModifier = visible and 0 or 1
        elseif d:IsA("Decal") then
            d.Transparency = visible and 0 or 1
        end
    end
end

local function safeClearScripts(model)
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("Script") or d:IsA("LocalScript") then
            d:Destroy()
        end
    end
end

-- Build UI
local function createGUI()
    -- ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FakeLagUI"
    screenGui.Parent = player:WaitForChild("PlayerGui")
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 9999

    -- Minimized button
    local showBtn = Instance.new("TextButton")
    showBtn.Name = "ShowButton"
    showBtn.Size = UDim2.new(0, 140, 0, 40)
    showBtn.Position = UDim2.new(0.5, -70, 1, -60)
    showBtn.Text = "Open FakeLag"
    showBtn.Font = Enum.Font.GothamBold
    showBtn.TextSize = 16
    showBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    showBtn.TextColor3 = Color3.new(1,1,1)
    showBtn.Visible = false
    showBtn.Parent = screenGui
    Instance.new("UICorner", showBtn).CornerRadius = UDim.new(0, 10)

    -- Window
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 360, 0, 240)
    main.Position = UDim2.new(0.5, -180, 0.5, -120)
    main.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
    main.BackgroundTransparency = 0.05
    main.Parent = screenGui
    main.ZIndex = 10
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 16)

    -- Gradient background
    local bgGrad = Instance.new("UIGradient")
    bgGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, Color3.fromRGB(28,28,28)),
        ColorSequenceKeypoint.new(1.0, Color3.fromRGB(18,18,18)),
    })
    bgGrad.Rotation = 90
    bgGrad.Parent = main

    -- Glow outline (subtle)
    local outline = Instance.new("Frame")
    outline.Name = "Outline"
    outline.BackgroundTransparency = 1
    outline.Size = UDim2.new(1, 8, 1, 8)
    outline.Position = UDim2.new(0, -4, 0, -4)
    outline.Parent = main
    outline.ZIndex = 9

    local outlineImg = Instance.new("ImageLabel")
    outlineImg.Size = UDim2.new(1, 0, 1, 0)
    outlineImg.BackgroundTransparency = 1
    outlineImg.Image = "rbxassetid://4576650985" -- soft glow
    outlineImg.ImageColor3 = Color3.fromRGB(120,120,255)
    outlineImg.ImageTransparency = 0.7
    outlineImg.Parent = outline
    outlineImg.ScaleType = Enum.ScaleType.Slice
    outlineImg.SliceCenter = Rect.new(128,128,128,128)

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 44)
    titleBar.BackgroundTransparency = 1
    titleBar.Parent = main
    titleBar.ZIndex = 11

    local title = Instance.new("TextLabel")
    title.Text = "FakeLag Control"
    title.Size = UDim2.new(1, -120, 1, 0)
    title.Position = UDim2.new(0, 16, 0, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextColor3 = Color3.fromRGB(240,240,240)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 12
    title.Parent = titleBar

    -- Buttons (minimize, close)
    local minBtn = Instance.new("TextButton")
    minBtn.Text = "–"
    minBtn.Size = UDim2.new(0, 36, 0, 28)
    minBtn.Position = UDim2.new(1, -92, 0, 8)
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 20
    minBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    minBtn.TextColor3 = Color3.new(1,1,1)
    minBtn.ZIndex = 12
    minBtn.Parent = titleBar
    Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 8)

    local closeBtn = Instance.new("TextButton")
    closeBtn.Text = "✕"
    closeBtn.Size = UDim2.new(0, 36, 0, 28)
    closeBtn.Position = UDim2.new(1, -48, 0, 8)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 18
    closeBtn.BackgroundColor3 = Color3.fromRGB(58,26,26)
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.ZIndex = 12
    closeBtn.Parent = titleBar
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

    -- Content container
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -32, 1, -64)
    content.Position = UDim2.new(0, 16, 0, 48)
    content.BackgroundTransparency = 1
    content.ZIndex = 11
    content.Parent = main

    -- Toggle
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "ToggleBtn"
    toggleBtn.Text = "FakeLag: OFF"
    toggleBtn.Size = UDim2.new(1, 0, 0, 42)
    toggleBtn.Position = UDim2.new(0, 0, 0, 0)
    toggleBtn.Font = Enum.Font.GothamSemibold
    toggleBtn.TextSize = 18
    toggleBtn.BackgroundColor3 = Color3.fromRGB(38,38,38)
    toggleBtn.TextColor3 = Color3.new(1,1,1)
    toggleBtn.ZIndex = 12
    toggleBtn.Parent = content
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 10)

    local toggleGrad = Instance.new("UIGradient", toggleBtn)
    toggleGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(50,50,50)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(34,34,34))
    }
    toggleGrad.Rotation = 90

    -- Delay input
    local delayBox = Instance.new("TextBox")
    delayBox.Name = "DelayBox"
    delayBox.PlaceholderText = "Delay (0.1–100s or inf)"
    delayBox.Text = "2.0"
    delayBox.Size = UDim2.new(0, 200, 0, 34)
    delayBox.Position = UDim2.new(0, 0, 0, 56)
    delayBox.Font = Enum.Font.Gotham
    delayBox.TextSize = 16
    delayBox.BackgroundColor3 = Color3.fromRGB(36,36,36)
    delayBox.TextColor3 = Color3.new(1,1,1)
    delayBox.ClearTextOnFocus = false
    delayBox.ZIndex = 12
    delayBox.Parent = content
    Instance.new("UICorner", delayBox).CornerRadius = UDim.new(0, 8)

    local delayGrad = Instance.new("UIGradient", delayBox)
    delayGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(42,42,42)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(30,30,30))
    }
    delayGrad.Rotation = 90

    -- Status label
    local status = Instance.new("TextLabel")
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.Gotham
    status.TextSize = 14
    status.TextColor3 = Color3.fromRGB(190,190,190)
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Size = UDim2.new(1, 0, 0, 20)
    status.Position = UDim2.new(0, 0, 0, 100)
    status.Text = "Status: Idle"
    status.ZIndex = 12
    status.Parent = content

    -- Make draggable
    makeDraggable(titleBar, main)

    -- Grow + outline pulse on open
    main.Size = UDim2.new(0, 0, 0, 0)
    outlineImg.ImageTransparency = 1
    tween(main, {Size = UDim2.new(0, 360, 0, 240)}, 0.5, Enum.EasingStyle.Back)
    tween(outlineImg, {ImageTransparency = 0.7}, 0.6, Enum.EasingStyle.Quad)

    -- Logic state
    local fakeLagEnabled = false
    local delayTime = 2.0
    local ghost -- client-only dummy
    local ghostHum
    local ghostConn = {}
    local catchupConn
    local diedConn

    local function cleanupGhost()
        for _, c in ipairs(ghostConn) do
            pcall(function() c:Disconnect() end)
        end
        ghostConn = {}
        if catchupConn then pcall(function() catchupConn:Disconnect() end) end
        catchupConn = nil
        if ghost and ghost.Parent then ghost:Destroy() end
        ghost, ghostHum = nil, nil

        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            hrp.Anchored = false
            setLocalVisibility(char, true)
            if char:FindFirstChildOfClass("Humanoid") then
                cam.CameraSubject = char:FindFirstChildOfClass("Humanoid")
            end
        end
    end

    local function buildGhostFromCharacter(char)
        -- Clone current character locally
        local clone = char:Clone()
        safeClearScripts(clone)
        clone.Name = "FakeLag_Ghost"
        clone.Parent = workspace

        -- Make sure parts behave locally and don’t interfere on server
        for _, d in ipairs(clone:GetDescendants()) do
            if d:IsA("BasePart") then
                d.Anchored = false
                d.Massless = false
                d.CanCollide = true
            end
        end

        -- Ensure humanoid exists
        local hum = clone:FindFirstChildOfClass("Humanoid")
        if not hum then
            hum = Instance.new("Humanoid")
            hum.Parent = clone
        end
        hum.AutoRotate = true

        -- Put ghost where the real character is
        local pivot = char:GetPivot()
        clone:PivotTo(pivot)

        return clone, hum
    end

    local function startFakeLag()
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            status.Text = "Status: No character"
            return
        end
        if ghost then cleanupGhost() end

        -- Hide real char locally and freeze it for others
        setLocalVisibility(char, false)
        local hrp = char.HumanoidRootPart
        hrp.Anchored = true

        -- Build ghost and route camera to it
        ghost, ghostHum = buildGhostFromCharacter(char)
        cam.CameraSubject = ghostHum

        -- Mirror movement from real humanoid to ghost humanoid
        local realHum = char:FindFirstChildOfClass("Humanoid")
        if realHum then
            ghostHum.WalkSpeed = realHum.WalkSpeed
            ghostHum.JumpPower = realHum.JumpPower
            ghostHum.UseJumpPower = realHum.UseJumpPower
        end

        ghostConn[#ghostConn+1] = RunService.RenderStepped:Connect(function()
            if not realHum or not ghostHum then return end
            -- Feed ghost the player's current input via real MoveDirection/Jump
            ghostHum:Move(realHum.MoveDirection, true)
            if realHum.Jump then
                ghostHum.Jump = true
            end
        end)

        -- Catch-up teleports (stutter visible to others)
        ghostConn[#ghostConn+1] = RunService.Heartbeat:Connect(function() -- keep HRP orientation aligned
            if ghost and ghost.PrimaryPart and hrp then
                -- Keep real orientation mirrored to avoid spin
                hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + ghost.PrimaryPart.CFrame.LookVector)
            end
        end)

        -- Periodic snap
        task.spawn(function()
            while fakeLagEnabled and ghost and ghost.PrimaryPart and hrp do
                status.Text = ("Status: Faking (%.2fs)"):format(delayTime == math.huge and 9e9 or delayTime)
                if delayTime == math.huge then
                    task.wait(0.5)
                else
                    task.wait(math.max(0.1, delayTime))
                    -- Snap real character to ghost, then re-freeze
                    hrp.Anchored = false
                    char:PivotTo(ghost:GetPivot())
                    RunService.Heartbeat:Wait()
                    hrp.Anchored = true
                end
            end
        end)

        -- Handle death/respawn
        local hum = realHum
        if hum then
            diedConn = hum.Died:Connect(function()
                fakeLagEnabled = false
                cleanupGhost()
                status.Text = "Status: Died"
            end)
        end

        toggleBtn.Text = "FakeLag: ON"
        tween(toggleBtn, {BackgroundColor3 = Color3.fromRGB(0,140,0)}, 0.25)
        status.Text = "Status: Faking"
    end

    local function stopFakeLag()
        fakeLagEnabled = false
        if diedConn then pcall(function() diedConn:Disconnect() end) end
        diedConn = nil
        cleanupGhost()
        toggleBtn.Text = "FakeLag: OFF"
        tween(toggleBtn, {BackgroundColor3 = Color3.fromRGB(38,38,38)}, 0.25)
        status.Text = "Status: Idle"
    end

    -- Interactions
    toggleBtn.MouseButton1Click:Connect(function()
        fakeLagEnabled = not fakeLagEnabled
        if fakeLagEnabled then startFakeLag() else stopFakeLag() end
    end)

    delayBox.FocusLost:Connect(function()
        local txt = (delayBox.Text or ""):lower()
        if txt == "inf" or txt == "infinite" then
            delayTime = math.huge
        else
            local v = tonumber(txt)
            if v then
                v = math.clamp(v, 0.1, 100)
                delayTime = v
            end
        end
        delayBox.Text = (delayTime == math.huge) and "inf" or string.format("%.2f", delayTime)
        if fakeLagEnabled then
            status.Text = "Status: Faking"
        end
    end)

    -- Minimize
    minBtn.MouseButton1Click:Connect(function()
        tween(main, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1}, 0.35, Enum.EasingStyle.Back)
        tween(outlineImg, {ImageTransparency = 1}, 0.35)
        task.delay(0.36, function()
            main.Visible = false
            showBtn.Visible = true
        end)
    end)

    -- Restore
    showBtn.MouseButton1Click:Connect(function()
        showBtn.Visible = false
        main.Visible = true
        main.Size = UDim2.new(0, 0, 0, 0)
        main.BackgroundTransparency = 1
        outlineImg.ImageTransparency = 1
        tween(main, {Size = UDim2.new(0, 360, 0, 240), BackgroundTransparency = 0.05}, 0.5, Enum.EasingStyle.Back)
        tween(outlineImg, {ImageTransparency = 0.7}, 0.5)
    end)

    -- Close (destroy everything and restore char)
    closeBtn.MouseButton1Click:Connect(function()
        stopFakeLag()
        tween(main, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1}, 0.3, Enum.EasingStyle.Back)
        tween(outlineImg, {ImageTransparency = 1}, 0.3)
        task.delay(0.32, function()
            if screenGui then screenGui:Destroy() end
        end)
    end)
end

-- Boot
createGUI()
