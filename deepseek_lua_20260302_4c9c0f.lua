-- Rain Pet GUI - Using EXACT pet spawning from first script
-- This WILL make pets rain properly

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local TweenService = game:GetService('TweenService')
local HttpService = game:GetService('HttpService')
local Debris = game:GetService('Debris')
local Lighting = game:GetService('Lighting')

-- Set thread identity for proper access (from first script)
pcall(function()
    setthreadidentity(2)
end)

local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Load ALL modules from the first script
local Fsys = require(ReplicatedStorage:WaitForChild("Fsys"))
local LoadModule = Fsys.load

-- Load ALL modules exactly like the first script
local ClientData = LoadModule("ClientData")
local InventoryDB = LoadModule("InventoryDB")
local KindDB = LoadModule("KindDB")
local DownloadClient = LoadModule("DownloadClient")
local PetRigs = LoadModule("new:PetRigs")
local AnimationManager = LoadModule("AnimationManager")
local NeonVFXHelper = LoadModule("NeonVFXHelper")
local CharWrapperClient = LoadModule("CharWrapperClient")
local AilmentsClient = LoadModule("new:AilmentsClient")
local AilmentsDB = LoadModule("new:AilmentsDB")
local Maid = LoadModule("Maid")

-- Make InventoryDB global like first script
_G.InventoryDB = InventoryDB

-- ==============================================
-- EXACT FUNCTIONS FROM FIRST SCRIPT
-- ==============================================

-- Generate unique ID function (from first script)
local function GenerateUniqueID()
    return HttpService:GenerateGUID(false)
end

