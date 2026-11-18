-- COASTAL PROSPECTING SAFE AUTO FARM
-- Known-working baseline: the version confirmed working before turbo/UI rewrites.
-- Does NOT call ToggleShovelActive.
-- STOP and CLOSE never send shovel commands.
-- Uses Collect(1), Pan(), Shake() and pan.Fill.
-- Includes TEST DIG, draggable UI and full cleanup.

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local env = getgenv()

if env.CoastalSafeFarm and env.CoastalSafeFarm.Close then
    pcall(function()
        env.CoastalSafeFarm:Close()
    end)
end

local CONFIG = {
    CollectDelay = 0.12,
    ShakeDelay = 0.14,
    PanRetryDelay = 0.20,
    RewardGap = 0.55,
    TeleportDelay = 0.22,
    RemoteTimeout = 3,
    MaxCollect = 180,
    MaxShakes = 80,
    MaxPanRetries = 12,
    MaxStalledDigs = 15
}

local state = {
    alive = true,
    running = false,
    revision = 0,
    cycles = 0,
    phase = "Idle",
    digPosition = nil,
    waterPosition = nil,
    rewards = 0,
    lastReward = 0,
    completed = false,
    connections = {},
    completionConnection = nil
}

env.CoastalSafeFarm = state

local function active(id)
    return state.alive
        and state.running
        and state.revision == id
end

local function connect(signal, callback)
    local c = signal:Connect(callback)
    table.insert(state.connections, c)
    return c
end

local function getRoot()
    local character = player.Character
    return character
        and character:FindFirstChild("HumanoidRootPart")
end

local function findPan()
    local character = player.Character

    if not character then
        return nil, "Character missing"
    end

    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") then
            local scripts = tool:FindFirstChild("Scripts")

            if scripts then
                local collect = scripts:FindFirstChild("Collect")
                local pan = scripts:FindFirstChild("Pan")
                local shake = scripts:FindFirstChild("Shake")

                if collect and pan and shake
                    and collect:IsA("RemoteFunction")
                    and pan:IsA("RemoteFunction")
                    and shake:IsA("RemoteEvent") then

                    return {
                        Tool = tool,
                        Collect = collect,
                        Pan = pan,
                        Shake = shake,
                        Complete = scripts:FindFirstChild("PanningComplete")
                    }
                end
            end
        end
    end

    return nil, "Equip your pan first"
end

local function getFill(remotes)
    local fill = remotes.Tool:GetAttribute("Fill")
    return tonumber(fill)
end

local function getCapacity()
    local stats = player:FindFirstChild("Stats")

    if stats then
        local value = stats:GetAttribute("Capacity")

        if type(value) == "number" then
            return value
        end
    end

    return 1338
end

-- ========== UI ==========

local gui = Instance.new("ScreenGui")
gui.Name = "CoastalSafeProspecting"
gui.ResetOnSpawn = false
gui.DisplayOrder = 9999

local guiParent = player:WaitForChild("PlayerGui")

if type(gethui) == "function" then
    local ok, result = pcall(gethui)

    if ok and result then
        guiParent = result
    end
end

gui.Parent = guiParent

local function make(class, props, parent)
    local obj = Instance.new(class)

    for key, value in pairs(props) do
        obj[key] = value
    end

    obj.Parent = parent
    return obj
end

local function corner(obj)
    make("UICorner", {
        CornerRadius = UDim.new(0, 9)
    }, obj)
end

local main = make("Frame", {
    Size = UDim2.fromOffset(360, 345),
    Position = UDim2.new(0.5, -180, 0.5, -172),
    BackgroundColor3 = Color3.fromRGB(24, 27, 36),
    BorderSizePixel = 0,
    Active = true
}, gui)

corner(main)

make("UIStroke", {
    Color = Color3.fromRGB(72, 80, 102),
    Thickness = 1
}, main)

local header = make("Frame", {
    Size = UDim2.new(1, 0, 0, 44),
    BackgroundColor3 = Color3.fromRGB(38, 43, 57),
    BorderSizePixel = 0,
    Active = true
}, main)

corner(header)

