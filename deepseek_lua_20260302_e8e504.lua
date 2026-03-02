-- Rain Pet GUI - Premium Edition with MFR/NFR/FR Selector
-- Beautiful, intuitive interface for selecting pet potions

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local TweenService = game:GetService('TweenService')
local Debris = game:GetService('Debris')
local HttpService = game:GetService('HttpService')
local Lighting = game:GetService('Lighting')

-- Wait for player
local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Try to load required modules safely
local InventoryDB = nil
local KindDB = nil
local DownloadClient = nil
local ClientData = nil

-- Attempt to load modules with error handling
local success, Fsys = pcall(function()
    return require(ReplicatedStorage:WaitForChild("Fsys"))
end)

if success and Fsys then
    local LoadModule = Fsys.load
    pcall(function() InventoryDB = LoadModule("InventoryDB") end)
    pcall(function() KindDB = LoadModule("KindDB") end)
    pcall(function() DownloadClient = LoadModule("DownloadClient") end)
    pcall(function() ClientData = LoadModule("ClientData") end)
end

-- Function to generate unique ID
local function GenerateUniqueID()
    return HttpService:GenerateGUID(false)
end

-- Function to generate unique pet name
local function GenerateUniquePetName()
    local prefixes = {"★", "☆", "♡", "☁️", "✨", "🍓", "🌸", "🍯", "☕", "🌙", "🌈", "❄️", "🫧", "🍬", "🍪", "🥛"}
    local names = {"Shadow", "Blaze", "Frost", "Thunder", "Moon", "Star", "Sky", "Ocean", "River", "Storm"}
    local usePrefix = math.random(1, 3) == 1
    local name = names[math.random(1, #names)]
    return usePrefix and (prefixes[math.random(1, #prefixes)] .. name) or (name .. " " .. prefixes[math.random(1, #prefixes)])
end

-- Function to create inventory item
local function CreateRainInventoryItem(itemId, category, properties)
    if not ClientData then return nil end
    local uniqueId = GenerateUniqueID()
    local itemKindData = KindDB and KindDB[itemId]
    if not itemKindData then return nil end

    properties = properties or {}
    properties.ailments_completed = 0
    properties.rp_name = properties.rp_name or GenerateUniquePetName()
    
    if properties.mega_neon and not properties.friendship_level then
        properties.friendship_level = math.random(1, 5)
    end

    local itemData = {
        unique = uniqueId,
        category = category,
        id = itemId,
        kind = itemKindData.kind,
        newness_order = 990000 - (properties.mega_neon and 0 or properties.neon and 10000 or 20000),
        properties = properties,
        _source = "rain_pet"
    }

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

-- Pet database
local AllPets = {}
if InventoryDB and InventoryDB.pets then
    for id, info in pairs(InventoryDB.pets) do
        if info.name then
            table.insert(AllPets, {id = id, name = info.name})
        end
    end
else
    local fallbackPets = {
        "Shadow Dragon", "Bat Dragon", "Frost Dragon", "Giraffe", "Owl", "Parrot",
        "Evil Unicorn", "Arctic Reindeer", "Fairy Bat Dragon", "Vampire Dragon",
        "Grim Dragon", "Lava Dragon", "Phantom Dragon", "Cupid Dragon", "Nessie",
        "Cow", "Monkey King", "Turtle", "Kangaroo", "Flamingo", "Blue Dog", "Pink Cat"
    }
    for i, name in ipairs(fallbackPets) do
        table.insert(AllPets, {id = tostring(i), name = name})
    end
end

-- ==============================================
-- MAIN GUI - MODERN DESIGN
-- ==============================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RainPetGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Main container (glass morphism effect)
local mainContainer = Instance.new("Frame")
mainContainer.Size = UDim2.new(0, 400, 0, 550)
mainContainer.Position = UDim2.new(0.5, -200, 0.5, -275)
mainContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainContainer.BackgroundTransparency = 0.1
mainContainer.ClipsDescendants = true
mainContainer.Parent = screenGui
mainContainer.Active = true
mainContainer.Draggable = true

-- Blur background
local blurEffect = Instance.new("BlurEffect")
blurEffect.Size = 0
blurEffect.Parent = Lighting

-- Modern corners
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 20)
mainCorner.Parent = mainContainer

-- Glass border
local mainStroke = Instance.new("UIStroke")
mainStroke.Thickness = 2
mainStroke.Color = Color3.fromRGB(100, 100, 150)
mainStroke.Transparency = 0.5
mainStroke.Parent = mainContainer

-- Inner glow
local innerGlow = Instance.new("Frame")
innerGlow.Size = UDim2.new(1, -4, 1, -4)
innerGlow.Position = UDim2.new(0, 2, 0, 2)
innerGlow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
innerGlow.BackgroundTransparency = 0.95
innerGlow.Parent = mainContainer
Instance.new("UICorner", innerGlow).CornerRadius = UDim.new(0, 18)

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 70)
header.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
header.BackgroundTransparency = 0.2
header.Parent = mainContainer
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 20)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 1, 0)
title.BackgroundTransparency = 1
title.Text = "☔ PET RAIN MAKER ☔"
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextTransparency = 0.1
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, 0, 0, 20)
subtitle.Position = UDim2.new(0, 0, 1, -20)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Select your potion type"
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 12
subtitle.TextColor3 = Color3.fromRGB(180, 180, 220)
subtitle.Parent = header