-- Generate unique pet name function (from first script)
local function GenerateUniquePetName()
    local prefixes = {"★", "☆", "♡", "☁️", "✨", "🍓", "🌸", "🍯", "☕", "🌙", "🌈", "❄️", "🫧", "🍬", "🍪", "🥛"}
    local names = {"Shadow", "Blaze", "Frost", "Thunder", "Moon", "Star", "Sky", "Ocean", "River", "Storm", 
                   "Ember", "Ash", "Dusk", "Dawn", "Night", "Day", "Sun", "Wind", "Rain", "Snow", "Ice", "Fire"}
    
    local usePrefix = math.random(1, 3) == 1
    local name = names[math.random(1, #names)]
    
    if usePrefix then
        return prefixes[math.random(1, #prefixes)] .. name
    else
        return name .. " " .. prefixes[math.random(1, #prefixes)]
    end
end

-- Newness groups from first script
local NewnessGroups = {
    mega_neon_flyable_rideable = 990000,
    mega_neon_flyable = 980000,
    mega_neon_rideable = 970000,
    mega_neon = 960000,
    neon_flyable_rideable = 950000,
    neon_flyable = 940000,
    neon_rideable = 930000,
    neon = 920000,
    flyable_rideable = 910000,
    flyable = 900000,
    rideable = 890000,
    regular = 880000
}

-- Get property group function (from first script)
local function GetPropertyGroup(properties)
    local isMega = properties.mega_neon or false
    local isNeon = properties.neon or false
    local canFly = properties.flyable or false
    local canRide = properties.rideable or false

    if isMega then
        if canFly and canRide then return "mega_neon_flyable_rideable"
        elseif canFly then return "mega_neon_flyable"
        elseif canRide then return "mega_neon_rideable"
        else return "mega_neon" end
    elseif isNeon then
        if canFly and canRide then return "neon_flyable_rideable"
        elseif canFly then return "neon_flyable"
        elseif canRide then return "neon_rideable"
        else return "neon" end
    else
        if canFly and canRide then return "flyable_rideable"
        elseif canFly then return "flyable"
        elseif canRide then return "rideable"
        else return "regular" end
    end
end

-- Update ClientData function (from first script)
local function UpdateClientData(dataPath, modifier)
    local identity = get_thread_identity and get_thread_identity() or 8
    set_thread_identity(2)
    local currentData = ClientData.get(dataPath)
    local clonedData = table.clone(currentData)
    local result = modifier(clonedData)
    ClientData.predict(dataPath, result)
    set_thread_identity(identity)
    return result
end

-- Pet Model Cache (from first script)
local PetModelCache = {}

-- Fetch pet model function (from first script)
local function FetchPetModel(petKind)
    if PetModelCache[petKind] then
        return PetModelCache[petKind]
    end
    local model = DownloadClient.promise_download_copy("Pets", petKind):expect()
    PetModelCache[petKind] = model
    return model
end

-- Apply neon visuals function (from first script)
local function ApplyNeonVisuals(petModel, petData)
    local modelInstance = petModel:FindFirstChild("PetModel")
    if modelInstance and (petData.properties.neon or petData.properties.mega_neon) then
        local petKindData = KindDB[petData.id]
        for partName, partProps in pairs(petKindData.neon_parts) do
            local geoPart = PetRigs.get(modelInstance).get_geo_part(modelInstance, partName)
            if geoPart then
                geoPart.Material = partProps.Material
                geoPart.Color = partProps.Color
            end
        end
    end
end

-- EXACT CreateInventoryItem function from first script
local NextToyOrder = 60000
local SpawnedItems = {}
local SpawnedPets = {}

local function CreateInventoryItem(itemId, category, properties)
    local uniqueId = GenerateUniqueID()
    local itemKindData = KindDB[itemId]

    if not itemKindData then
        warn("Item not found: " .. itemId)
        return nil
    end

    properties = properties or {}
    local newnessValue = NextToyOrder

    if category == "pets" then
        local groupKey = GetPropertyGroup(properties)
        NewnessGroups[groupKey] = NewnessGroups[groupKey] - 1
        newnessValue = NewnessGroups[groupKey]

        if not properties.ailments_completed then
            properties.ailments_completed = 0
        end

        if not properties.rp_name or properties.rp_name == "" then
            properties.rp_name = GenerateUniquePetName()
        end
        
        if properties.mega_neon and not properties.friendship_level then
            properties.friendship_level = math.random(1, 5)
        end
    else
        NextToyOrder = NextToyOrder - 1
        newnessValue = NextToyOrder
    end

    local itemData = {
        unique = uniqueId,
        category = category,
        id = itemId,
        kind = itemKindData.kind,
        newness_order = newnessValue,
        properties = properties,
        _source = "4fire"
    }

    local identity = get_thread_identity and get_thread_identity() or 8
    set_thread_identity(2)
    local inventory = ClientData.get("inventory")
    if inventory and inventory[category] then
        inventory[category][uniqueId] = itemData
    end
    set_thread_identity(identity)

    if category == "pets" then
        SpawnedPets[uniqueId] = { data = itemData, model = nil }
    end
    
    SpawnedItems[uniqueId] = true

    task.defer(function()
        if _G.UIManager and _G.UIManager.apps and _G.UIManager.apps.BackpackApp then
            _G.UIManager.apps.BackpackApp:refresh_rendered_items()
        end
    end)

    return itemData
end

-- Find pet ID function (from first script)
local function FindPetId(petName)
    for id, info in pairs(InventoryDB.pets) do
        if info.name:lower() == petName:lower() then
            return id
        end
    end
    return nil
end

-- ==============================================
-- GET ALL PETS FROM INVENTORYDB
-- ==============================================

local AllPets = {}
for id, info in pairs(InventoryDB.pets) do
    if info.name then
        table.insert(AllPets, {
            id = id,
            name = info.name,
            kind = info.kind
        })
    end
end

print("✅ Loaded " .. #AllPets .. " pets from InventoryDB")

-- ==============================================
-- SIMPLE GUI
-- ==============================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RainPetGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Main frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 400)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainFrame

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
title.Text = "☔ PET RAIN ☔"
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Parent = mainFrame
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 10)

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Parent = title
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

-- Potion selection
local potionLabel = Instance.new("TextLabel")
potionLabel.Size = UDim2.new(1, -20, 0, 30)
potionLabel.Position = UDim2.new(0, 10, 0, 50)
potionLabel.BackgroundTransparency = 1
potionLabel.Text = "Select Potion Type:"
potionLabel.Font = Enum.Font.GothamBold
potionLabel.TextSize = 14
potionLabel.TextXAlignment = Enum.TextXAlignment.Left
potionLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
potionLabel.Parent = mainFrame

local potionFrame = Instance.new("Frame")
potionFrame.Size = UDim2.new(1, -20, 0, 40)
potionFrame.Position = UDim2.new(0, 10, 0, 80)
potionFrame.BackgroundTransparency = 1
potionFrame.Parent = mainFrame

local potionButtons = {}
local potionColors = {
    mfr = Color3.fromRGB(170, 0, 255),
    nfr = Color3.fromRGB(0, 255, 100),
    fr = Color3.fromRGB(0, 200, 255),
    regular = Color3.fromRGB(150, 150, 150)
}
local selectedPotion = "regular"

local function updatePotionSelection()
    for name, btn in pairs(potionButtons) do
        if name == selectedPotion then
            btn.BackgroundColor3 = potionColors[name]
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Text = "▶ " .. btn.BaseText
        else
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            btn.TextColor3 = Color3.fromRGB(200, 200, 200)
            btn.Text = btn.BaseText
        end
    end
end

local potionNames = {"mfr", "nfr", "fr", "regular"}
local potionDisplay = {mfr = "MFR", nfr = "NFR", fr = "FR", regular = "Regular"}

for i, name in ipairs(potionNames) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.23, -2, 1, 0)
    btn.Position = UDim2.new((i-1) * 0.25, (i > 1) and 2 or 0, 0, 0)
    btn.BackgroundColor3 = name == "regular" and potionColors[name] or Color3.fromRGB(50, 50, 60)
    btn.Text = name == "regular" and "▶ Regular" or potionDisplay[name]
    btn.BaseText = potionDisplay[name]
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.TextColor3 = name == "regular" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
    btn.Parent = potionFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
    potionButtons[name] = btn
    
    btn.MouseButton1Click:Connect(function()
        selectedPotion = name
        updatePotionSelection()
    end)
end

-- Count slider
local countLabel = Instance.new("TextLabel")
countLabel.Size = UDim2.new(1, -20, 0, 25)
countLabel.Position = UDim2.new(0, 10, 0, 130)
countLabel.BackgroundTransparency = 1
countLabel.Text = "Number of Pets: 10"
countLabel.Font = Enum.Font.Gotham
countLabel.TextSize = 12
countLabel.TextXAlignment = Enum.TextXAlignment.Left
countLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
countLabel.Parent = mainFrame

local countSlider = Instance.new("Frame")
countSlider.Size = UDim2.new(1, -20, 0, 6)
countSlider.Position = UDim2.new(0, 10, 0, 160)
countSlider.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
countSlider.Parent = mainFrame
Instance.new("UICorner", countSlider).CornerRadius = UDim.new(1, 0)

local countFill = Instance.new("Frame")
countFill.Size = UDim2.new(0.2, 0, 1, 0) -- 10/50 = 0.2
countFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
countFill.Parent = countSlider
Instance.new("UICorner", countFill).CornerRadius = UDim.new(1, 0)

local countButton = Instance.new("TextButton")
countButton.Size = UDim2.new(0, 16, 0, 16)
countButton.Position = UDim2.new(0.2, -8, 0.5, -8)
countButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
countButton.Text = ""
countButton.Parent = countSlider
Instance.new("UICorner", countButton).CornerRadius = UDim.new(1, 0)

local petCount = 10

-- Speed slider
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, -20, 0, 25)
speedLabel.Position = UDim2.new(0, 10, 0, 180)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Speed: 5"
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextSize = 12
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedLabel.Parent = mainFrame

local speedSlider = Instance.new("Frame")
speedSlider.Size = UDim2.new(1, -20, 0, 6)
speedSlider.Position = UDim2.new(0, 10, 0, 210)
speedSlider.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
speedSlider.Parent = mainFrame
Instance.new("UICorner", speedSlider).CornerRadius = UDim.new(1, 0)

local speedFill = Instance.new("Frame")
speedFill.Size = UDim2.new(0.5, 0, 1, 0)
speedFill.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
speedFill.Parent = speedSlider
Instance.new("UICorner", speedFill).CornerRadius = UDim.new(1, 0)

local speedButton = Instance.new("TextButton")
speedButton.Size = UDim2.new(0, 16, 0, 16)
speedButton.Position = UDim2.new(0.5, -8, 0.5, -8)
speedButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
speedButton.Text = ""
speedButton.Parent = speedSlider
Instance.new("UICorner", speedButton).CornerRadius = UDim.new(1, 0)

local speedValue = 5

-- Rain button
local rainButton = Instance.new("TextButton")
rainButton.Size = UDim2.new(1, -20, 0, 50)
rainButton.Position = UDim2.new(0, 10, 0, 240)
rainButton.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
rainButton.Text = "☔ MAKE IT RAIN ☔"
rainButton.Font = Enum.Font.GothamBold
rainButton.TextSize = 18
rainButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rainButton.Parent = mainFrame
Instance.new("UICorner", rainButton).CornerRadius = UDim.new(0, 8)

-- Status label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 30)
statusLabel.Position = UDim2.new(0, 10, 0, 300)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Ready"
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.TextColor3 = Color3.fromRGB(180, 180, 220)
statusLabel.Parent = mainFrame

-- ==============================================
-- SLIDER DRAGGING
-- ==============================================

local draggingSlider = nil
local draggingButton = nil
local draggingFill = nil
local draggingLabel = nil
local draggingMin = 1
local draggingMax = 50
local draggingIsFloat = false

countButton.MouseButton1Down:Connect(function()
    draggingSlider = countSlider
    draggingButton = countButton
    draggingFill = countFill
    draggingLabel = countLabel
    draggingMin = 1
    draggingMax = 50
    draggingIsFloat = false
end)

speedButton.MouseButton1Down:Connect(function()
    draggingSlider = speedSlider
    draggingButton = speedButton
    draggingFill = speedFill
    draggingLabel = speedLabel
    draggingMin = 1
    draggingMax = 10
    draggingIsFloat = true
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
        local mousePos = UserInputService:GetMouseLocation()
        local sliderPos = draggingSlider.AbsolutePosition.X
        local sliderSize = draggingSlider.AbsoluteSize.X
        
        local percent = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
        
        draggingFill.Size = UDim2.new(percent, 0, 1, 0)
        draggingButton.Position = UDim2.new(percent, -8, 0.5, -8)
        
        if draggingIsFloat then
            local value = draggingMin + (draggingMax - draggingMin) * percent
            value = math.floor(value * 10) / 10
            if draggingLabel == speedLabel then
                speedValue = value
                draggingLabel.Text = "Speed: " .. value
            end
        else
            local value = math.floor(draggingMin + (draggingMax - draggingMin) * percent)
            if draggingLabel == countLabel then
                petCount = value
                draggingLabel.Text = "Number of Pets: " .. value
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingSlider = nil
        draggingButton = nil
        draggingFill = nil
        draggingLabel = nil
    end
end)

-- ==============================================
-- RAIN PET FUNCTION - USING EXACT FIRST SCRIPT METHODS
-- ==============================================

local activePets = {}
local isRaining = false

local function createRainPet()
    if #AllPets == 0 then return nil end
    
    -- Select random pet
    local petData = AllPets[math.random(1, #AllPets)]
    
    -- Create properties based on selected potion
    local properties = {
        pet_trick_level = 5,
        age = math.random(1, 6),
        ailments_completed = 0,
        rp_name = GenerateUniquePetName(),
        flyable = (selectedPotion ~= "regular"),
        rideable = (selectedPotion ~= "regular"),
        mega_neon = (selectedPotion == "mfr"),
        neon = (selectedPotion == "nfr" or selectedPotion == "mfr"),
        friendship_level = (selectedPotion == "mfr") and math.random(1, 5) or nil
    }
    
    -- Create inventory item (this adds to your inventory)
    local item = CreateInventoryItem(petData.id, "pets", properties)
    
    if not item then
        warn("Failed to create pet item")
        return nil
    end
    
    -- Fetch the actual pet model using the same method as first script
    local petModel = nil
    local success = pcall(function()
        petModel = FetchPetModel(petData.kind):Clone()
    end)
    
    if not success or not petModel then
        warn("Failed to load pet model for: " .. petData.name)
        return nil
    end
    
    -- Apply neon visuals if needed
    if selectedPotion == "mfr" or selectedPotion == "nfr" then
        pcall(function()
            ApplyNeonVisuals(petModel, item)
        end)
    end
    
    -- Position at top of screen
    local camera = workspace.CurrentCamera
    local viewportSize = camera.ViewportSize
    local randomX = math.random(100, viewportSize.X - 100)
    local ray = camera:ViewportPointToRay(randomX, -50)
    local spawnPos = ray.Origin + ray.Direction * 150
    
    petModel.Parent = workspace
    petModel:SetPrimaryPartCFrame(CFrame.new(spawnPos) * CFrame.Angles(0, math.random(0, 360), 0))
    
    -- Add trail for visual effect
    if petModel.PrimaryPart then
        local trail = Instance.new("Trail")
        trail.Attachment0 = Instance.new("Attachment", petModel.PrimaryPart)
        trail.Attachment1 = Instance.new("Attachment", petModel.PrimaryPart)
        trail.Attachment1.Position = Vector3.new(0, -2, 0)
        
        if selectedPotion == "mfr" then
            trail.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 0))
            })
        elseif selectedPotion == "nfr" then
            trail.Color = ColorSequence.new(Color3.fromRGB(0, 255, 0))
        elseif selectedPotion == "fr" then
            trail.Color = ColorSequence.new(Color3.fromRGB(0, 200, 255))
        else
            trail.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
        end
        
        trail.Transparency = NumberSequence.new(0.3)
        trail.Lifetime = 0.8
        trail.Parent = petModel.PrimaryPart
        
        -- Add glow
        local pointLight = Instance.new("PointLight")
        pointLight.Range = 15
        pointLight.Brightness = selectedPotion == "mfr" and 3 or 2
        pointLight.Parent = petModel.PrimaryPart
        
        if selectedPotion == "mfr" then
            pointLight.Color = Color3.fromHSV(math.random(), 1, 1)
            -- Rainbow cycle
            spawn(function()
                local hue = 0
                while petModel and petModel.PrimaryPart and petModel.Parent do
                    hue = (hue + 0.01) % 1
                    pointLight.Color = Color3.fromHSV(hue, 1, 1)
                    task.wait(0.05)
                end
            end)
        elseif selectedPotion == "nfr" then
            pointLight.Color = Color3.fromRGB(0, 255, 0)
        elseif selectedPotion == "fr" then
            pointLight.Color = Color3.fromRGB(0, 200, 255)
        end
    end
    
    -- Add simple spinning animation
    local spinConnection
    spinConnection = RunService.Heartbeat:Connect(function(dt)
        if petModel and petModel.PrimaryPart and petModel.Parent then
            petModel:SetPrimaryPartCFrame(petModel.PrimaryPart.CFrame * CFrame.Angles(0, dt * speedValue * 2, 0))
        else
            if spinConnection then spinConnection:Disconnect() end
        end
    end)
    
    -- Create falling tween
    local targetPos = spawnPos - Vector3.new(0, 300, 0)
    local fallTime = 3 / (speedValue / 5)
    
    local tween = TweenService:Create(petModel, TweenInfo.new(fallTime, Enum.EasingStyle.Quad), {
        CFrame = CFrame.new(targetPos) * CFrame.Angles(0, math.random(0, 360), 0)
    })
    
    tween:Play()
    
    -- Track and clean up
    local petId = tostring(math.random())
    activePets[petId] = petModel
    
    tween.Completed:Connect(function()
        if spinConnection then
            spinConnection:Disconnect()
        end
        
        if petModel and petModel.Parent then
            -- Fade out
            for _, part in pairs(petModel:GetDescendants()) do
                if part:IsA("BasePart") then
                    TweenService:Create(part, TweenInfo.new(1), {Transparency = 1}):Play()
                end
            end
            
            task.wait(1)
            petModel:Destroy()
            activePets[petId] = nil
        end
    end)
    
    Debris:AddItem(petModel, 15)
    
    return petModel
