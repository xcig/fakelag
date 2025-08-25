-- FakeLag Control UI
-- - Clean gradient UI with glow + grow animation
-- - Draggable window (reliable after clicking gameplay)
-- - Minimize [-] to "Open FakeLag" button, Close [✕] destroys UI
-- - Delay range: 0.1..100 seconds or "inf"
-- - Cosmetic fake lag: you keep control locally; others see freezes + snaps

-- Services
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Tween helper
local function tween(obj, props, time, style, dir)
    local info = TweenInfo.new(time or 0.4, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

-- Draggable helper that keeps working after clicking outside the UI
local function makeDraggable(handle, root)
    handle.Active = true
    root.Active = true

    local dragging = false
    local dragStartPos
    local frameStartPos

    local function begin(input)
        dragging = true
        dragStartPos = input.Position
        frameStartPos = root.Position
    end

    local function update(input)
        if not dragging then return end
        local delta = input.Position - dragStartPos
        root.Position = UDim2.new(
            frameStartPos.X.Scale,
            frameStartPos.X.Offset + delta.X,
            frameStartPos.Y.Scale,
            frameStartPos.Y.Offset + delta.Y
        )
    end

    -- Start dragging
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            begin(input)
        end
    end)

    -- Track movement from handle
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            update(input)
        end
    end)

    -- Track movement globally (fixes losing focus when you click game world)
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            update(input)
        end
    end)

    -- End dragging on any global mouse/touch release
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- Local visibility utility (no TextScaled bloat)
local function setLocalVisibility(model, visible)
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") then
            d.LocalTransparencyModifier = visible and 0 or 1
        elseif d:IsA("Decal") then
            d.Transparency = visible and 0 or 1
        elseif d:IsA("ParticleEmitter") then
            d.Enabled = visible
        end
    end
end