-- Close button
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -40, 0, 20)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeButton.Text = "✕"
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 16
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Parent = header
Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0, 8)

-- ==============================================
-- POTION SELECTOR CARDS (MFR, NFR, FR)
-- ==============================================

local potionContainer = Instance.new("Frame")
potionContainer.Size = UDim2.new(1, -40, 0, 200)
potionContainer.Position = UDim2.new(0, 20, 0, 90)
potionContainer.BackgroundTransparency = 1
potionContainer.Parent = mainContainer

-- Selected potion state
local selectedPotion = "regular" -- mfr, nfr, fr, regular

-- Helper to update card visuals
local function updateCardSelection()
    for _, child in pairs(potionContainer:GetChildren()) do
        if child:IsA("Frame") and child:FindFirstChild("SelectIndicator") then
            local isSelected = child.Name == selectedPotion.."Card"
            local indicator = child.SelectIndicator
            local stroke = child:FindFirstChild("UIStroke")
            
            indicator.Visible = isSelected
            if stroke then
                stroke.Thickness = isSelected and 3 or 1.5
                stroke.Transparency = isSelected and 0 or 0.7
            end
            
            -- Scale effect
            TweenService:Create(child, TweenInfo.new(0.2), {
                Size = isSelected and UDim2.new(0.3, -5, 0.9, 0) or UDim2.new(0.3, -5, 0.85, 0)
            }):Play()
        end
    end
end

-- Create potion card function
local function createPotionCard(name, displayName, color, icon, position)
    local card = Instance.new("Frame")
    card.Name = name.."Card"
    card.Size = UDim2.new(0.3, -5, 0.85, 0)
    card.Position = position
    card.BackgroundColor3 = color
    card.BackgroundTransparency = 0.2
    card.Parent = potionContainer
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 16)
    
    -- Stroke
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.5
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.7
    stroke.Parent = card
    
    -- Icon
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(1, 0, 0, 50)
    iconLabel.Position = UDim2.new(0, 0, 0, 15)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = icon
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.TextSize = 30
    iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    iconLabel.Parent = card
    
    -- Name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 25)
    nameLabel.Position = UDim2.new(0, 0, 0, 70)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = displayName
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.Parent = card
    
    -- Description
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, 0, 0, 40)
    descLabel.Position = UDim2.new(0, 0, 0, 95)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = name == "mfr" and "Mega Neon + Fly + Ride" or
                     name == "nfr" and "Neon + Fly + Ride" or
                     name == "fr" and "Fly + Ride" or
                     "No Potions"
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextSize = 9
    descLabel.TextColor3 = Color3.fromRGB(220, 220, 255)
    descLabel.TextWrapped = true
    descLabel.Parent = card
    
    -- Selection indicator
    local indicator = Instance.new("Frame")
    indicator.Name = "SelectIndicator"
    indicator.Size = UDim2.new(1, -10, 1, -10)
    indicator.Position = UDim2.new(0, 5, 0, 5)
    indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    indicator.BackgroundTransparency = 0.9
    indicator.Visible = false
    indicator.Parent = card
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 12)
    
    -- Checkmark
    local check = Instance.new("TextLabel")
    check.Size = UDim2.new(0, 20, 0, 20)
    check.Position = UDim2.new(1, -25, 1, -25)
    check.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    check.Text = "✓"
    check.Font = Enum.Font.GothamBold
    check.TextSize = 14
    check.TextColor3 = Color3.fromRGB(255, 255, 255)
    check.Parent = indicator
    Instance.new("UICorner", check).CornerRadius = UDim.new(1, 0)
    
    -- Click handler
    card.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            selectedPotion = name
            updateCardSelection()
            
            -- Play click sound (if you want)
            -- (Optional sound effect)
        end
    end)
    
    return card