make("TextLabel", {
    Size = UDim2.fromOffset(246, 44),
    Position = UDim2.fromOffset(12, 0),
    BackgroundTransparency = 1,
    Text = "COASTAL | SAFE AUTO FARM",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 13,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, header)

local function button(text, x, y, w, h, color, parent)
    local b = make("TextButton", {
        Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(w, h),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = true
    }, parent or main)

    corner(b)
    return b
end

local closeButton = button(
    "X", 321, 7, 31, 30,
    Color3.fromRGB(184, 61, 69), header
)

local minimizeButton = button(
    "_", 286, 7, 31, 30,
    Color3.fromRGB(84, 94, 114), header
)

local body = make("Frame", {
    Position = UDim2.fromOffset(0, 45),
    Size = UDim2.new(1, 0, 1, -45),
    BackgroundTransparency = 1
}, main)

local statusLabel = make("TextLabel", {
    Position = UDim2.fromOffset(14, 10),
    Size = UDim2.fromOffset(332, 42),
    BackgroundTransparency = 1,
    Text = "Status: Idle",
    TextColor3 = Color3.fromRGB(154, 204, 255),
    Font = Enum.Font.GothamMedium,
    TextSize = 12,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left
}, body)

local progressLabel = make("TextLabel", {
    Position = UDim2.fromOffset(14, 52),
    Size = UDim2.fromOffset(332, 23),
    BackgroundTransparency = 1,
    Text = "Cycles: 0 | Fill: --",
    TextColor3 = Color3.fromRGB(206, 214, 233),
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left
}, body)

local digButton = button(
    "SAVE DIG", 14, 83, 158, 39,
    Color3.fromRGB(73, 106, 185), body
)

local waterButton = button(
    "SAVE WATER", 188, 83, 158, 39,
    Color3.fromRGB(43, 132, 187), body
)

local testButton = button(
    "TEST DIG (1 CALL)", 14, 132, 332, 37,
    Color3.fromRGB(91, 80, 148), body
)

local capLabel = make("TextLabel", {
    Position = UDim2.fromOffset(14, 179),
    Size = UDim2.fromOffset(152, 30),
    BackgroundTransparency = 1,
    Text = "Target Fill / Capacity:",
    TextColor3 = Color3.fromRGB(215, 220, 235),
    TextSize = 11,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left
}, body)

local capBox = make("TextBox", {
    Position = UDim2.fromOffset(188, 180),
    Size = UDim2.fromOffset(158, 29),
    BackgroundColor3 = Color3.fromRGB(48, 55, 75),
    Text = tostring(getCapacity()),
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 13,
    Font = Enum.Font.Gotham,
    ClearTextOnFocus = false,
    BorderSizePixel = 0
}, body)

corner(capBox)

local startButton = button(
    "START", 14, 221, 158, 42,
    Color3.fromRGB(37, 149, 95), body
)

local stopButton = button(
    "STOP", 188, 221, 158, 42,
    Color3.fromRGB(187, 67, 74), body
)

make("TextLabel", {
    Position = UDim2.fromOffset(10, 268),
    Size = UDim2.fromOffset(340, 27),
    BackgroundTransparency = 1,
    Text = "X = full cleanup | No shovel toggles",
    TextColor3 = Color3.fromRGB(144, 154, 176),
    Font = Enum.Font.Gotham,
    TextSize = 11
}, body)

local function status(message)
    if not state.alive then return end

    state.phase = message
    statusLabel.Text = "Status: " .. message
    print("[COASTAL]", message)
end

local function updateProgress(fill, capacity)
    if not state.alive then return end

    progressLabel.Text = string.format(
        "Cycles: %d | Fill: %s / %s",
        state.cycles,
        fill and string.format("%.1f", fill) or "--",
        capacity and tostring(capacity) or "--"
    )
end

local function waitActive(seconds, id)
    local deadline = os.clock() + seconds

    while os.clock() < deadline do
        if not active(id) then return false end
        task.wait(0.025)
    end

    return active(id)
end

local function invoke(remote, id, ...)
    if not active(id) then return false, nil, "Stopped" end
    local args = table.pack(...)
    local finished, succeeded, response = false, false, nil

    task.spawn(function()
        if not active(id) then finished = true; return end

        succeeded, response = pcall(function()
            return remote:InvokeServer(
                table.unpack(args, 1, args.n)
            )
        end)
        finished = true
    end)

    local deadline = os.clock() + CONFIG.RemoteTimeout

    while not finished and os.clock() < deadline do
        if not active(id) then return false, nil, "Stopped" end
        task.wait(0.02)
    end

    if not finished then return false, nil, "Remote timeout" end
    if not succeeded then return false, nil, tostring(response) end
    return true, response
end

local function teleport(position, id)
    if not position then return false end

    for attempt = 1, 2 do
        if not active(id) then return false end
        local root = getRoot()
        if not root then return false end

        local ok = pcall(function() root.CFrame = position end)
        if not ok then return false end
        if not waitActive(CONFIG.TeleportDelay, id) then return false end

        root = getRoot()
        if root and (root.Position - position.Position).Magnitude < 10 then
            return true
        end
    end
    return false
end

local function stopFarm(message)
    if not state.alive then return end
    state.running = false
    state.revision = state.revision + 1

    if state.completionConnection then
        state.completionConnection:Disconnect()
        state.completionConnection = nil
    end

    status(message or "Stopped")
end

local function dig(remotes, id, capacity)
    status("Moving to sand")
    if not teleport(state.digPosition, id) then
        return false, "Dig teleport failed"
    end

    local fill = getFill(remotes)
    if fill == nil then return false, "Pan Fill attribute missing" end
    local stalled = 0
    status("Digging with Collect(1)")

    for attempt = 1, CONFIG.MaxCollect do
        if not active(id) then return false, "Stopped" end
        fill = getFill(remotes)
        if fill and fill >= capacity - 0.01 then
            updateProgress(fill, capacity)
            return true
        end

        local before = fill or 0
        local ok, response, err = invoke(remotes.Collect, id, 1)
        if not ok then return false, err or "Collect failed" end
        if not waitActive(CONFIG.CollectDelay, id) then
            return false, "Stopped"
        end

        fill = getFill(remotes)
        updateProgress(fill, capacity)

        if fill and fill > before + 0.001 then
            stalled = 0
        else
            stalled = stalled + 1
        end

        if stalled >= CONFIG.MaxStalledDigs then
            return false, "Fill not increasing. Activate shovel manually."
        end
    end

    return false, "Dig limit reached before pan was full"
end

local function wash(remotes, id, capacity)
    status("Moving to water")
    if not teleport(state.waterPosition, id) then
        return false, "Water teleport failed"
    end

    state.rewards = 0
    state.lastReward = 0
    state.completed = false

    status("Starting pan")
    local accepted = false

    for attempt = 1, CONFIG.MaxPanRetries do
        if not active(id) then return false, "Stopped" end
        local ok, response, err = invoke(remotes.Pan, id)
        if not ok then return false, err or "Pan failed" end
        if response == true then accepted = true; break end
        if not waitActive(CONFIG.PanRetryDelay, id) then
            return false, "Stopped"
        end
    end

    if not accepted then return false, "Pan was never accepted" end
    status("Shaking")
    local done = false

    for attempt = 1, CONFIG.MaxShakes do
        if not active(id) then return false, "Stopped" end

        if state.completed then break end

        if state.rewards > 0
            and os.clock() - state.lastReward >= CONFIG.RewardGap then
            break
        end

        local ok, err = pcall(function()
            remotes.Shake:FireServer()
        end)
        if not ok then return false, tostring(err) end

        if not waitActive(CONFIG.ShakeDelay, id) then
            return false, "Stopped"
        end
    end

    if state.completed then done = true end
    if state.rewards > 0 and os.clock() - state.lastReward
        >= CONFIG.RewardGap then done = true end

    if not done then
        local deadline = os.clock() + 2
        while active(id) and os.clock() < deadline do
            if state.completed then done = true; break end
            if state.rewards > 0 and os.clock() - state.lastReward
                >= CONFIG.RewardGap then
                done = true
                break
            end
            task.wait(0.05)
        end
    end

    if not done then return false, "No completion/reward signal" end

    while active(id) and state.rewards > 0
        and os.clock() - state.lastReward < CONFIG.RewardGap do
        task.wait(0.05)
    end

    return active(id)
end

local function startFarm()
    if not state.alive or state.running then return end
    if not state.digPosition then status("Save DIG position first"); return end
    if not state.waterPosition then status("Save WATER position first"); return end

    local capacity = tonumber(capBox.Text)
    if not capacity or capacity <= 0 then
        status("Enter valid Capacity")
        return
    end

    local remotes, err = findPan()
    if not remotes then status(err); return end
    if getFill(remotes) == nil then status("Cannot read pan Fill"); return end

    state.running = true
    state.revision = state.revision + 1
    local id = state.revision

    if remotes.Complete
        and remotes.Complete:IsA("RemoteEvent") then

        state.completionConnection =
            remotes.Complete.OnClientEvent:Connect(function()
                if active(id) then state.completed = true end
            end)
    end

    task.spawn(function()
        while active(id) do
            local ok, reason = dig(remotes, id, capacity)
            if not ok then
                if active(id) then stopFarm(reason) end
                break
            end

            if not active(id) then break end

            ok, reason = wash(remotes, id, capacity)
            if not ok then
                if active(id) then stopFarm(reason) end
                break
            end

            if not active(id) then break end

            state.cycles = state.cycles + 1
            status(string.format(
                "Pan %d completed - %d minerals",
                state.cycles,
                state.rewards
            ))
            updateProgress(getFill(remotes), capacity)
            if not waitActive(0.3, id) then break end
        end
    end)

    status("Running")
end

local backpack = player:WaitForChild("BackpackTwo")

connect(backpack.ChildAdded, function(item)
    if not state.running then return end
    local id = state.revision

    task.delay(0.06, function()
        if not active(id) then return end
        if state.phase ~= "Shaking" then return end
        if not item:IsA("Tool") then return end

        if item:GetAttribute("ItemType") == "Valuable" then
            state.rewards = state.rewards + 1
            state.lastReward = os.clock()
        end
    end)
end)

connect(digButton.MouseButton1Click, function()
    if state.running then return end
    local root = getRoot()
    if not root then status("Character unavailable"); return end
    state.digPosition = root.CFrame
    digButton.Text = "DIG SAVED"
    status("Dig position saved")
end)

connect(waterButton.MouseButton1Click, function()
    if state.running then return end
    local root = getRoot()
    if not root then status("Character unavailable"); return end
    state.waterPosition = root.CFrame
    waterButton.Text = "WATER SAVED"
    status("Water position saved")
end)

connect(testButton.MouseButton1Click, function()
    if state.running or not state.alive then return end
    local remotes, err = findPan()
    if not remotes then status(err); return end
    status("Testing one Collect(1) call")

    task.spawn(function()
        local before = getFill(remotes)
        local ok, response = pcall(function()
            return remotes.Collect:InvokeServer(1)
        end)
        task.wait(0.3)
        if not state.alive then return end

        local after = getFill(remotes)
        print("[TEST DIG] Before:", before)
        print("[TEST DIG] After:", after)
        print("[TEST DIG] Success:", ok)
        print("[TEST DIG] Response:", response)

        if not ok then
            status("TEST DIG failed - check console")
        elseif before ~= nil and after ~= nil and after > before then
            status(string.format(
                "TEST SUCCESS: %.1f -> %.1f",
                before, after
            ))
        else
            status("No Fill increase - check shovel/deposit")
        end
    end)
end)

connect(startButton.MouseButton1Click, startFarm)

connect(stopButton.MouseButton1Click, function()
    stopFarm("Stopped manually")
end)

local function closeFarm()
    if not state.alive then return end
    stopFarm("Closing")
    state.alive = false

    for _, c in ipairs(state.connections) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(state.connections)

    pcall(function() gui:Destroy() end)
    if env.CoastalSafeFarm == state then
        env.CoastalSafeFarm = nil
    end
    print("[COASTAL] UI removed. Farm stopped.")
    print("[COASTAL] No shovel toggle was sent.")
end

state.Close = function() closeFarm() end
state.Stop = function() stopFarm("Stopped") end

connect(closeButton.MouseButton1Click, closeFarm)

local minimized = false
connect(minimizeButton.MouseButton1Click, function()
    if not state.alive then return end
    minimized = not minimized
    body.Visible = not minimized
    main.Size = minimized
        and UDim2.fromOffset(360, 44)
        or UDim2.fromOffset(360, 345)
    minimizeButton.Text = minimized and "+" or "_"
end)

local dragging = false
local dragStart, windowStart

connect(header.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        windowStart = main.Position
    end
end)

connect(UIS.InputChanged, function(input)
    if not dragging or not state.alive then return end

    if input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            windowStart.X.Scale,
            windowStart.X.Offset + delta.X,
            windowStart.Y.Scale,
            windowStart.Y.Offset + delta.Y
        )
    end
end)

connect(UIS.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

connect(player.CharacterRemoving, function()
    if state.running then stopFarm("Character changed") end
end)

print("COASTAL SAFE PROSPECTING FARM LOADED")
print("No ToggleShovelActive calls.")
print("Equip your pan and activate digging normally.")
print("Save positions, TEST DIG, then START.")
print("X closes and disconnects everything.")
