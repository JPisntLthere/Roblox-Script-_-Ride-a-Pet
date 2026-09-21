-- ============================================================================
-- EGG RADAR V2 (Deep Scanning & Safe Execution)
-- ============================================================================

-- #region 1. SERVICES & INITIAL VARIABLES
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
if not PlayerGui then return end

local Camera = Workspace.CurrentCamera

local RenderedEggs = Workspace:FindFirstChild("RenderedEggs")
if not RenderedEggs then
    RenderedEggs = Workspace:WaitForChild("RenderedEggs", 10)
end

local trackerEnabled = true
local maxDistance = 10000
local minDistanceLimit, maxDistanceLimit = 0, 10000

local dynamicFilters = {}
local filterInsertionOrder = {}
-- #endregion

-- #region 2. GUI CREATION & SETUP
if PlayerGui:FindFirstChild("UnifiedEggTrackerGui") then
    PlayerGui.UnifiedEggTrackerGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UnifiedEggTrackerGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 480, 0, 205)
mainFrame.Position = UDim2.new(1, -500, 0.5, -102)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 15, 35)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(160, 50, 220)
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -40, 0, 30)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Egg Radar V2"
titleLabel.TextColor3 = Color3.fromRGB(235, 180, 255)
titleLabel.TextSize, titleLabel.Font = 15, Enum.Font.SourceSansBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Active = true
titleLabel.Parent = mainFrame
-- #endregion

-- #region 3. UI INTERACTIONS & DRAGGING LOGIC
local draggingFrame = false
local dragInput, dragStart, startPos

titleLabel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingFrame = true
        dragStart = input.Position
        startPos = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                draggingFrame = false
            end
        end)
    end
end)

titleLabel.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and draggingFrame then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0, 25, 0, 25)
minimizeButton.Position = UDim2.new(1, -28, 0, 2)
minimizeButton.BackgroundColor3 = Color3.fromRGB(60, 25, 90)
minimizeButton.Text = "-"
minimizeButton.TextColor3 = Color3.fromRGB(240, 200, 255)
minimizeButton.TextSize, minimizeButton.Font = 16, Enum.Font.SourceSansBold
minimizeButton.Parent = mainFrame

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 4)
minCorner.Parent = minimizeButton

local container = Instance.new("Frame")
container.Size = UDim2.new(1, 0, 1, -30)
container.Position = UDim2.new(0, 0, 0, 30)
container.BackgroundTransparency = 1
container.Parent = mainFrame

local filterFrame = Instance.new("ScrollingFrame")
filterFrame.Size = UDim2.new(0, 145, 0, 146)
filterFrame.Position = UDim2.new(0, 5, 0, 0)
filterFrame.BackgroundTransparency = 0.2
filterFrame.BackgroundColor3 = Color3.fromRGB(35, 20, 50)
filterFrame.BorderSizePixel = 1
filterFrame.BorderColor3 = Color3.fromRGB(140, 40, 200)
filterFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
filterFrame.ScrollBarThickness = 3
filterFrame.Parent = container

local filterListLayout = Instance.new("UIListLayout")
filterListLayout.SortOrder = Enum.SortOrder.LayoutOrder
filterListLayout.Padding = UDim.new(0, 4)
filterListLayout.Parent = filterFrame

local rightContainer = Instance.new("Frame")
rightContainer.Size = UDim2.new(1, -160, 1, -10)
rightContainer.Position = UDim2.new(0, 155, 0, 0)
rightContainer.BackgroundTransparency = 1
rightContainer.Parent = container

local closestLabel = Instance.new("TextLabel")
closestLabel.Size = UDim2.new(1, 0, 0, 22)
closestLabel.Position = UDim2.new(0, 0, 0, 0)
closestLabel.BackgroundTransparency = 0.3
closestLabel.BackgroundColor3 = Color3.fromRGB(70, 25, 105)
closestLabel.TextColor3 = Color3.fromRGB(235, 160, 255)
closestLabel.TextSize, closestLabel.Font = 12, Enum.Font.SourceSans
closestLabel.TextXAlignment = Enum.TextXAlignment.Left
closestLabel.Visible = false
closestLabel.Parent = rightContainer

local closestCorner = Instance.new("UICorner")
closestCorner.CornerRadius = UDim.new(0, 4)
closestCorner.Parent = closestLabel

local farthestLabel = Instance.new("TextLabel")
farthestLabel.Size = UDim2.new(1, 0, 0, 22)
farthestLabel.Position = UDim2.new(0, 0, 0, 28)
farthestLabel.BackgroundTransparency = 0.3
farthestLabel.BackgroundColor3 = Color3.fromRGB(70, 25, 105)
farthestLabel.TextColor3 = Color3.fromRGB(235, 160, 255)
farthestLabel.TextSize, farthestLabel.Font = 12, Enum.Font.SourceSans
farthestLabel.TextXAlignment = Enum.TextXAlignment.Left
farthestLabel.Visible = false
farthestLabel.Parent = rightContainer