-- Remove scripts from a cloned rig
local function stripScripts(model)
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
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 10^6
    screenGui.Parent = player:WaitForChild("PlayerGui")

    -- Minimized button
    local showBtn = Instance.new("TextButton")
    showBtn.Name = "ShowButton"
    showBtn.Size = UDim2.new(0, 150, 0, 40)
    showBtn.Position = UDim2.new(0.5, -75, 1, -56)
    showBtn.Text = "Open FakeLag"
    showBtn.AutoButtonColor = true
    showBtn.Font = Enum.Font.GothamBold
    showBtn.TextSize = 16
    showBtn.TextColor3 = Color3.new(1,1,1)
    showBtn.BackgroundColor3 = Color3.fromRGB(28,28,28)
    showBtn.Visible = false
    showBtn.Parent = screenGui
    Instance.new("UICorner", showBtn).CornerRadius = UDim.new(0, 10)

    -- Window
    local main = Instance.new("Frame")
    main.Name = "Window"
    main.Size = UDim2.new(0, 380, 0, 240)
    main.Position = UDim2.new(0.5, -190, 0.5, -120)
    main.BackgroundColor3 = Color3.fromRGB(20,20,22)
    main.BackgroundTransparency = 0.05
    main.ClipsDescendants = false
    main.Parent = screenGui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 16)

    -- Gradient + subtle glass
    local grad = Instance.new("UIGradient")
    grad.Rotation = 90
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(38,40,44)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(18,18,20)),
    })
    grad.Parent = main

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(180,180,200)
    stroke.Transparency = 0.8
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = main

    -- Glow outline
    local glow = Instance.new("ImageLabel")
    glow.BackgroundTransparency = 1
    glow.Image = "rbxassetid://4576650985"
    glow.ImageTransparency = 1
    glow.ImageColor3 = Color3.fromRGB(100,130,255)
    glow.ScaleType = Enum.ScaleType.Slice
    glow.SliceCenter = Rect.new(128,128,128,128)
    glow.Size = UDim2.new(1, 24, 1, 24)
    glow.Position = UDim2.new(0, -12, 0, -12)
    glow.ZIndex = 0
    glow.Parent = main

    -- Title bar (draggable)
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.BackgroundTransparency = 1
    titleBar.Size = UDim2.new(1, 0, 0, 44)
    titleBar.Parent = main

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Text = "FakeLag Control"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextColor3 = Color3.fromRGB(235,235,240)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Size = UDim2.new(1, -120, 1, 0)
    title.Position = UDim2.new(0, 16, 0, 0)
    title.Parent = titleBar

    -- Window controls
    local minBtn = Instance.new("TextButton")
    minBtn.Text = "–"
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 20
    minBtn.TextColor3 = Color3.new(1,1,1)
    minBtn.Size = UDim2.new(0, 36, 0, 28)
    minBtn.Position = UDim2.new(1, -92, 0, 8)
    minBtn.BackgroundColor3 = Color3.fromRGB(40,40,44)
    minBtn.AutoButtonColor = true
    minBtn.Parent = titleBar
    Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 8)

    local closeBtn = Instance.new("TextButton")
    closeBtn.Text = "✕"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 18
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.Size = UDim2.new(0, 36, 0, 28)
    closeBtn.Position = UDim2.new(1, -48, 0, 8)
    closeBtn.BackgroundColor3 = Color3.fromRGB(70,32,32)
    closeBtn.AutoButtonColor = true
    closeBtn.Parent = titleBar
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

    -- Content
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.BackgroundTransparency = 1
    content.Size = UDim2.new(1, -32, 1, -64)
    content.Position = UDim2.new(0, 16, 0, 48)
    content.Parent = main

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "Toggle"
    toggleBtn.Text = "FakeLag: OFF"
    toggleBtn.Font = Enum.Font.GothamMedium
    toggleBtn.TextSize = 18
    toggleBtn.TextColor3 = Color3.new(1,1,1)
    toggleBtn.Size = UDim2.new(1, 0, 0, 44)
    toggleBtn.Position = UDim2.new(0, 0, 0, 0)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(42,42,46)
    toggleBtn.AutoButtonColor = true
    toggleBtn.Parent = content
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 10)
    do
        local g = Instance.new("UIGradient", toggleBtn)
        g.Rotation = 90
        g.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(52,52,58)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(36,36,40))
        }
    end

    local delayBox = Instance.new("TextBox")
    delayBox.Name = "Delay"
    delayBox.PlaceholderText = "Delay (0.1–100s or inf)"
    delayBox.Text = "2.0"
    delayBox.Font = Enum.Font.Gotham
    delayBox.TextSize = 16
    delayBox.TextColor3 = Color3.new(1,1,1)
    delayBox.ClearTextOnFocus = false
    delayBox.Size = UDim2.new(0, 200, 0, 34)
    delayBox.Position = UDim2.new(0, 0, 0, 56)
    delayBox.BackgroundColor3 = Color3.fromRGB(38,38,42)
    delayBox.Parent = content
    Instance.new("UICorner", delayBox).CornerRadius = UDim.new(0, 8)

    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.BackgroundTransparency = 1
    status.Text = "Status: Idle"
    status.Font = Enum.Font.Gotham
    status.TextSize = 14
    status.TextColor3 = Color3.fromRGB(190,190,195)
    status.TextWrapped = false
    status.Size = UDim2.new(1, 0, 0, 20)
    status.Position = UDim2.new(0, 0, 0, 100)
    status.Parent = content

    -- Dragging (reliable)
    makeDraggable(titleBar, main)

    -- Fancy open animation
    main.Size = UDim2.new(0, 0, 0, 0)
    glow.ImageTransparency = 1
    tween(main, {Size = UDim2.new(0, 380, 0, 240)}, 0.5, Enum.EasingStyle.Back)
    tween(glow, {ImageTransparency = 0.75}, 0.55, Enum.EasingStyle.Quad)

    -- FakeLag state
    local FL = {
        enabled = false,
        delay = 2.0,
        ghost = nil,
        ghostHum = nil,
        realChar = nil,
        realHum = nil,
        hrp = nil,
        conns = {},
        diedConn = nil,
    }

    local function disconnectAll()
        for _, c in ipairs(FL.conns) do
            pcall(function() c:Disconnect() end)
        end
        FL.conns = {}
        if FL.diedConn then pcall(function() FL.diedConn:Disconnect() end) end
        FL.diedConn = nil
    end

    local function destroyGhost()
        if FL.ghost and FL.ghost.Parent then
            FL.ghost:Destroy()
        end
        FL.ghost, FL.ghostHum = nil, nil
    end

    local function stopFakeLag()
        FL.enabled = false
        disconnectAll()
        if FL.realChar then
            setLocalVisibility(FL.realChar, true)
        end
        if FL.hrp then
            FL.hrp.Anchored = false
        end
        if FL.realHum then
            camera.CameraSubject = FL.realHum
        end
        destroyGhost()
        toggleBtn.Text = "FakeLag: OFF"
        tween(toggleBtn, {BackgroundColor3 = Color3.fromRGB(42,42,46)}, 0.2)
        status.Text = "Status: Idle"
    end

    local function buildGhost(char)
        local clone = char:Clone()
        stripScripts(clone)
        clone.Name = "FakeLag_Ghost"
        clone.Parent = workspace
        -- Ensure physics set
        for _, d in ipairs(clone:GetDescendants()) do
            if d:IsA("BasePart") then
                d.Anchored = false
                d.Massless = false
                d.CanCollide = true
            end
        end
        clone:PivotTo(char:GetPivot())
        local hum = clone:FindFirstChildOfClass("Humanoid")
        if not hum then
            hum = Instance.new("Humanoid")
            hum.Parent = clone
        end
        hum.AutoRotate = true
        return clone, hum
    end

    local function startFakeLag()
        local char = player.Character
        if not char then status.Text = "Status: No character"; return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not (hrp and hum) then status.Text = "Status: No HRP/Humanoid"; return end

        FL.realChar, FL.hrp, FL.realHum = char, hrp, hum

        -- Freeze the real character (server sees freeze), hide it locally
        setLocalVisibility(char, false)
        hrp.Anchored = true

        -- Build local ghost and drive it with your inputs
        local ghost, ghostHum = buildGhost(char)
        FL.ghost, FL.ghostHum = ghost, ghostHum

        -- Match movement capabilities
        ghostHum.WalkSpeed = hum.WalkSpeed
        ghostHum.JumpPower = hum.JumpPower
        ghostHum.UseJumpPower = hum.UseJumpPower

        -- Camera follows ghost locally
        camera.CameraSubject = ghostHum

        -- Drive the ghost based on your real Humanoid's input state
        table.insert(FL.conns, RunService.RenderStepped:Connect(function(dt)
            if not (FL.enabled and ghostHum and hum) then return end
            ghostHum:Move(hum.MoveDirection, true)
            if hum.Jump then
                ghostHum.Jump = true
            end
        end))

        -- Periodic snap: others see you freeze and then teleport to ghost
        table.insert(FL.conns, RunService.Heartbeat:Connect(function()
            -- Keep real orientation roughly aligned to ghost for smoother snap
            if FL.hrp and ghost and ghost.PrimaryPart then
                local look = ghost.PrimaryPart.CFrame.LookVector
                local pos = FL.hrp.Position
                FL.hrp.CFrame = CFrame.new(pos, pos + look)
            end
        end))

        task.spawn(function()
            while FL.enabled do
                status.Text = (FL.delay == math.huge) and "Status: Faking (∞)" or ("Status: Faking ("..string.format("%.2fs", FL.delay)..")")
                if FL.delay == math.huge then
                    task.wait(0.25)
                else
                    task.wait(math.max(0.1, FL.delay))
                    if not (FL.enabled and FL.realChar and FL.hrp and FL.ghost) then break end
                    -- Briefly unanchor, snap to ghost, re-anchor
                    FL.hrp.Anchored = false
                    FL.realChar:PivotTo(FL.ghost:GetPivot())
                    RunService.Heartbeat:Wait()
                    FL.hrp.Anchored = true
                end
            end
        end)

        -- Safety: stop on death
        FL.diedConn = hum.Died:Connect(function()
            stopFakeLag()
            status.Text = "Status: Died"
        end)

        toggleBtn.Text = "FakeLag: ON"
        tween(toggleBtn, {BackgroundColor3 = Color3.fromRGB(0,140,0)}, 0.2)
        status.Text = "Status: Faking"
    end

    -- Interactions
    toggleBtn.MouseButton1Click:Connect(function()
        FL.enabled = not FL.enabled
        if FL.enabled then startFakeLag() else stopFakeLag() end
    end)

    delayBox.FocusLost:Connect(function()
        local txt = (delayBox.Text or ""):lower()
        if txt == "inf" or txt == "infinite" then
            FL.delay = math.huge
        else
            local v = tonumber(txt)
            if v then FL.delay = math.clamp(v, 0.1, 100) end
        end
        delayBox.Text = (FL.delay == math.huge) and "inf" or string.format("%.2f", FL.delay)
        if FL.enabled then status.Text = "Status: Faking" end
    end)

    -- Minimize [-] → to showBtn
    minBtn.MouseButton1Click:Connect(function()
        tween(glow, {ImageTransparency = 1}, 0.25)
        tween(main, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1}, 0.28, Enum.EasingStyle.Back)
        task.delay(0.3, function()
            main.Visible = false
            showBtn.Visible = true
        end)
    end)

    -- Restore from showBtn
    showBtn.MouseButton1Click:Connect(function()
        showBtn.Visible = false
        main.Visible = true
        main.Size = UDim2.new(0, 0, 0, 0)
        main.BackgroundTransparency = 1
        glow.ImageTransparency = 1
        tween(main, {Size = UDim2.new(0, 380, 0, 240), BackgroundTransparency = 0.05}, 0.45, Enum.EasingStyle.Back)
        tween(glow, {ImageTransparency = 0.75}, 0.5)
    end)

    -- Close [✕] → destroy and restore character
    closeBtn.MouseButton1Click:Connect(function()
        stopFakeLag()
        tween(glow, {ImageTransparency = 1}, 0.2)
        tween(main, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1}, 0.24, Enum.EasingStyle.Back)
        task.delay(0.26, function()
            if screenGui and screenGui.Parent then screenGui:Destroy() end
        end)
    end)
end

-- Boot UI
createGUI()
