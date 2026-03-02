-- Rain Pet GUI - Fixed Version
-- Creates a button that makes random pets rain from the sky with animations

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local TweenService = game:GetService('TweenService')
local Debris = game:GetService('Debris')

-- Wait for player
local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Try to load required modules safely
local InventoryDB = nil
local KindDB = nil
local DownloadClient = nil
local PetRigs = nil

-- Attempt to load modules with error handling
local success, Fsys = pcall(function()
    return require(ReplicatedStorage:WaitForChild("Fsys"))
end)

if success and Fsys then
    local LoadModule = Fsys.load
    pcall(function()
        InventoryDB = LoadModule("InventoryDB")
    end)
    pcall(function()
        KindDB = LoadModule("KindDB")
    end)
    pcall(function()
        DownloadClient = LoadModule("DownloadClient")
    end)
    pcall(function()
        PetRigs = LoadModule("new:PetRigs")
    end)
end

-- Fallback pet list if InventoryDB fails
local AllPets = {}
if InventoryDB and InventoryDB.pets then
    for id, info in pairs(InventoryDB.pets) do
        if info.name then
            table.insert(AllPets, {
                id = id,
                name = info.name
            })
        end
    end
else
    -- Fallback common pets list
    local fallbackPets = {
        "Shadow Dragon", "Bat Dragon", "Frost Dragon", "Giraffe", "Owl", "Parrot", "Crow",
        "Evil Unicorn", "Arctic Reindeer", "Hedgehog", "Dalmatian", "Turtle", "Kangaroo",
        "Lion", "Elephant", "Blazing Lion", "Flamingo", "Mini Pig", "Caterpillar",
        "Albino Monkey", "Blue Dog", "Pink Cat", "Nessie", "Cow", "Monkey King"
    }
    for i, name in ipairs(fallbackPets) do
        table.insert(AllPets, {
            id = tostring(i),
            name = name
        })
    end
end

print("✅ Loaded " .. #AllPets .. " pets for rain effect")

-- Create main GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RainPetGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Main button
local rainButton = Instance.new("TextButton")
rainButton.Size = UDim2.new(0, 200, 0, 70)
rainButton.Position = UDim2.new(0.5, -100, 0.1, 0)
rainButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
rainButton.Text = "☔ RAIN PETS ☔"
rainButton.Font = Enum.Font.GothamBold
rainButton.TextSize = 18
rainButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rainButton.Parent = screenGui
rainButton.Draggable = true
rainButton.Active = true
rainButton.Selectable = true

-- Button styling
local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 20)
buttonCorner.Parent = rainButton

local buttonStroke = Instance.new("UIStroke")
buttonStroke.Thickness = 3
buttonStroke.Color = Color3.fromRGB(255, 255, 255)
buttonStroke.Transparency = 0.3
buttonStroke.Parent = rainButton

-- Status label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 25)
statusLabel.Position = UDim2.new(0, 0, 1, 5)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Ready!"
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 14
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
statusLabel.Parent = rainButton

-- Settings panel
local settingsPanel = Instance.new("Frame")
settingsPanel.Size = UDim2.new(0, 280, 0, 250)
settingsPanel.Position = UDim2.new(0.5, -140, 0.3, 0)
settingsPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
settingsPanel.Visible = false
settingsPanel.Parent = screenGui
settingsPanel.Active = true
settingsPanel.Draggable = true

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = settingsPanel

local panelTitle = Instance.new("TextLabel")
panelTitle.Size = UDim2.new(1, 0, 0, 40)
panelTitle.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
panelTitle.Text = "⚙️ Settings ⚙️"
panelTitle.Font = Enum.Font.GothamBold
panelTitle.TextSize = 16
panelTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
panelTitle.Parent = settingsPanel
Instance.new("UICorner", panelTitle).CornerRadius = UDim.new(0, 12)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Parent = settingsPanel
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

-- Settings content
local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, -20, 1, -50)
contentFrame.Position = UDim2.new(0, 10, 0, 45)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = settingsPanel

-- Amount slider
local amountLabel = Instance.new("TextLabel")
amountLabel.Size = UDim2.new(1, 0, 0, 30)
amountLabel.BackgroundTransparency = 1
amountLabel.Text = "Number of Pets: 15"
amountLabel.Font = Enum.Font.Gotham
amountLabel.TextSize = 14
amountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
amountLabel.TextXAlignment = Enum.TextXAlignment.Left
amountLabel.Parent = contentFrame