end

-- Rain function
local function startRain()
    if isRaining then 
        statusLabel.Text = "Already raining!"
        task.wait(1)
        statusLabel.Text = "Ready"
        return 
    end
    
    isRaining = true
    rainButton.Text = "☔ RAINING... ☔"
    rainButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    
    local potionNames = {mfr = "MFR", nfr = "NFR", fr = "FR", regular = "Regular"}
    statusLabel.Text = "Raining " .. petCount .. " " .. potionNames[selectedPotion] .. " pets..."
    
    local spawnedCount = 0
    
    for i = 1, petCount do
        local success = pcall(function()
            local pet = createRainPet()
            if pet then
                spawnedCount = spawnedCount + 1
            end
        end)
        
        if i % 5 == 0 then
            statusLabel.Text = "Spawned " .. i .. "/" .. petCount .. " pets..."
        end
        
        if i < petCount then
            task.wait(0.2)
        end
    end
    
    statusLabel.Text = "Complete! (" .. spawnedCount .. "/" .. petCount .. " pets)"
    rainButton.Text = "☔ MAKE IT RAIN ☔"
    rainButton.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
    
    task.wait(2)
    statusLabel.Text = "Ready"
    isRaining = false
end

-- ==============================================
-- EVENT HANDLERS
-- ==============================================

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    -- Clean up all pets
    for id, pet in pairs(activePets) do
        if pet and pet.Parent then
            pet:Destroy()
        end
    end
end)

rainButton.MouseButton1Click:Connect(function()
    if not isRaining then
        startRain()
    end
end)

-- Initialize potion selection
updatePotionSelection()

print("✅ RAIN PET GUI LOADED - USING ACTUAL PET MODELS!")
print("📊 Total pets available: " .. #AllPets)
print("🖱️ Click MAKE IT RAIN to see REAL pets fall!")