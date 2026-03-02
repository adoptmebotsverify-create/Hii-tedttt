-- Rain Pet GUI - With MFR/NFR/FR Options
-- Creates a button that makes random pets rain from the sky with customizable potions

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local TweenService = game:GetService('TweenService')
local Debris = game:GetService('Debris')
local HttpService = game:GetService('HttpService')

-- Wait for player
local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Try to load required modules safely
local InventoryDB = nil
local KindDB = nil
local DownloadClient = nil
local PetRigs = nil
local ClientData = nil
local NeonVFXHelper = nil

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
    pcall(function()
        ClientData = LoadModule("ClientData")
    end)
    pcall(function()
        NeonVFXHelper = LoadModule("NeonVFXHelper")
    end)
end

-- Function to generate unique ID (from first file)
local function GenerateUniqueID()
    return HttpService:GenerateGUID(false)
end

-- Function to generate unique pet name (from first file)
local function GenerateUniquePetName()
    local prefixes = {"★", "☆", "♡", "☁️", "✨", "🍓", "🌸", "🍯", "☕", "🌙", "🌈", "❄️", "🫧", "🍬", "🍪", "🥛"}
    local names = {"Shadow", "Blaze", "Frost", "Thunder", "Moon", "Star", "Sky", "Ocean", "River", "Storm", 
                   "Ember", "Ash", "Dusk", "Dawn", "Night", "Day", "Sun", "Wind", "Rain", "Snow", "Ice", "Fire",
                   "Nova", "Cosmo", "Galaxy", "Orbit", "Comet", "Meteor", "Aurora", "Nebula", "Crystal", "Gem",
                   "Ruby", "Sapphire", "Emerald", "Diamond", "Gold", "Silver", "Mystic", "Magic", "Enchant"}
    
    local usePrefix = math.random(1, 3) == 1
    local name = names[math.random(1, #names)]
    
    if usePrefix then
        return prefixes[math.random(1, #prefixes)] .. name
    else
        return name .. " " .. prefixes[math.random(1, #prefixes)]
    end
end

-- Function to create inventory item (adapted from first file)
local function CreateRainInventoryItem(itemId, category, properties)
    if not ClientData then return nil end
    
    local uniqueId = GenerateUniqueID()
    local itemKindData = KindDB and KindDB[itemId]

    if not itemKindData then
        return nil
    end

    properties = properties or {}
    
    -- Set newness order based on properties
    local newnessValue = 880000 -- regular
    if properties.mega_neon then
        if properties.flyable and properties.rideable then newnessValue = 990000
        elseif properties.flyable then newnessValue = 980000
        elseif properties.rideable then newnessValue = 970000
        else newnessValue = 960000 end
    elseif properties.neon then
        if properties.flyable and properties.rideable then newnessValue = 950000
        elseif properties.flyable then newnessValue = 940000
        elseif properties.rideable then newnessValue = 930000
        else newnessValue = 920000 end
    else
        if properties.flyable and properties.rideable then newnessValue = 910000
        elseif properties.flyable then newnessValue = 900000
        elseif properties.rideable then newnessValue = 890000
        else newnessValue = 880000 end
    end

    if not properties.ailments_completed then
        properties.ailments_completed = 0
    end

    if not properties.rp_name or properties.rp_name == "" then
        properties.rp_name = GenerateUniquePetName()
    end
    
    if properties.mega_neon and not properties.friendship_level then
        properties.friendship_level = math.random(1, 5)
    end

    local itemData = {
        unique = uniqueId,
        category = category,
        id = itemId,
        kind = itemKindData.kind,
        newness_order = newnessValue,
        properties = properties,
        _source = "rain_pet"
    }

    -- Try to add to inventory
    pcall(function()
        local identity = get_thread_identity and get_thread_identity() or 8
        set_thread_identity(2)
        local inventory = ClientData.get("inventory")
        if inventory and inventory[category] then
            inventory[category][uniqueId] = itemData
        end
        set_thread_identity(identity)
    end)

    return itemData
end

-- Fallback pet list
local AllPets = {}
if InventoryDB and InventoryDB.pets then
    for id, info in pairs(InventoryDB.pets) do
        if info.name then
            table.insert(AllPets, {
                id = id,
                name = info.name,
                displayName = info.name
            })
        end
    end
else
    -- Fallback common pets list
    local fallbackPets = {
        "Shadow Dragon", "Bat Dragon", "Frost Dragon", "Giraffe", "Owl", "Parrot", "Crow",
        "Evil Unicorn", "Arctic Reindeer", "Hedgehog", "Dalmatian", "Turtle", "Kangaroo",
        "Lion", "Elephant", "Blazing Lion", "Flamingo", "Mini Pig", "Caterpillar",
        "Albino Monkey", "Blue Dog", "Pink Cat", "Nessie", "Cow", "Monkey King",
        "Fairy Bat Dragon", "Strawberry Shortcake Bat Dragon", "Chocolate Chip Bat Dragon",
        "Vampire Dragon", "Grim Dragon", "Lava Dragon", "Phantom Dragon", "Cupid Dragon"
    }
    for i, name in ipairs(fallbackPets) do
        table.insert(AllPets, {
            id = tostring(i),
            name = name,
            displayName = name
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
rainButton.Size = UDim2.new(0, 220, 0, 80)
rainButton.Position = UDim2.new(0.5, -110, 0.1, 0)
rainButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
rainButton.Text = "☔ RAIN PETS ☔"
rainButton.Font = Enum.Font.GothamBold
rainButton.TextSize = 20
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
settingsPanel.Size = UDim2.new(0, 320, 0, 400)
settingsPanel.Position = UDim2.new(0.5, -160, 0.25, 0)
settingsPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
settingsPanel.Visible = false
settingsPanel.Parent = screenGui
settingsPanel.Active = true
settingsPanel.Draggable = true

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 16)
panelCorner.Parent = settingsPanel

local panelTitle = Instance.new("TextLabel")
panelTitle.Size = UDim2.new(1, 0, 0, 45)
panelTitle.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
panelTitle.Text = "⚙️ Rain Settings ⚙️"
panelTitle.Font = Enum.Font.GothamBold
panelTitle.TextSize = 18
panelTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
panelTitle.Parent = settingsPanel
Instance.new("UICorner", panelTitle).CornerRadius = UDim.new(0, 16)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 35, 0, 35)
closeBtn.Position = UDim2.new(1, -40, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Parent = settingsPanel
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 10)

-- Settings content (ScrollingFrame)
local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Size = UDim2.new(1, -20, 1, -55)
contentFrame.Position = UDim2.new(0, 10, 0, 50)
contentFrame.BackgroundTransparency = 1
contentFrame.ScrollBarThickness = 8
contentFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 150)
contentFrame.CanvasSize = UDim2.new(0, 0, 0, 600)
contentFrame.Parent = settingsPanel
contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y

-- Pet count slider
local countLabel = Instance.new("TextLabel")
countLabel.Size = UDim2.new(1, 0, 0, 30)
countLabel.BackgroundTransparency = 1
countLabel.Text = "Number of Pets: 15"
countLabel.Font = Enum.Font.Gotham
countLabel.TextSize = 14
countLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
countLabel.TextXAlignment = Enum.TextXAlignment.Left
countLabel.Parent = contentFrame

local countSlider = Instance.new("Frame")
countSlider.Size = UDim2.new(1, 0, 0, 10)
countSlider.Position = UDim2.new(0, 0, 0, 35)
countSlider.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
countSlider.Parent = contentFrame
Instance.new("UICorner", countSlider).CornerRadius = UDim.new(1, 0)

local countFill = Instance.new("Frame")
countFill.Size = UDim2.new(0.3, 0, 1, 0)
countFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
countFill.Parent = countSlider
Instance.new("UICorner", countFill).CornerRadius = UDim.new(1, 0)

-- Potion Type Section
local potionLabel = Instance.new("TextLabel")
potionLabel.Size = UDim2.new(1, 0, 0, 30)
potionLabel.Position = UDim2.new(0, 0, 0, 60)
potionLabel.BackgroundTransparency = 1
potionLabel.Text = "✨ Potion Type:"
potionLabel.Font = Enum.Font.GothamBold
potionLabel.TextSize = 16
potionLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
potionLabel.TextXAlignment = Enum.TextXAlignment.Left
potionLabel.Parent = contentFrame

-- MFR (Mega Neon) Button
local mfrButton = Instance.new("TextButton")
mfrButton.Size = UDim2.new(1, 0, 0, 45)
mfrButton.Position = UDim2.new(0, 0, 0, 95)
mfrButton.BackgroundColor3 = Color3.fromRGB(100, 0, 255)
mfrButton.Text = "🌈 MFR (Mega Neon)"
mfrButton.Font = Enum.Font.GothamBold
mfrButton.TextSize = 16
mfrButton.TextColor3 = Color3.fromRGB(255, 255, 255)
mfrButton.Parent = contentFrame
Instance.new("UICorner", mfrButton).CornerRadius = UDim.new(0, 10)

-- Add a checkmark for MFR
local mfrCheck = Instance.new("Frame")
mfrCheck.Size = UDim2.new(0, 25, 0, 25)
mfrCheck.Position = UDim2.new(1, -35, 0.5, -12.5)
mfrCheck.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
mfrCheck.Visible = false
mfrCheck.Parent = mfrButton
Instance.new("UICorner", mfrCheck).CornerRadius = UDim.new(1, 0)

local mfrCheckLabel = Instance.new("TextLabel")
mfrCheckLabel.Size = UDim2.new(1, 0, 1, 0)
mfrCheckLabel.BackgroundTransparency = 1
mfrCheckLabel.Text = "✓"
mfrCheckLabel.Font = Enum.Font.GothamBold
mfrCheckLabel.TextSize = 20
mfrCheckLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
mfrCheckLabel.Parent = mfrCheck

-- NFR (Neon) Button
local nfrButton = Instance.new("TextButton")
nfrButton.Size = UDim2.new(1, 0, 0, 45)
nfrButton.Position = UDim2.new(0, 0, 0, 145)
nfrButton.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
nfrButton.Text = "🌟 NFR (Neon)"
nfrButton.Font = Enum.Font.GothamBold
nfrButton.TextSize = 16
nfrButton.TextColor3 = Color3.fromRGB(255, 255, 255)
nfrButton.Parent = contentFrame
Instance.new("UICorner", nfrButton).CornerRadius = UDim.new(0, 10)

-- Add a checkmark for NFR
local nfrCheck = Instance.new("Frame")
nfrCheck.Size = UDim2.new(0, 25, 0, 25)
nfrCheck.Position = UDim2.new(1, -35, 0.5, -12.5)
nfrCheck.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
nfrCheck.Visible = false
nfrCheck.Parent = nfrButton
Instance.new("UICorner", nfrCheck).CornerRadius = UDim.new(1, 0)

local nfrCheckLabel = Instance.new("TextLabel")
nfrCheckLabel.Size = UDim2.new(1, 0, 1, 0)
nfrCheckLabel.BackgroundTransparency = 1
nfrCheckLabel.Text = "✓"
nfrCheckLabel.Font = Enum.Font.GothamBold
nfrCheckLabel.TextSize = 20
nfrCheckLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
nfrCheckLabel.Parent = nfrCheck

-- FR (Fly/Ride) Button
local frButton = Instance.new("TextButton")
frButton.Size = UDim2.new(1, 0, 0, 45)
frButton.Position = UDim2.new(0, 0, 0, 195)
frButton.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
frButton.Text = "🪽 FR (Fly + Ride)"
frButton.Font = Enum.Font.GothamBold
frButton.TextSize = 16
frButton.TextColor3 = Color3.fromRGB(255, 255, 255)
frButton.Parent = contentFrame
Instance.new("UICorner", frButton).CornerRadius = UDim.new(0, 10)

-- Add a checkmark for FR
local frCheck = Instance.new("Frame")
frCheck.Size = UDim2.new(0, 25, 0, 25)
frCheck.Position = UDim2.new(1, -35, 0.5, -12.5)
frCheck.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
frCheck.Visible = false
frCheck.Parent = frButton
Instance.new("UICorner", frCheck).CornerRadius = UDim.new(1, 0)

local frCheckLabel = Instance.new("TextLabel")
frCheckLabel.Size = UDim2.new(1, 0, 1, 0)
frCheckLabel.BackgroundTransparency = 1
frCheckLabel.Text = "✓"
frCheckLabel.Font = Enum.Font.GothamBold
frCheckLabel.TextSize = 20
frCheckLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
frCheckLabel.Parent = frCheck

-- Regular (No Potion) Button
local regularButton = Instance.new("TextButton")
regularButton.Size = UDim2.new(1, 0, 0, 45)
regularButton.Position = UDim2.new(0, 0, 0, 245)
regularButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
regularButton.Text = "⚪ Regular (No Potions)"
regularButton.Font = Enum.Font.GothamBold
regularButton.TextSize = 16
regularButton.TextColor3 = Color3.fromRGB(255, 255, 255)
regularButton.Parent = contentFrame
Instance.new("UICorner", regularButton).CornerRadius = UDim.new(0, 10)

-- Add a checkmark for Regular
local regularCheck = Instance.new("Frame")
regularCheck.Size = UDim2.new(0, 25, 0, 25)
regularCheck.Position = UDim2.new(1, -35, 0.5, -12.5)
regularCheck.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
regularCheck.Visible = false
regularCheck.Parent = regularButton
Instance.new("UICorner", regularCheck).CornerRadius = UDim.new(1, 0)

local regularCheckLabel = Instance.new("TextLabel")
regularCheckLabel.Size = UDim2.new(1, 0, 1, 0)
regularCheckLabel.BackgroundTransparency = 1
regularCheckLabel.Text = "✓"
regularCheckLabel.Font = Enum.Font.GothamBold
regularCheckLabel.TextSize = 20
regularCheckLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
regularCheckLabel.Parent = regularCheck

-- Potion state
local potionState = {
    mfr = false,
    nfr = false,
    fr = false,
    regular = true
}

-- Update checkmarks
local function updatePotionChecks()
    mfrCheck.Visible = potionState.mfr
    nfrCheck.Visible = potionState.nfr
    frCheck.Visible = potionState.fr
    regularCheck.Visible = potionState.regular
end

-- Button click handlers
mfrButton.MouseButton1Click:Connect(function()
    potionState.mfr = true
    potionState.nfr = false
    potionState.fr = false
    potionState.regular = false
    updatePotionChecks()
end)

nfrButton.MouseButton1Click:Connect(function()
    potionState.mfr = false
    potionState.nfr = true
    potionState.fr = false
    potionState.regular = false
    updatePotionChecks()
end)

frButton.MouseButton1Click:Connect(function()
    potionState.mfr = false
    potionState.nfr = false
    potionState.fr = true
    potionState.regular = false
    updatePotionChecks()
end)

regularButton.MouseButton1Click:Connect(function()
    potionState.mfr = false
    potionState.nfr = false
    potionState.fr = false
    potionState.regular = true
    updatePotionChecks()
end)

-- Animation dropdown
local animLabel = Instance.new("TextLabel")
animLabel.Size = UDim2.new(1, 0, 0, 30)
animLabel.Position = UDim2.new(0, 0, 0, 305)
animLabel.BackgroundTransparency = 1
animLabel.Text = "🎭 Animation:"
animLabel.Font = Enum.Font.GothamBold
animLabel.TextSize = 16
animLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
animLabel.TextXAlignment = Enum.TextXAlignment.Left
animLabel.Parent = contentFrame

local animDropdown = Instance.new("TextButton")
animDropdown.Size = UDim2.new(1, 0, 0, 40)
animDropdown.Position = UDim2.new(0, 0, 0, 340)
animDropdown.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
animDropdown.Text = "Random"
animDropdown.Font = Enum.Font.Gotham
animDropdown.TextSize = 14
animDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
animDropdown.Parent = contentFrame
Instance.new("UICorner", animDropdown).CornerRadius = UDim.new(0, 10)

-- Animation options
local animOptions = {"Random", "Spin", "Bounce", "Float", "Tumble", "Dizzy", "Twirl", "Wave"}
local currentAnim = "Random"

-- Speed slider
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, 0, 0, 30)
speedLabel.Position = UDim2.new(0, 0, 0, 395)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Speed: 5"
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextSize = 14
speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = contentFrame

local speedSlider = Instance.new("Frame")
speedSlider.Size = UDim2.new(1, 0, 0, 10)
speedSlider.Position = UDim2.new(0, 0, 0, 430)
speedSlider.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
speedSlider.Parent = contentFrame
Instance.new("UICorner", speedSlider).CornerRadius = UDim.new(1, 0)

local speedFill = Instance.new("Frame")
speedFill.Size = UDim2.new(0.5, 0, 1, 0)
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

local function applyTwirl(pet, speed)
    local time = 0
    local connection
    connection = RunService.Heartbeat:Connect(function(dt)
        if pet and pet.PrimaryPart then
            time = time + dt
            local yAngle = dt * speed * 6
            local xAngle = math.sin(time * 3) * 0.2
            pet:SetPrimaryPartCFrame(pet.PrimaryPart.CFrame * CFrame.Angles(xAngle, yAngle, 0))
        else
            if connection then connection:Disconnect() end
        end
    end)
    return connection
end

local function applyWave(pet, speed)
    local time = 0
    local connection
    connection = RunService.Heartbeat:Connect(function(dt)
        if pet and pet.PrimaryPart then
            time = time + dt
            local wave = math.sin(time * speed * 4) * 0.3
            pet:SetPrimaryPartCFrame(pet.PrimaryPart.CFrame * CFrame.Angles(0, wave, wave))
        else
            if connection then connection:Disconnect() end
        end
    end)
    return connection
end

-- Function to create a falling pet with potion effects
local function createRainPet()
    if #AllPets == 0 then return end
    
    -- Select random pet
    local petData = AllPets[math.random(1, #AllPets)]
    
    -- Create properties based on potion state
    local properties = {
        pet_trick_level = 5,
        age = math.random(1, 6),
        ailments_completed = 0,
        rp_name = GenerateUniquePetName(),
        flyable = potionState.fr or potionState.mfr or potionState.nfr or false,
        rideable = potionState.fr or potionState.mfr or potionState.nfr or false,
        mega_neon = potionState.mfr,
        neon = potionState.nfr or potionState.mfr,
    }
    
    if potionState.mfr then
        properties.friendship_level = math.random(1, 5)
    end
    
    -- Create inventory item
    if ClientData and petData.id then
        CreateRainInventoryItem(petData.id, "pets", properties)
    end
    
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
    
    -- If no model, create a placeholder with potion effects
    if not model then
        model = Instance.new("Model")
        local part = Instance.new("Part")
        
        -- Size based on potion type
        if potionState.mfr then
            part.Size = Vector3.new(3, 3, 3)
        elseif potionState.nfr then
            part.Size = Vector3.new(2.5, 2.5, 2.5)
        else
            part.Size = Vector3.new(2, 2, 2)
        end
        
        -- Color based on potion type
        if potionState.mfr then
            part.BrickColor = BrickColor.new("Really red")
            part.Material = Enum.Material.Neon
        elseif potionState.nfr then
            part.BrickColor = BrickColor.new("Bright green")
            part.Material = Enum.Material.Neon
        elseif potionState.fr then
            part.BrickColor = BrickColor.new("Bright blue")
        else
            part.BrickColor = BrickColor.new("Bright yellow")
        end
        
        part.Parent = model
        model.PrimaryPart = part
        
        -- Add glow for neon/mega
        if potionState.mfr or potionState.nfr then
            local pointLight = Instance.new("PointLight")
            pointLight.Range = 15
            pointLight.Brightness = 3
            pointLight.Color = Color3.fromHSV(math.random(), 1, 1)
            pointLight.Parent = part
            
            -- Rainbow cycle for mega neon
            if potionState.mfr then
                spawn(function()
                    local hue = 0
                    while model and model.PrimaryPart do
                        hue = (hue + 0.01) % 1
                        pointLight.Color = Color3.fromHSV(hue, 1, 1)
                        part.Color = Color3.fromHSV(hue, 1, 1)
                        task.wait(0.05)
                    end
                end)
            end
        end
        
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 120, 0, 60)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.Parent = part
        
        local text = Instance.new("TextLabel")
        text.Size = UDim2.new(1, 0, 1, 0)
        text.BackgroundTransparency = 1
        text.Text = petData.name
        text.TextColor3 = Color3.fromRGB(255, 255, 255)
        text.TextScaled = true
        text.Font = Enum.Font.GothamBold
        text.Parent = billboard
        
        -- Add potion indicator
        local potionText = Instance.new("TextLabel")
        potionText.Size = UDim2.new(1, 0, 0, 20)
        potionText.Position = UDim2.new(0, 0, 1, 0)
        potionText.BackgroundTransparency = 1
        potionText.Text = potionState.mfr and "MFR" or potionState.nfr and "NFR" or potionState.fr and "FR" or ""
        potionText.TextColor3 = potionState.mfr and Color3.fromRGB(255, 0, 255) or 
                               potionState.nfr and Color3.fromRGB(0, 255, 0) or
                               potionState.fr and Color3.fromRGB(0, 200, 255) or
                               Color3.fromRGB(255, 255, 255)
        potionText.Font = Enum.Font.GothamBold
        potionText.TextSize = 14
        potionText.Parent = billboard
    end
    
    -- Position at top of screen
    local camera = workspace.CurrentCamera
    local viewportSize = camera.ViewportSize
    local randomX = math.random(100, viewportSize.X - 100)
    local ray = camera:ViewportPointToRay(randomX, -50)
    local spawnPos = ray.Origin + ray.Direction * 100
    
    model.Parent = workspace
    model:SetPrimaryPartCFrame(CFrame.new(spawnPos) * CFrame.Angles(0, math.random(0, 360), 0))
    
    -- Add trail with potion color
    local trail = Instance.new("Trail")
    trail.Attachment0 = Instance.new("Attachment", model.PrimaryPart)
    trail.Attachment1 = Instance.new("Attachment", model.PrimaryPart)
    trail.Attachment1.Position = Vector3.new(0, -2, 0)
    
    if potionState.mfr then
        trail.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 0))
        })
    elseif potionState.nfr then
        trail.Color = ColorSequence.new(Color3.fromRGB(0, 255, 0))
    elseif potionState.fr then
        trail.Color = ColorSequence.new(Color3.fromRGB(0, 200, 255))
    else
        trail.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
    end
    
    trail.Transparency = NumberSequence.new(0.3)
    trail.Lifetime = 0.5
    trail.Parent = model.PrimaryPart
    
    -- Add glow
    local pointLight = Instance.new("PointLight")
    pointLight.Range = 12
    pointLight.Brightness = 3
    if potionState.mfr then
        pointLight.Color = Color3.fromHSV(math.random(), 1, 1)
    elseif potionState.nfr then
        pointLight.Color = Color3.fromRGB(0, 255, 0)
    elseif potionState.fr then
        pointLight.Color = Color3.fromRGB(0, 200, 255)
    else
        pointLight.Brightness = 1
    end
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
    elseif selectedAnim == "Twirl" then
        animConnection = applyTwirl(model, animSpeed)
    elseif selectedAnim == "Wave" then
        animConnection = applyWave(model, animSpeed)
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
    
    local potionText = potionState.mfr and "MFR" or potionState.nfr and "NFR" or potionState.fr and "FR" or "Regular"
    statusLabel.Text = "Raining " .. petCount .. " " .. potionText .. " pets..."
    
    for i = 1, petCount do
        createRainPet()
        if i < petCount then
            task.wait(0.1)
        end
    end
    
    statusLabel.Text = "Done! (" .. petCount .. " " .. potionText .. " pets)"
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

countSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingSlider = countSlider
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
        
        if draggingSlider == countSlider then
            countFill.Size = UDim2.new(percent, 0, 1, 0)
            petCount = math.floor(1 + percent * 49)
            countLabel.Text = "Number of Pets: " .. petCount
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
    menu.Size = UDim2.new(1, 0, 0, #animOptions * 40)
    menu.Position = UDim2.new(0, 0, 1, 5)
    menu.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    menu.Parent = animDropdown
    Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 10)
    
    for i, animName in ipairs(animOptions) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 35)
        btn.Position = UDim2.new(0, 0, 0, (i-1) * 40)
        btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
        btn.Text = animName
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Parent = menu
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        
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

-- Initialize regular as default
updatePotionChecks()

print("✅ Rain Pet GUI with MFR/NFR/FR loaded successfully!")
print("📊 Available pets: " .. #AllPets)
print("🖱️ Left-click to rain | Right-click for settings")
print("✨ Select MFR, NFR, FR, or Regular from settings!")