end

-- Create the three cards
local mfrCard = createPotionCard("mfr", "MFR", Color3.fromRGB(170, 0, 255), "🌈", UDim2.new(0, 0, 0.5, -85))
local nfrCard = createPotionCard("nfr", "NFR", Color3.fromRGB(0, 200, 100), "🌟", UDim2.new(0.35, 0, 0.5, -85))
local frCard = createPotionCard("fr", "FR", Color3.fromRGB(0, 150, 255), "🪽", UDim2.new(0.7, 0, 0.5, -85))

-- Regular card (separate below)
local regularCard = Instance.new("Frame")
regularCard.Name = "regularCard"
regularCard.Size = UDim2.new(0.94, 0, 0, 50)
regularCard.Position = UDim2.new(0.03, 0, 0, 305)
regularCard.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
regularCard.BackgroundTransparency = 0.2
regularCard.Parent = mainContainer
Instance.new("UICorner", regularCard).CornerRadius = UDim.new(0, 12)

-- Regular card stroke
local regularStroke = Instance.new("UIStroke")
regularStroke.Thickness = 1.5
regularStroke.Color = Color3.fromRGB(255, 255, 255)
regularStroke.Transparency = 0.7
regularStroke.Parent = regularCard

-- Regular icon
local regularIcon = Instance.new("TextLabel")
regularIcon.Size = UDim2.new(0, 40, 1, 0)
regularIcon.BackgroundTransparency = 1
regularIcon.Text = "⚪"
regularIcon.Font = Enum.Font.GothamBold
regularIcon.TextSize = 24
regularIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
regularIcon.Parent = regularCard

-- Regular text
local regularText = Instance.new("TextLabel")
regularText.Size = UDim2.new(1, -50, 1, 0)
regularText.Position = UDim2.new(0, 50, 0, 0)
regularText.BackgroundTransparency = 1
regularText.Text = "Regular (No Potions)"
regularText.Font = Enum.Font.GothamBold
regularText.TextSize = 16
regularText.TextXAlignment = Enum.TextXAlignment.Left
regularText.TextColor3 = Color3.fromRGB(255, 255, 255)
regularText.Parent = regularCard

-- Regular selection indicator
local regularIndicator = Instance.new("Frame")
regularIndicator.Name = "SelectIndicator"
regularIndicator.Size = UDim2.new(1, -6, 1, -6)
regularIndicator.Position = UDim2.new(0, 3, 0, 3)
regularIndicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
regularIndicator.BackgroundTransparency = 0.9
regularIndicator.Visible = false
regularIndicator.Parent = regularCard
Instance.new("UICorner", regularIndicator).CornerRadius = UDim.new(0, 10)

local regularCheck = Instance.new("TextLabel")
regularCheck.Size = UDim2.new(0, 20, 0, 20)
regularCheck.Position = UDim2.new(1, -25, 0.5, -10)
regularCheck.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
regularCheck.Text = "✓"
regularCheck.Font = Enum.Font.GothamBold
regularCheck.TextSize = 14
regularCheck.TextColor3 = Color3.fromRGB(255, 255, 255)
regularCheck.Parent = regularIndicator
Instance.new("UICorner", regularCheck).CornerRadius = UDim.new(1, 0)

regularCard.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        selectedPotion = "regular"
        updateCardSelection()
    end
end)

-- ==============================================
-- SETTINGS SECTION
-- ==============================================

local settingsContainer = Instance.new("Frame")
settingsContainer.Size = UDim2.new(1, -40, 0, 120)
settingsContainer.Position = UDim2.new(0, 20, 0, 370)
settingsContainer.BackgroundTransparency = 0.5
settingsContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
settingsContainer.Parent = mainContainer
Instance.new("UICorner", settingsContainer).CornerRadius = UDim.new(0, 12)

local settingsTitle = Instance.new("TextLabel")
settingsTitle.Size = UDim2.new(1, 0, 0, 25)
settingsTitle.Position = UDim2.new(0, 10, 0, 5)
settingsTitle.BackgroundTransparency = 1
settingsTitle.Text = "⚙️ Settings"
settingsTitle.Font = Enum.Font.GothamBold
settingsTitle.TextSize = 14
settingsTitle.TextXAlignment = Enum.TextXAlignment.Left
settingsTitle.TextColor3 = Color3.fromRGB(220, 220, 255)
settingsTitle.Parent = settingsContainer