local farthestCorner = Instance.new("UICorner")
farthestCorner.CornerRadius = UDim.new(0, 4)
farthestCorner.Parent = farthestLabel

local distLabel = Instance.new("TextLabel")
distLabel.Size = UDim2.new(1, 0, 0, 18)
distLabel.Position = UDim2.new(0, 0, 1, -48)
distLabel.BackgroundTransparency = 1
distLabel.Text = "Max Distance: 10000 studs"
distLabel.TextColor3 = Color3.fromRGB(220, 180, 240)
distLabel.TextSize, distLabel.Font = 12, Enum.Font.SourceSans
distLabel.TextXAlignment = Enum.TextXAlignment.Left
distLabel.Parent = rightContainer

local sliderBar = Instance.new("Frame")
sliderBar.Size = UDim2.new(1, 0, 0, 8)
sliderBar.Position = UDim2.new(0, 0, 1, -28)
sliderBar.BackgroundColor3 = Color3.fromRGB(50, 25, 75)
sliderBar.BorderSizePixel = 0
sliderBar.Parent = rightContainer

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(1, 0)
barCorner.Parent = sliderBar

local sliderFill = Instance.new("Frame")
local initialPercent = (maxDistance - minDistanceLimit) / (maxDistanceLimit - minDistanceLimit)
sliderFill.Size = UDim2.new(initialPercent, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(190, 70, 255)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderBar

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = sliderFill

local minimized = false
minimizeButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    container.Visible = not minimized
    if minimized then
        mainFrame.Size = UDim2.new(0, 480, 0, 35)
        minimizeButton.Text = "+"
    else
        mainFrame.Size = UDim2.new(0, 480, 0, 205)
        minimizeButton.Text = "-"
    end
end)

local draggingSlider = false

local function updateSlider(input)
    local pos = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
    sliderFill.Size = UDim2.new(pos, 0, 1, 0)
    maxDistance = math.floor(minDistanceLimit + pos * (maxDistanceLimit - minDistanceLimit))
    distLabel.Text = string.format("Max Distance: %d studs", maxDistance)
end

sliderBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingSlider = true
        updateSlider(input)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingSlider = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateSlider(input)
    end
end)
-- #endregion

-- #region 4. ESP & DRAWING FUNCTIONS
local drawingPool = {}
if Drawing and Drawing.new then
    pcall(function()
        for i = 1, 50 do
            local line = Drawing.new("Line")
            line.Visible = false
            line.Color = Color3.fromRGB(190, 70, 255)
            line.Thickness = 2
            line.Transparency = 0.9
            table.insert(drawingPool, line)
        end
    end)
end

local function hideAllLines()
    for _, line in ipairs(drawingPool) do
        line.Visible = false
    end
end

local filterButtonObjects = {}
local eggCounts = {}