local amountSlider = Instance.new("Frame")
amountSlider.Size = UDim2.new(1, 0, 0, 8)
amountSlider.Position = UDim2.new(0, 0, 0, 35)
amountSlider.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
amountSlider.Parent = contentFrame
Instance.new("UICorner", amountSlider).CornerRadius = UDim.new(1, 0)

local amountFill = Instance.new("Frame")
amountFill.Size = UDim2.new(0.3, 0, 1, 0) -- 15/50 = 0.3
amountFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
amountFill.Parent = amountSlider
Instance.new("UICorner", amountFill).CornerRadius = UDim.new(1, 0)

-- Animation dropdown
local animLabel = Instance.new("TextLabel")
animLabel.Size = UDim2.new(1, 0, 0, 30)
animLabel.Position = UDim2.new(0, 0, 0, 60)
animLabel.BackgroundTransparency = 1
animLabel.Text = "Animation:"
animLabel.Font = Enum.Font.Gotham
animLabel.TextSize = 14
animLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
animLabel.TextXAlignment = Enum.TextXAlignment.Left
animLabel.Parent = contentFrame

local animDropdown = Instance.new("TextButton")
animDropdown.Size = UDim2.new(1, 0, 0, 35)
animDropdown.Position = UDim2.new(0, 0, 0, 95)
animDropdown.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
animDropdown.Text = "Random"
animDropdown.Font = Enum.Font.Gotham
animDropdown.TextSize = 14
animDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
animDropdown.Parent = contentFrame
Instance.new("UICorner", animDropdown).CornerRadius = UDim.new(0, 8)

-- Animation options
local animOptions = {"Random", "Spin", "Bounce", "Float", "Tumble", "Dizzy"}
local currentAnim = "Random"

-- Speed slider
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, 0, 0, 30)
speedLabel.Position = UDim2.new(0, 0, 0, 145)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Speed: 5"
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextSize = 14
speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = contentFrame

local speedSlider = Instance.new("Frame")
speedSlider.Size = UDim2.new(1, 0, 0, 8)
speedSlider.Position = UDim2.new(0, 0, 0, 180)
speedSlider.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
speedSlider.Parent = contentFrame
Instance.new("UICorner", speedSlider).CornerRadius = UDim.new(1, 0)

local speedFill = Instance.new("Frame")
speedFill.Size = UDim2.new(0.5, 0, 1, 0) -- 5/10 = 0.5
speedFill.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
speedFill.Parent = speedSlider
Instance.new("UICorner", speedFill).CornerRadius = UDim.new(1, 0)

-- Variables
local petCount = 15
local animSpeed = 5
local activePets = {}
local isRaining = false

-- Animation functions
local function applySpin(pet, speed)
    local connection
    connection = RunService.Heartbeat:Connect(function(dt)
        if pet and pet.PrimaryPart then
            pet:SetPrimaryPartCFrame(pet.PrimaryPart.CFrame * CFrame.Angles(0, dt * speed * 8, 0))
        else
            if connection then connection:Disconnect() end
        end
    end)
    return connection
end

local function applyBounce(pet, speed)
    local originalY = pet.PrimaryPart.Position.Y
    local time = 0
    local connection
    connection = RunService.Heartbeat:Connect(function(dt)
        if pet and pet.PrimaryPart then
            time = time + dt
            local offset = math.abs(math.sin(time * speed * 3)) * 3
            pet:SetPrimaryPartCFrame(CFrame.new(
                pet.PrimaryPart.Position.X,
                originalY + offset,
                pet.PrimaryPart.Position.Z
            ))
        else
            if connection then connection:Disconnect() end
        end
    end)
    return connection
end

local function applyFloat(pet, speed)
    local time = 0
    local connection
    connection = RunService.Heartbeat:Connect(function(dt)
        if pet and pet.PrimaryPart then
            time = time + dt
            local offset = math.sin(time * 2) * 1.5
            pet:SetPrimaryPartCFrame(pet.PrimaryPart.CFrame + Vector3.new(0, offset * dt, 0))
        else
            if connection then connection:Disconnect() end
        end
    end)
    return connection
end

local function applyTumble(pet, speed)
    local connection
    connection = RunService.Heartbeat:Connect(function(dt)
        if pet and pet.PrimaryPart then
            pet:SetPrimaryPartCFrame(pet.PrimaryPart.CFrame * CFrame.Angles(dt * speed * 5, dt * speed * 3, 0))
        else
            if connection then connection:Disconnect() end
        end
    end)
    return connection
