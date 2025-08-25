--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

--// FakeLag Table
local FL = {
    enabled = false,
    delay = 2,
    realChar = nil,
    ghost = nil,
    hrp = nil,
    defaultSpeed = nil
}

--// Create GUI
local screenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 150)
frame.Position = UDim2.new(0.5, -125, 0.5, -75)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.Parent = frame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,5)
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    FL.enabled = false
end)

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 0, 30)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Fake Lag Controller"
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextColor3 = Color3.fromRGB(255,255,255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

-- Toggle Button
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1, -20, 0, 30)
toggleBtn.Position = UDim2.new(0, 10, 0, 40)
toggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
toggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
toggleBtn.Font = Enum.Font.Gotham
toggleBtn.TextSize = 14
toggleBtn.Text = "Enable Fake Lag"
toggleBtn.Parent = frame
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0,5)

-- Delay Box
local delayBox = Instance.new("TextBox")
delayBox.Size = UDim2.new(1, -20, 0, 30)
delayBox.Position = UDim2.new(0, 10, 0, 80)
delayBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
delayBox.PlaceholderText = "Delay (seconds)"
delayBox.TextColor3 = Color3.fromRGB(255,255,255)
delayBox.Font = Enum.Font.Gotham
delayBox.TextSize = 14
delayBox.Text = tostring(FL.delay)
delayBox.Parent = frame
Instance.new("UICorner", delayBox).CornerRadius = UDim.new(0,5)

-- Status (only visible when active)
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 20)
status.Position = UDim2.new(0, 10, 0, 120)
status.BackgroundTransparency = 1
status.TextXAlignment = Enum.TextXAlignment.Left
status.Font = Enum.Font.Gotham
status.TextSize = 14
status.TextColor3 = Color3.fromRGB(190,190,195)
status.Visible = false
status.Parent = frame

--// Utility Functions
local function createGhost()
    if FL.realChar and FL.realChar.PrimaryPart then
        local success, ghost = pcall(function()
            return FL.realChar:Clone()
        end)
        if success and ghost then
            if typeof(ghost.GetDescendants) == "function" then
                for _,desc in ipairs(ghost:GetDescendants()) do
                    if desc:IsA("BasePart") then
                        desc.Anchored = true
                        desc.Transparency = 0.5
                        desc.CanCollide = false
                    elseif desc:IsA("Humanoid") then
                        desc.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                    end
                end
            end
            ghost.Parent = workspace
            FL.ghost = ghost
        end
    end
end

local function removeGhost()
    if FL.ghost then
        FL.ghost:Destroy()
        FL.ghost = nil
    end
end

local function fakeLagLoop()
    task.spawn(function()
        while FL.enabled do
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not char or not hum or not hrp then
                task.wait(0.05)
                continue
            end

            -- LAG PHASE: freeze for 0.5 seconds
            hrp.Anchored = true
            hum.PlatformStand = false
            task.wait(0.5)

            -- MOVE PHASE: unfreeze for (delay - 0.5) seconds
            hrp.Anchored = false
            hum.WalkSpeed = FL.defaultSpeed or hum.WalkSpeed
            local freeTime = math.max(FL.delay - 0.5, 0)
            local start = tick()
            while FL.enabled and (tick() - start < freeTime) do
                task.wait(0.05)
            end
        end

        -- clean reset
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hum and FL.defaultSpeed then hum.WalkSpeed = FL.defaultSpeed end
        if hrp then hrp.Anchored = false end
        status.Visible = false
    end)
end

--// Events
toggleBtn.MouseButton1Click:Connect(function()
    FL.enabled = not FL.enabled
    toggleBtn.Text = FL.enabled and "Disable Fake Lag" or "Enable Fake Lag"

    if FL.enabled then
        FL.realChar = LocalPlayer.Character
        if FL.realChar then
            local hum = FL.realChar:FindFirstChildOfClass("Humanoid")
            FL.hrp = FL.realChar:FindFirstChild("HumanoidRootPart")
            if hum then
                FL.defaultSpeed = hum.WalkSpeed
            end
            if FL.hrp then
                createGhost()
                fakeLagLoop()
            end
        end
    else
        if FL.hrp then FL.hrp.Anchored = false end
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and FL.defaultSpeed then hum.WalkSpeed = FL.defaultSpeed end
        removeGhost()
    end
end)

delayBox.FocusLost:Connect(function()
    local val = tonumber(delayBox.Text)
    if val and val > 0 then
        FL.delay = val
    else
        delayBox.Text = tostring(FL.delay)
    end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.L then
        toggleBtn:Activate()
    end
end)
