--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

--// FakeLag Table
local FL = {
    enabled = false,
    delay = 2,
    realChar = nil,
    ghost = nil,
    hrp = nil
}

--// Create GUI
local screenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 150)
frame.Position = UDim2.new(0.5, -125, 0.5, -75)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local uiCorner = Instance.new("UICorner", frame)
uiCorner.CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "Fake Lag Controller"
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Parent = frame

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

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 20)
status.Position = UDim2.new(0, 10, 0, 120)
status.BackgroundTransparency = 1
status.TextXAlignment = Enum.TextXAlignment.Left
status.Font = Enum.Font.Gotham
status.TextSize = 14
status.TextColor3 = Color3.fromRGB(190,190,195)
status.Text = "Status: Idle"
status.Parent = frame

--// Utility Functions
local function createGhost()
    if FL.realChar and FL.realChar.PrimaryPart then
        local ghost = FL.realChar:Clone()
        for _,desc in ipairs(ghost:GetDescendants()) do
            if desc:IsA("BasePart") then
                desc.Anchored = true
                desc.Transparency = 0.5
                desc.CanCollide = false
            elseif desc:IsA("Humanoid") then
                desc.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            end
        end
        ghost.Parent = workspace
        FL.ghost = ghost
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
            local delayText = (FL.delay == math.huge) and "∞" or string.format("%.2f", FL.delay)
            status.Text = "Status: Faking (" .. delayText .. "s)"

            -- Wait, checking every 0.05s so toggle is instant
            local startTime = tick()
            while tick() - startTime < (FL.delay == math.huge and 1e9 or FL.delay) do
                if not FL.enabled then break end
                task.wait(0.05)
            end
            if not FL.enabled then break end

            -- Snap real char to ghost
            if FL.realChar and FL.hrp and FL.ghost and FL.ghost.PrimaryPart then
                FL.hrp.Anchored = false
                FL.realChar:PivotTo(FL.ghost:GetPivot())
                RunService.Heartbeat:Wait()
                FL.hrp.Anchored = true
            end
        end
        -- Reset status on stop
        status.Text = "Status: Idle"
    end)
end

--// Button + Box Events
toggleBtn.MouseButton1Click:Connect(function()
    FL.enabled = not FL.enabled
    toggleBtn.Text = FL.enabled and "Disable Fake Lag" or "Enable Fake Lag"

    if FL.enabled then
        -- Prep vars
        FL.realChar = LocalPlayer.Character
        if FL.realChar then
            FL.hrp = FL.realChar:FindFirstChild("HumanoidRootPart")
            if FL.hrp then
                FL.hrp.Anchored = true
                createGhost()
                fakeLagLoop()
            end
        end
    else
        if FL.hrp then FL.hrp.Anchored = false end
        removeGhost()
    end
end)

delayBox.FocusLost:Connect(function(enterPressed)
    local val = tonumber(delayBox.Text)
    if val and val > 0 then
        FL.delay = val
    else
        delayBox.Text = tostring(FL.delay)
    end
end)

-- Optional: Toggle with keybind (e.g., "L")
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.L then
        toggleBtn:Activate()
    end
end)