end

local function applyDizzy(pet, speed)
    local time = 0
    local connection
    connection = RunService.Heartbeat:Connect(function(dt)
        if pet and pet.PrimaryPart then
            time = time + dt
            local randomRot = math.random(-30, 30) * dt
            pet:SetPrimaryPartCFrame(pet.PrimaryPart.CFrame * CFrame.Angles(randomRot, dt * speed * 10, randomRot))
        else
            if connection then connection:Disconnect() end
        end
    end)
    return connection
end

-- Function to create a falling pet
local function createRainPet()
    if #AllPets == 0 then return end
    
    -- Select random pet
    local petData = AllPets[math.random(1, #AllPets)]
    
    -- Try to load pet model
    local model = nil
    
    if DownloadClient and DownloadClient.promise_download_copy then
        pcall(function()
            model = DownloadClient.promise_download_copy("Pets", petData.id):expect()
            if model then
                model = model:Clone()
            end
        end)
    end
    
    -- If no model, create a simple placeholder
    if not model then
        model = Instance.new("Model")
        local part = Instance.new("Part")
        part.Size = Vector3.new(2, 2, 2)
        part.BrickColor = BrickColor.new("Bright red")
        part.Parent = model
        model.PrimaryPart = part
        
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 100, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 2, 0)
        billboard.Parent = part
        
        local text = Instance.new("TextLabel")
        text.Size = UDim2.new(1, 0, 1, 0)
        text.BackgroundTransparency = 1
        text.Text = petData.name
        text.TextColor3 = Color3.fromRGB(255, 255, 255)
        text.TextScaled = true
        text.Font = Enum.Font.GothamBold
        text.Parent = billboard
    end
    
    -- Position at top of screen
    local camera = workspace.CurrentCamera
    local viewportSize = camera.ViewportSize
    local randomX = math.random(100, viewportSize.X - 100)
    local ray = camera:ViewportPointToRay(randomX, -50)
    local spawnPos = ray.Origin + ray.Direction * 100
    
    model.Parent = workspace
    model:SetPrimaryPartCFrame(CFrame.new(spawnPos) * CFrame.Angles(0, math.random(0, 360), 0))
    
    -- Add trail
    local trail = Instance.new("Trail")
    trail.Attachment0 = Instance.new("Attachment", model.PrimaryPart)
    trail.Attachment1 = Instance.new("Attachment", model.PrimaryPart)
    trail.Attachment1.Position = Vector3.new(0, -2, 0)
    trail.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
    trail.Transparency = NumberSequence.new(0.3)
    trail.Lifetime = 0.5
    trail.Parent = model.PrimaryPart
    
    -- Add glow
    local pointLight = Instance.new("PointLight")
    pointLight.Range = 10
    pointLight.Brightness = 2
    pointLight.Color = Color3.fromHSV(math.random(), 1, 1)
    pointLight.Parent = model.PrimaryPart
    
    -- Apply animation based on selection
    local animConnection = nil
    local selectedAnim = currentAnim == "Random" and animOptions[math.random(2, #animOptions)] or currentAnim
    
    if selectedAnim == "Spin" then
        animConnection = applySpin(model, animSpeed)
    elseif selectedAnim == "Bounce" then
        animConnection = applyBounce(model, animSpeed)
    elseif selectedAnim == "Float" then
        animConnection = applyFloat(model, animSpeed)
    elseif selectedAnim == "Tumble" then
        animConnection = applyTumble(model, animSpeed)
    elseif selectedAnim == "Dizzy" then
        animConnection = applyDizzy(model, animSpeed)
    end
    
    -- Create falling tween
    local targetPos = spawnPos - Vector3.new(0, 300, 0)
    local fallTime = 2 / (animSpeed / 5)
    
    local tween = TweenService:Create(model, TweenInfo.new(fallTime, Enum.EasingStyle.Quad), {
        CFrame = CFrame.new(targetPos) * CFrame.Angles(0, math.random(0, 360), 0)
    })
    
    tween:Play()
    
    -- Track pet
    local petId = tostring(math.random())
    activePets[petId] = model
    
    -- Clean up
    tween.Completed:Connect(function()
        if animConnection then
            animConnection:Disconnect()
        end
        
        if model then
            -- Fade out
            for _, part in pairs(model:GetDescendants()) do
                if part:IsA("BasePart") then
                    TweenService:Create(part, TweenInfo.new(1), {Transparency = 1}):Play()
                end
            end
            
            task.wait(1)
            model:Destroy()
            activePets[petId] = nil
        end
    end)
    
    Debris:AddItem(model, 10)
    
    return model
end

-- Rain function
local function startRain()
    if isRaining then return end
    isRaining = true
    
    statusLabel.Text = "Raining " .. petCount .. " pets..."
    
    for i = 1, petCount do
        createRainPet()
        if i < petCount then
            task.wait(0.1)
        end
    end
    
    statusLabel.Text = "Done! (" .. petCount .. " pets)"
    task.wait(2)
    statusLabel.Text = "Ready!"
    isRaining = false
end

-- Button click
rainButton.MouseButton1Click:Connect(startRain)

-- Right-click for settings
rainButton.MouseButton2Click:Connect(function()
    settingsPanel.Visible = not settingsPanel.Visible
end)

-- Close settings
closeBtn.MouseButton1Click:Connect(function()
    settingsPanel.Visible = false
end)

-- Slider dragging
local draggingSlider = nil

amountSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingSlider = amountSlider
    end
end)

speedSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingSlider = speedSlider
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
        local pos = input.Position.X
        local absPos = draggingSlider.AbsolutePosition.X
        local size = draggingSlider.AbsoluteSize.X
        
        local percent = math.clamp((pos - absPos) / size, 0, 1)
        
        if draggingSlider == amountSlider then
            amountFill.Size = UDim2.new(percent, 0, 1, 0)
            petCount = math.floor(1 + percent * 49)
            amountLabel.Text = "Number of Pets: " .. petCount
        elseif draggingSlider == speedSlider then
            speedFill.Size = UDim2.new(percent, 0, 1, 0)
            animSpeed = 1 + percent * 9
            speedLabel.Text = "Speed: " .. math.floor(animSpeed * 10) / 10
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingSlider = nil
    end
end)

-- Animation dropdown click
animDropdown.MouseButton1Click:Connect(function()
    -- Create dropdown menu
    local menu = Instance.new("Frame")
    menu.Size = UDim2.new(1, 0, 0, #animOptions * 35)
    menu.Position = UDim2.new(0, 0, 1, 5)
    menu.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    menu.Parent = animDropdown
    Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 8)
    
    for i, animName in ipairs(animOptions) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.Position = UDim2.new(0, 0, 0, (i-1) * 35)
        btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
        btn.Text = animName
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Parent = menu
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        
        btn.MouseButton1Click:Connect(function()
            currentAnim = animName
            animDropdown.Text = animName
            menu:Destroy()
        end)
    end
    
    -- Close menu when clicking outside
    local function onInputBegan(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local pos = UserInputService:GetMouseLocation()
            local absPos = menu.AbsolutePosition
            local size = menu.AbsoluteSize
            
            if pos.X < absPos.X or pos.X > absPos.X + size.X or
               pos.Y < absPos.Y or pos.Y > absPos.Y + size.Y then
                menu:Destroy()
                UserInputService.InputBegan:Disconnect(connection)
            end
        end
    end
    
    local connection = UserInputService.InputBegan:Connect(onInputBegan)
    
    -- Clean up if menu destroyed
    menu.Destroying:Connect(function()
        connection:Disconnect()
    end)
end)

-- Hide settings when clicking outside
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and settingsPanel.Visible then
        local pos = UserInputService:GetMouseLocation()
        local absPos = settingsPanel.AbsolutePosition
        local size = settingsPanel.AbsoluteSize
        
        if pos.X < absPos.X or pos.X > absPos.X + size.X or
           pos.Y < absPos.Y or pos.Y > absPos.Y + size.Y then
            
            local btnPos = rainButton.AbsolutePosition
            local btnSize = rainButton.AbsoluteSize
            
            if pos.X < btnPos.X or pos.X > btnPos.X + btnSize.X or
               pos.Y < btnPos.Y or pos.Y > btnPos.Y + btnSize.Y then
                settingsPanel.Visible = false
            end
        end
    end
end)

-- Rainbow animation for button
spawn(function()
    while true do
        for hue = 0, 1, 0.01 do
            rainButton.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
            task.wait(0.02)
        end
    end
end)

print("✅ Rain Pet GUI loaded successfully!")
print("📊 Available pets: " .. #AllPets)
print("🖱️ Left-click to rain | Right-click for settings")