-- Pet count slider
local countLabel = Instance.new("TextLabel")
countLabel.Size = UDim2.new(0.5, 0, 0, 20)
countLabel.Position = UDim2.new(0, 10, 0, 30)
countLabel.BackgroundTransparency = 1
countLabel.Text = "Pet Count: 15"
countLabel.Font = Enum.Font.Gotham
countLabel.TextSize = 12
countLabel.TextXAlignment = Enum.TextXAlignment.Left
countLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
countLabel.Parent = settingsContainer

local countSlider = Instance.new("Frame")
countSlider.Size = UDim2.new(0.45, 0, 0, 6)
countSlider.Position = UDim2.new(0, 10, 0, 55)
countSlider.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
countSlider.Parent = settingsContainer
Instance.new("UICorner", countSlider).CornerRadius = UDim.new(1, 0)

local countFill = Instance.new("Frame")
countFill.Size = UDim2.new(0.3, 0, 1, 0)
countFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
countFill.Parent = countSlider
Instance.new("UICorner", countFill).CornerRadius = UDim.new(1, 0)

local countValue = 15

-- Speed slider
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0.5, 0, 0, 20)
speedLabel.Position = UDim2.new(0.5, 0, 0, 30)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Speed: 5"
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextSize = 12
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedLabel.Parent = settingsContainer

local speedSlider = Instance.new("Frame")
speedSlider.Size = UDim2.new(0.45, 0, 0, 6)
speedSlider.Position = UDim2.new(0.5, 10, 0, 55)
speedSlider.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
speedSlider.Parent = settingsContainer
Instance.new("UICorner", speedSlider).CornerRadius = UDim.new(1, 0)

local speedFill = Instance.new("Frame")
speedFill.Size = UDim2.new(0.5, 0, 1, 0)
speedFill.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
speedFill.Parent = speedSlider
Instance.new("UICorner", speedFill).CornerRadius = UDim.new(1, 0)

local speedValue = 5

-- Animation dropdown
local animLabel = Instance.new("TextLabel")
animLabel.Size = UDim2.new(1, -20, 0, 20)
animLabel.Position = UDim2.new(0, 10, 0, 70)
animLabel.BackgroundTransparency = 1
animLabel.Text = "Animation: Random"
animLabel.Font = Enum.Font.Gotham
animLabel.TextSize = 12
animLabel.TextXAlignment = Enum.TextXAlignment.Left
animLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
animLabel.Parent = settingsContainer

local animDropdown = Instance.new("TextButton")
animDropdown.Size = UDim2.new(0.45, 0, 0, 25)
animDropdown.Position = UDim2.new(0.5, 10, 0, 70)
animDropdown.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
animDropdown.Text = "Random"
animDropdown.Font = Enum.Font.Gotham
animDropdown.TextSize = 12
animDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
animDropdown.Parent = settingsContainer
Instance.new("UICorner", animDropdown).CornerRadius = UDim.new(0, 6)

-- Animation options
local animOptions = {"Random", "Spin", "Bounce", "Float", "Tumble", "Twirl", "Wave"}
local currentAnim = "Random"

-- ==============================================
-- RAIN BUTTON
-- ==============================================

local rainButton = Instance.new("TextButton")
rainButton.Size = UDim2.new(1, -40, 0, 55)
rainButton.Position = UDim2.new(0, 20, 1, -70)
rainButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
rainButton.Text = "☔ MAKE IT RAIN ☔"
rainButton.Font = Enum.Font.GothamBold
rainButton.TextSize = 20
rainButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rainButton.Parent = mainContainer
Instance.new("UICorner", rainButton).CornerRadius = UDim.new(0, 16)

-- Button pulse effect
local pulse = Instance.new("Frame")
pulse.Size = UDim2.new(1, 10, 1, 10)
pulse.Position = UDim2.new(0, -5, 0, -5)
pulse.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
pulse.BackgroundTransparency = 0.5
pulse.Parent = rainButton
Instance.new("UICorner", pulse).CornerRadius = UDim.new(0, 18)

task.spawn(function()
    while true do
        TweenService:Create(pulse, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Size = UDim2.new(1, 20, 1, 20),
            Position = UDim2.new(0, -10, 0, -10),
            BackgroundTransparency = 1
        }):Play()
        task.wait(1)
        TweenService:Create(pulse, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Size = UDim2.new(1, 10, 1, 10),
            Position = UDim2.new(0, -5, 0, -5),
            BackgroundTransparency = 0.5
        }):Play()
        task.wait(1)
    end