local function rebuildFilterUI()
    for _, btn in pairs(filterButtonObjects) do
        btn:Destroy()
    end
    filterButtonObjects = {}

    for index, eggName in ipairs(filterInsertionOrder) do
        local state = dynamicFilters[eggName]
        if state ~= nil then
            local count = eggCounts[eggName] or 0
            local filterBtn = Instance.new("TextButton")
            filterBtn.Size = UDim2.new(1, 0, 0, 25)
            filterBtn.BackgroundColor3 = state and Color3.fromRGB(80, 30, 120) or Color3.fromRGB(45, 20, 65)
            filterBtn.TextColor3 = state and Color3.fromRGB(245, 200, 255) or Color3.fromRGB(150, 110, 180)
            filterBtn.TextSize, filterBtn.Font = 11, Enum.Font.SourceSansBold
            filterBtn.Text = string.format(" [%s] (%d) %s", state and "ON" or "OFF", count, eggName)
            filterBtn.TextXAlignment = Enum.TextXAlignment.Left
            filterBtn.LayoutOrder = index
            filterBtn.Parent = filterFrame
            
            local fCorner = Instance.new("UICorner")
            fCorner.CornerRadius = UDim.new(0, 4)
            fCorner.Parent = filterBtn
            
            filterBtn.MouseButton1Click:Connect(function()
                dynamicFilters[eggName] = not dynamicFilters[eggName]
                local newState = dynamicFilters[eggName]
                local currentCount = eggCounts[eggName] or 0
                filterBtn.BackgroundColor3 = newState and Color3.fromRGB(80, 30, 120) or Color3.fromRGB(45, 20, 65)
                filterBtn.TextColor3 = newState and Color3.fromRGB(245, 200, 255) or Color3.fromRGB(150, 110, 180)
                filterBtn.Text = string.format(" [%s] (%d) %s", newState and "ON" or "OFF", currentCount, eggName)
            end)

            filterButtonObjects[eggName] = filterBtn
        end
    end

    filterFrame.CanvasSize = UDim2.new(0, 0, 0, #filterInsertionOrder * 29)
end

local function updateFilterOrderAndCounts()
    table.sort(filterInsertionOrder, function(a, b)
        local countA = eggCounts[a] or 0
        local countB = eggCounts[b] or 0
        if countA == countB then
            return a < b
        end
        return countA < countB
    end)

    for index, eggName in ipairs(filterInsertionOrder) do
        local btn = filterButtonObjects[eggName]
        if btn then
            btn.LayoutOrder = index
            local state = dynamicFilters[eggName]
            local count = eggCounts[eggName] or 0
            btn.Text = string.format(" [%s] (%d) %s", state and "ON" or "OFF", count, eggName)
        end
    end
end
-- #endregion

-- #region 5. MAIN RENDER LOOP & EXECUTION
local frameCounter = 0
local renderConnection
renderConnection = RunService.RenderStepped:Connect(function()
    frameCounter = (frameCounter + 1) % 2
    if frameCounter ~= 0 then return end

    hideAllLines()
    
    if not trackerEnabled then
        closestLabel.Visible = false
        farthestLabel.Visible = false
        return
    end

    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    local playerPos = rootPart.Position

    local currentMapEggs = {}
    local newEggCounts = {}

    if RenderedEggs then
        for _, activeEgg in ipairs(RenderedEggs:GetChildren()) do
            if activeEgg:IsA("BasePart") or activeEgg:IsA("Model") then
                local eggName = activeEgg.Name
                currentMapEggs[eggName] = true
                newEggCounts[eggName] = (newEggCounts[eggName] or 0) + 1
            end
        end
    end

    eggCounts = newEggCounts

    local filterChanged = false
    for i = #filterInsertionOrder, 1, -1 do
        local eggName = filterInsertionOrder[i]
        if not currentMapEggs[eggName] then
            dynamicFilters[eggName] = nil
            table.remove(filterInsertionOrder, i)
            filterChanged = true
        end
    end

    local detectedEggs = {}
    local foundNewEggName = false

    if RenderedEggs then
        for _, activeEgg in ipairs(RenderedEggs:GetChildren()) do
            if activeEgg:IsA("BasePart") or activeEgg:IsA("Model") then
                local eggName = activeEgg.Name
                if dynamicFilters[eggName] == nil then
                    dynamicFilters[eggName] = false
                    table.insert(filterInsertionOrder, eggName)
                    foundNewEggName = true
                end

                if dynamicFilters[eggName] == true then
                    local success, eggPos = pcall(function()
                        if activeEgg:IsA("Model") then
                            return activeEgg:GetPivot().Position
                        else
                            return activeEgg.Position
                        end
                    end)
                    
                    if success and eggPos then
                        local diff = eggPos - playerPos
                        local distSq = diff.X * diff.X + diff.Y * diff.Y + diff.Z * diff.Z
                        if distSq <= (maxDistance * maxDistance) then
                            table.insert(detectedEggs, {name = eggName, pos = eggPos, dist = math.floor(math.sqrt(distSq))})
                        end
                    end
                end
            end
        end
    end

    -- Only fully rebuild UI if new eggs appear or disappear; otherwise just smoothly update counts/order
    if foundNewEggName or filterChanged then
        rebuildFilterUI()
    else
        updateFilterOrderAndCounts()
    end

    table.sort(detectedEggs, function(a, b)
        return a.dist < b.dist
    end)

    if #detectedEggs > 0 then
        local closest = detectedEggs[1]
        closestLabel.Text = string.format(" [CLOSEST] %s: %d studs", closest.name, closest.dist)
        closestLabel.Visible = true

        local farthest = detectedEggs[#detectedEggs]
        farthestLabel.Text = string.format(" [FARTHEST] %s: %d studs", farthest.name, farthest.dist)
        farthestLabel.Visible = true
    else
        closestLabel.Visible = false
        farthestLabel.Visible = false
    end

    local lineIndex = 1
    for _, data in ipairs(detectedEggs) do
        if lineIndex <= #drawingPool then
            local screenPos, onScreen = Camera:WorldToViewportPoint(data.pos)
            if onScreen then
                local line = drawingPool[lineIndex]
                line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                line.To = Vector2.new(screenPos.X, screenPos.Y)
                line.Visible = true
                lineIndex = lineIndex + 1
            end
        end
    end
end)

screenGui.Destroying:Connect(function()
    if renderConnection then
        renderConnection:Disconnect()
    end
    for _, line in ipairs(drawingPool) do
        pcall(function() line.Remove() end)
    end
end)

print("Egg Radar V2 Deep Scan Loaded!")
-- #endregion