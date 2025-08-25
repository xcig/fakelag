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

            -- LAG PHASE
            hrp.Anchored = true
            hum.PlatformStand = false -- keep animations alive but movement blocked
            task.wait(0.5) -- freeze

            -- MOVE PHASE + Speed stutter
            hrp.Anchored = false
            -- quick speed pattern to mimic jitter
            hum.WalkSpeed = 22
            task.wait(0.27)
            hum.WalkSpeed = 18
            task.wait(0.15)
            hum.WalkSpeed = 20

            -- let them move for rest of cycle
            local freeTime = math.max(FL.delay - 0.5, 0)
            local start = tick()
            while tick() - start < freeTime do
                if not FL.enabled then break end
                task.wait(0.05)
            end
        end

        -- clean reset
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hum then hum.WalkSpeed = 16 end -- or your default walk speed
        if hrp then hrp.Anchored = false end
        status.Visible = false
    end)
end