end)

-- Status label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -40, 0, 20)
statusLabel.Position = UDim2.new(0, 20, 1, -25)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Ready to rain!"
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.TextColor3 = Color3.fromRGB(180, 180, 220)
statusLabel.Parent = mainContainer

-- ==============================================
-- ANIMATION FUNCTIONS
-- ==============================================

local activePets = {}
local isRaining = false

-- Animation functions (simplified but working)
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

-- Create rain pet function
local function createRainPet()
    if #AllPets == 0 then return end
    
    local petData = AllPets[math.random(1, #AllPets)]
    
    -- Create properties based on selection
    local properties = {
        pet_trick_level = 5,
        age = math.random(1, 6),
        rp_name = GenerateUniquePetName(),
        flyable = selectedPotion ~= "regular",
        rideable = selectedPotion ~= "regular",
        mega_neon = selectedPotion == "mfr",
        neon = selectedPotion == "nfr" or selectedPotion == "mfr",
    }
    
    -- Create inventory item
    if ClientData and petData.id then
        CreateRainInventoryItem(petData.id, "pets", properties)
    end
    
    -- Create model (simplified placeholder)
    local model = Instance.new("Model")
    local part = Instance.new("Part")
    
    -- Size based on potion type
    part.Size = selectedPotion == "mfr" and Vector3.new(3, 3, 3) or 
                selectedPotion == "nfr" and Vector3.new(2.5, 2.5, 2.5) or 
                Vector3.new(2, 2, 2)
    
    -- Color based on potion type
    part.BrickColor = selectedPotion == "mfr" and BrickColor.new("Really red") or
                      selectedPotion == "nfr" and BrickColor.new("Bright green") or
                      selectedPotion == "fr" and BrickColor.new("Bright blue") or
                      BrickColor.new("Bright yellow")
    
    if selectedPotion == "mfr" or selectedPotion == "nfr" then
        part.Material = Enum.Material.Neon
    end
    
    part.Parent = model
    model.PrimaryPart = part
    
    -- Add glow for neon/mega
    if selectedPotion == "mfr" or selectedPotion == "nfr" then
        local pointLight = Instance.new("PointLight")
        pointLight.Range = 15
        pointLight.Brightness = 3
        pointLight.Color = selectedPotion == "mfr" and Color3.fromHSV(math.random(), 1, 1) or Color3.fromRGB(0, 255, 0)
        pointLight.Parent = part
        
        if selectedPotion == "mfr" then
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
    
    -- Name tag
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 150, 0, 70)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Parent = part
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 0.6, 0)
    text.BackgroundTransparency = 1
    text.Text = petData.name
    text.TextColor3 = Color3.fromRGB(255, 255, 255)
    text.TextScaled = true
    text.Font = Enum.Font.GothamBold
    text.Parent = billboard
    
    local potionTag = Instance.new("TextLabel")
    potionTag.Size = UDim2.new(1, 0, 0.4, 0)
    potionTag.Position = UDim2.new(0, 0, 0.6, 0)
    potionTag.BackgroundTransparency = 1
    potionTag.Text = selectedPotion == "mfr" and "🌈 MFR" or 
                     selectedPotion == "nfr" and "🌟 NFR" or 
                     selectedPotion == "fr" and "🪽 FR" or "⚪ REG"
    potionTag.TextColor3 = selectedPotion == "mfr" and Color3.fromRGB(255, 0, 255) or
                           selectedPotion == "nfr" and Color3.fromRGB(0, 255, 0) or
                           selectedPotion == "fr" and Color3.fromRGB(0, 200, 255) or
                           Color3.fromRGB(200, 200, 200)
    potionTag.Font = Enum.Font.GothamBold
    potionTag.TextScaled = true
    potionTag.Parent = billboard
    
    -- Position at top
    local camera = workspace.CurrentCamera
    local viewportSize = camera.ViewportSize
    local randomX = math.random(100, viewportSize.X - 100)
    local ray = camera:ViewportPointToRay(randomX, -50)
    local spawnPos = ray.Origin + ray.Direction * 100
    
    model.Parent = workspace
    model:SetPrimaryPartCFrame(CFrame.new(spawnPos) * CFrame.Angles(0, math.random(0, 360), 0))
    
    -- Trail
    local trail = Instance.new("Trail")
    trail.Attachment0 = Instance.new("Attachment", part)
    trail.Attachment1 = Instance.new("Attachment", part)
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
    trail.Lifetime = 0.5
    trail.Parent = part
    
    -- Animation
    local animConnection = nil
    local selectedAnim = currentAnim == "Random" and animOptions[math.random(2, #animOptions)] or currentAnim
    
    if selectedAnim == "Spin" then animConnection = applySpin(model, speedValue)
    elseif selectedAnim == "Bounce" then animConnection = applyBounce(model, speedValue)
    elseif selectedAnim == "Float" then animConnection = applyFloat(model, speedValue)
    elseif selectedAnim == "Tumble" then animConnection = applyTumble(model, speedValue)
    elseif selectedAnim == "Twirl" then animConnection = applyTwirl(model, speedValue)
    elseif selectedAnim == "Wave" then animConnection = applyWave(model, speedValue)
    end
    
    -- Falling tween
    local targetPos = spawnPos - Vector3.new(0, 300, 0)
    local fallTime = 2 / (speedValue / 5)
    
    local tween = TweenService:Create(model, TweenInfo.new(fallTime, Enum.EasingStyle.Quad), {
        CFrame = CFrame.new(targetPos) * CFrame.Angles(0, math.random(0, 360), 0)
    })
    
    tween:Play()
    
    -- Clean up
    local petId = tostring(math.random())
    activePets[petId] = model
    
    tween.Completed:Connect(function()
        if animConnection then animConnection:Disconnect() end
        if model then
            for _, p in pairs(model:GetDescendants()) do
                if p:IsA("BasePart") then
                    TweenService:Create(p, TweenInfo.new(1), {Transparency = 1}):Play()
                end
            end
            task.wait(1)
            model:Destroy()
            activePets[petId] = nil
        end
    end)
    
    Debris:AddItem(model, 10)
end

-- Rain function
local function startRain()
    if isRaining then return end
    isRaining = true
    
    local potionNames = {mfr = "MFR", nfr = "NFR", fr = "FR", regular = "Regular"}
    statusLabel.Text = "Raining " .. petCountValue .. " " .. potionNames[selectedPotion] .. " pets..."
    
    for i = 1, petCountValue do
        createRainPet()
        if i < petCountValue then task.wait(0.1) end
    end
    
    statusLabel.Text = "Done! (" .. petCountValue .. " pets)"
    task.wait(2)
    statusLabel.Text = "Ready to rain!"
    isRaining = false
end

-- ==============================================
-- EVENT HANDLERS
-- ==============================================

-- Slider dragging
local draggingSlider = nil
local petCountValue = 15

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
            petCountValue = math.floor(1 + percent * 49)
            countLabel.Text = "Pet Count: " .. petCountValue
        elseif draggingSlider == speedSlider then
            speedFill.Size = UDim2.new(percent, 0, 1, 0)
            speedValue = 1 + percent * 9
            speedLabel.Text = "Speed: " .. math.floor(speedValue * 10) / 10
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingSlider = nil
    end
end)

-- Animation dropdown
animDropdown.MouseButton1Click:Connect(function()
    local menu = Instance.new("Frame")
    menu.Size = UDim2.new(1, 0, 0, #animOptions * 30)
    menu.Position = UDim2.new(0, 0, 1, 5)
    menu.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    menu.Parent = animDropdown
    Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 6)
    
    for i, animName in ipairs(animOptions) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 25)
        btn.Position = UDim2.new(0, 5, 0, (i-1) * 30 + 2)
        btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
        btn.Text = animName
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 12
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Parent = menu
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        
        btn.MouseButton1Click:Connect(function()
            currentAnim = animName
            animDropdown.Text = animName
            animLabel.Text = "Animation: " .. animName
            menu:Destroy()
        end)
    end
    
    local connection
    connection = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local pos = UserInputService:GetMouseLocation()
            local absPos = menu.AbsolutePosition
            local size = menu.AbsoluteSize
            
            if pos.X < absPos.X or pos.X > absPos.X + size.X or
               pos.Y < absPos.Y or pos.Y > absPos.Y + size.Y then
                menu:Destroy()
                connection:Disconnect()
            end
        end
    end)
end)

-- Close button
closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    if blurEffect then blurEffect:Destroy() end
end)

-- Rain button
rainButton.MouseButton1Click:Connect(startRain)

-- Initialize with regular selected
selectedPotion = "regular"
updateCardSelection()

print("✅ Premium Rain Pet GUI loaded!")
print("📊 Available pets: " .. #AllPets)
print("🌈 Select MFR, NFR, FR, or Regular from the cards!")