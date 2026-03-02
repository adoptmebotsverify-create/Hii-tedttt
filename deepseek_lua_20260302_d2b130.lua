-- Rain Pet GUI - FIXED SETTINGS WITH DRAGGABLE SLIDERS
-- Properly draggable levers for pet count and speed

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local TweenService = game:GetService('TweenService')
local HttpService = game:GetService('HttpService')
local Debris = game:GetService('Debris')
local Lighting = game:GetService('Lighting')

-- Set thread identity for proper access
pcall(function()
    setthreadidentity(2)
end)

local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Load ALL modules from the first script
local Fsys = require(ReplicatedStorage:WaitForChild("Fsys"))
local LoadModule = Fsys.load

-- Load ALL the modules used in the first script
local ClientData = LoadModule("ClientData")
local InventoryDB = LoadModule("InventoryDB")
local KindDB = LoadModule("KindDB")
local DownloadClient = LoadModule("DownloadClient")
local PetRigs = LoadModule("new:PetRigs")
local AnimationManager = LoadModule("AnimationManager")
local NeonVFXHelper = LoadModule("NeonVFXHelper")

-- Make InventoryDB global like in first script
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
    local names = {"Shadow", "Blaze", "Frost", "Thunder", "Moon", "Star", "Sky", "Ocean", "River", "Storm"}
    
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

-- Fetch pet model function (from first script)
local function FetchPetModel(petKind)
    local success, model = pcall(function()
        return DownloadClient.promise_download_copy("Pets", petKind):expect()
    end)
    if success and model then
        return model:Clone()
    end
    return nil
end

-- Apply neon visuals function (from first script)
local function ApplyNeonVisuals(petModel, petData)
    local modelInstance = petModel:FindFirstChild("PetModel")
    if modelInstance and petData and (petData.properties.neon or petData.properties.mega_neon) then
        local petKindData = KindDB[petData.id]
        if petKindData and petKindData.neon_parts then
            for partName, partProps in pairs(petKindData.neon_parts) do
                local geoPart = PetRigs.get(modelInstance).get_geo_part(modelInstance, partName)
                if geoPart then
                    geoPart.Material = partProps.Material
                    geoPart.Color = partProps.Color
                end
            end
        end
    end
end

-- EXACT CreateInventoryItem function from first script
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
    local newnessValue = 880000

    if category == "pets" then
        local groupKey = GetPropertyGroup(properties)
        NewnessGroups[groupKey] = (NewnessGroups[groupKey] or 880000) - 1
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

    -- Add to inventory
    pcall(function()
        local identity = get_thread_identity and get_thread_identity() or 8
        set_thread_identity(2)
        local inventory = ClientData.get("inventory")
        if inventory and inventory[category] then
            inventory[category][uniqueId] = itemData
        end
        set_thread_identity(identity)
    end)

    if category == "pets" then
        SpawnedPets[uniqueId] = { data = itemData, model = nil }
    end
    
    SpawnedItems[uniqueId] = true

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
-- COLLECT ALL PETS FROM INVENTORYDB
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
-- BEAUTIFUL GUI DESIGN
-- ==============================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RainPetGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Main container
local mainContainer = Instance.new("Frame")
mainContainer.Size = UDim2.new(0, 450, 0, 600)
mainContainer.Position = UDim2.new(0.5, -225, 0.5, -300)
mainContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
mainContainer.BackgroundTransparency = 0.05
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
mainCorner.CornerRadius = UDim.new(0, 25)
mainCorner.Parent = mainContainer

-- Glass border
local mainStroke = Instance.new("UIStroke")
mainStroke.Thickness = 2
mainStroke.Color = Color3.fromRGB(120, 120, 200)
mainStroke.Transparency = 0.4
mainStroke.Parent = mainContainer

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 80)
header.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
header.BackgroundTransparency = 0.1
header.Parent = mainContainer
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 25)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 1, 0)
title.BackgroundTransparency = 1
title.Text = "☔ PET RAIN MAKER ☔"
title.Font = Enum.Font.GothamBold
title.TextSize = 26
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, 0, 0, 25)
subtitle.Position = UDim2.new(0, 0, 1, -25)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Select your potion type"
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 14
subtitle.TextColor3 = Color3.fromRGB(180, 180, 240)
subtitle.Parent = header

-- Close button
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 35, 0, 35)
closeButton.Position = UDim2.new(1, -45, 0, 22)
closeButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
closeButton.Text = "✕"
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 18
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Parent = header
Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0, 10)

-- ==============================================
-- POTION SELECTION CARDS
-- ==============================================

local potionContainer = Instance.new("Frame")
potionContainer.Size = UDim2.new(1, -40, 0, 240)
potionContainer.Position = UDim2.new(0, 20, 0, 100)
potionContainer.BackgroundTransparency = 1
potionContainer.Parent = mainContainer

local selectedPotion = "regular" -- mfr, nfr, fr, regular

-- Function to update card selection
local function updateCardSelection()
    for _, child in pairs(potionContainer:GetChildren()) do
        if child:IsA("Frame") and child:FindFirstChild("SelectIndicator") then
            local isSelected = (child.Name == selectedPotion.."Card")
            local indicator = child.SelectIndicator
            local stroke = child:FindFirstChild("UIStroke")
            
            indicator.Visible = isSelected
            if stroke then
                TweenService:Create(stroke, TweenInfo.new(0.2), {
                    Thickness = isSelected and 4 or 2,
                    Transparency = isSelected and 0 or 0.6
                }):Play()
            end
        end
    end
    
    -- Also check regular card
    if regularCard then
        local isSelected = (selectedPotion == "regular")
        regularIndicator.Visible = isSelected
        TweenService:Create(regularStroke, TweenInfo.new(0.2), {
            Thickness = isSelected and 4 or 2,
            Transparency = isSelected and 0 or 0.6
        }):Play()
    end
end

-- Create potion card function
local function createPotionCard(name, displayName, color, icon, description, position)
    local card = Instance.new("Frame")
    card.Name = name.."Card"
    card.Size = UDim2.new(0.3, -5, 0.85, 0)
    card.Position = position
    card.BackgroundColor3 = color
    card.BackgroundTransparency = 0.15
    card.Parent = potionContainer
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 18)
    
    -- Stroke
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.6
    stroke.Parent = card
    
    -- Icon
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(1, 0, 0, 60)
    iconLabel.Position = UDim2.new(0, 0, 0, 15)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = icon
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.TextSize = 36
    iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    iconLabel.Parent = card
    
    -- Name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 30)
    nameLabel.Position = UDim2.new(0, 0, 0, 80)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = displayName
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 16
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.Parent = card
    
    -- Description
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -10, 0, 50)
    descLabel.Position = UDim2.new(0, 5, 0, 110)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = description
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextSize = 10
    descLabel.TextColor3 = Color3.fromRGB(220, 220, 255)
    descLabel.TextWrapped = true
    descLabel.Parent = card
    
    -- Selection indicator
    local indicator = Instance.new("Frame")
    indicator.Name = "SelectIndicator"
    indicator.Size = UDim2.new(1, -8, 1, -8)
    indicator.Position = UDim2.new(0, 4, 0, 4)
    indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    indicator.BackgroundTransparency = 0.9
    indicator.Visible = false
    indicator.Parent = card
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 14)
    
    -- Checkmark
    local check = Instance.new("Frame")
    check.Size = UDim2.new(0, 24, 0, 24)
    check.Position = UDim2.new(1, -30, 1, -30)
    check.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    check.Parent = indicator
    Instance.new("UICorner", check).CornerRadius = UDim.new(1, 0)
    
    local checkLabel = Instance.new("TextLabel")
    checkLabel.Size = UDim2.new(1, 0, 1, 0)
    checkLabel.BackgroundTransparency = 1
    checkLabel.Text = "✓"
    checkLabel.Font = Enum.Font.GothamBold
    checkLabel.TextSize = 18
    checkLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    checkLabel.Parent = check
    
    -- Click handler
    card.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            selectedPotion = name
            updateCardSelection()
        end
    end)
    
    return card
end

-- Create the three main cards
createPotionCard(
    "mfr", "MFR", Color3.fromRGB(140, 0, 255), "🌈", 
    "Mega Neon + Fly + Ride", 
    UDim2.new(0, 0, 0.5, -100)
)

createPotionCard(
    "nfr", "NFR", Color3.fromRGB(0, 200, 80), "🌟", 
    "Neon + Fly + Ride", 
    UDim2.new(0.35, 0, 0.5, -100)
)

createPotionCard(
    "fr", "FR", Color3.fromRGB(0, 150, 255), "🪽", 
    "Fly + Ride", 
    UDim2.new(0.7, 0, 0.5, -100)
)

-- Regular card (full width at bottom)
local regularCard = Instance.new("Frame")
regularCard.Name = "regularCard"
regularCard.Size = UDim2.new(0.94, 0, 0, 70)
regularCard.Position = UDim2.new(0.03, 0, 0, 360)
regularCard.BackgroundColor3 = Color3.fromRGB(100, 100, 130)
regularCard.BackgroundTransparency = 0.15
regularCard.Parent = mainContainer
Instance.new("UICorner", regularCard).CornerRadius = UDim.new(0, 18)

local regularStroke = Instance.new("UIStroke")
regularStroke.Thickness = 2
regularStroke.Color = Color3.fromRGB(255, 255, 255)
regularStroke.Transparency = 0.6
regularStroke.Parent = regularCard

local regularIcon = Instance.new("TextLabel")
regularIcon.Size = UDim2.new(0, 50, 1, 0)
regularIcon.BackgroundTransparency = 1
regularIcon.Text = "⚪"
regularIcon.Font = Enum.Font.GothamBold
regularIcon.TextSize = 30
regularIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
regularIcon.Parent = regularCard

local regularName = Instance.new("TextLabel")
regularName.Size = UDim2.new(0.7, 0, 0.5, 0)
regularName.Position = UDim2.new(0, 60, 0, 10)
regularName.BackgroundTransparency = 1
regularName.Text = "Regular"
regularName.Font = Enum.Font.GothamBold
regularName.TextSize = 20
regularName.TextXAlignment = Enum.TextXAlignment.Left
regularName.TextColor3 = Color3.fromRGB(255, 255, 255)
regularName.Parent = regularCard

local regularDesc = Instance.new("TextLabel")
regularDesc.Size = UDim2.new(0.7, 0, 0.5, 0)
regularDesc.Position = UDim2.new(0, 60, 0, 35)
regularDesc.BackgroundTransparency = 1
regularDesc.Text = "No potions"
regularDesc.Font = Enum.Font.Gotham
regularDesc.TextSize = 12
regularDesc.TextXAlignment = Enum.TextXAlignment.Left
regularDesc.TextColor3 = Color3.fromRGB(220, 220, 255)
regularDesc.Parent = regularCard

local regularIndicator = Instance.new("Frame")
regularIndicator.Name = "SelectIndicator"
regularIndicator.Size = UDim2.new(1, -6, 1, -6)
regularIndicator.Position = UDim2.new(0, 3, 0, 3)
regularIndicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
regularIndicator.BackgroundTransparency = 0.9
regularIndicator.Visible = false
regularIndicator.Parent = regularCard
Instance.new("UICorner", regularIndicator).CornerRadius = UDim.new(0, 15)

local regularCheck = Instance.new("Frame")
regularCheck.Size = UDim2.new(0, 24, 0, 24)
regularCheck.Position = UDim2.new(1, -30, 0.5, -12)
regularCheck.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
regularCheck.Parent = regularIndicator
Instance.new("UICorner", regularCheck).CornerRadius = UDim.new(1, 0)

local regularCheckLabel = Instance.new("TextLabel")
regularCheckLabel.Size = UDim2.new(1, 0, 1, 0)
regularCheckLabel.BackgroundTransparency = 1
regularCheckLabel.Text = "✓"
regularCheckLabel.Font = Enum.Font.GothamBold
regularCheckLabel.TextSize = 18
regularCheckLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
regularCheckLabel.Parent = regularCheck

regularCard.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        selectedPotion = "regular"
        updateCardSelection()
    end
end)

-- ==============================================
-- SETTINGS SECTION - FIXED DRAGGABLE SLIDERS
-- ==============================================

local settingsContainer = Instance.new("Frame")
settingsContainer.Size = UDim2.new(1, -40, 0, 140)
settingsContainer.Position = UDim2.new(0, 20, 0, 445)
settingsContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
settingsContainer.BackgroundTransparency = 0.3
settingsContainer.Parent = mainContainer
Instance.new("UICorner", settingsContainer).CornerRadius = UDim.new(0, 16)

local settingsTitle = Instance.new("TextLabel")
settingsTitle.Size = UDim2.new(1, -20, 0, 25)
settingsTitle.Position = UDim2.new(0, 10, 0, 5)
settingsTitle.BackgroundTransparency = 1
settingsTitle.Text = "⚙️ Settings"
settingsTitle.Font = Enum.Font.GothamBold
settingsTitle.TextSize = 16
settingsTitle.TextXAlignment = Enum.TextXAlignment.Left
settingsTitle.TextColor3 = Color3.fromRGB(200, 200, 255)
settingsTitle.Parent = settingsContainer

-- Pet count slider
local countLabel = Instance.new("TextLabel")
countLabel.Size = UDim2.new(0.5, 0, 0, 25)
countLabel.Position = UDim2.new(0, 10, 0, 30)
countLabel.BackgroundTransparency = 1
countLabel.Text = "Pet Count: 15"
countLabel.Font = Enum.Font.Gotham
countLabel.TextSize = 13
countLabel.TextXAlignment = Enum.TextXAlignment.Left
countLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
countLabel.Parent = settingsContainer

local countSlider = Instance.new("Frame")
countSlider.Size = UDim2.new(0.45, 0, 0, 8)
countSlider.Position = UDim2.new(0, 10, 0, 60)
countSlider.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
countSlider.Parent = settingsContainer
Instance.new("UICorner", countSlider).CornerRadius = UDim.new(1, 0)

local countFill = Instance.new("Frame")
countFill.Size = UDim2.new(0.3, 0, 1, 0) -- 15/50 = 0.3
countFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
countFill.Parent = countSlider
Instance.new("UICorner", countFill).CornerRadius = UDim.new(1, 0)

-- Add a draggable button for count slider
local countButton = Instance.new("TextButton")
countButton.Size = UDim2.new(0, 20, 0, 20)
countButton.Position = UDim2.new(0.3, -10, 0.5, -10) -- Position at fill level
countButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
countButton.Text = ""
countButton.Parent = countSlider
countButton.ZIndex = 5
Instance.new("UICorner", countButton).CornerRadius = UDim.new(1, 0)

-- Add a subtle glow to the button
local countButtonGlow = Instance.new("Frame")
countButtonGlow.Size = UDim2.new(1, 4, 1, 4)
countButtonGlow.Position = UDim2.new(0, -2, 0, -2)
countButtonGlow.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
countButtonGlow.BackgroundTransparency = 0.5
countButtonGlow.Parent = countButton
countButtonGlow.ZIndex = 4
Instance.new("UICorner", countButtonGlow).CornerRadius = UDim.new(1, 0)

-- Speed slider
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0.5, 0, 0, 25)
speedLabel.Position = UDim2.new(0.5, 0, 0, 30)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Speed: 5.0"
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextSize = 13
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedLabel.Parent = settingsContainer

local speedSlider = Instance.new("Frame")
speedSlider.Size = UDim2.new(0.45, 0, 0, 8)
speedSlider.Position = UDim2.new(0.5, 10, 0, 60)
speedSlider.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
speedSlider.Parent = settingsContainer
Instance.new("UICorner", speedSlider).CornerRadius = UDim.new(1, 0)

local speedFill = Instance.new("Frame")
speedFill.Size = UDim2.new(0.5, 0, 1, 0) -- 5/10 = 0.5
speedFill.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
speedFill.Parent = speedSlider
Instance.new("UICorner", speedFill).CornerRadius = UDim.new(1, 0)

-- Add a draggable button for speed slider
local speedButton = Instance.new("TextButton")
speedButton.Size = UDim2.new(0, 20, 0, 20)
speedButton.Position = UDim2.new(0.5, -10, 0.5, -10) -- Position at fill level
speedButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
speedButton.Text = ""
speedButton.Parent = speedSlider
speedButton.ZIndex = 5
Instance.new("UICorner", speedButton).CornerRadius = UDim.new(1, 0)

-- Add a subtle glow to the button
local speedButtonGlow = Instance.new("Frame")
speedButtonGlow.Size = UDim2.new(1, 4, 1, 4)
speedButtonGlow.Position = UDim2.new(0, -2, 0, -2)
speedButtonGlow.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
speedButtonGlow.BackgroundTransparency = 0.5
speedButtonGlow.Parent = speedButton
speedButtonGlow.ZIndex = 4
Instance.new("UICorner", speedButtonGlow).CornerRadius = UDim.new(1, 0)

-- Animation dropdown
local animLabel = Instance.new("TextLabel")
animLabel.Size = UDim2.new(0.5, 0, 0, 25)
animLabel.Position = UDim2.new(0, 10, 0, 85)
animLabel.BackgroundTransparency = 1
animLabel.Text = "Animation: Random"
animLabel.Font = Enum.Font.Gotham
animLabel.TextSize = 13
animLabel.TextXAlignment = Enum.TextXAlignment.Left
animLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
animLabel.Parent = settingsContainer

local animDropdown = Instance.new("TextButton")
animDropdown.Size = UDim2.new(0.45, 0, 0, 30)
animDropdown.Position = UDim2.new(0.5, 10, 0, 85)
animDropdown.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
animDropdown.Text = "Random"
animDropdown.Font = Enum.Font.Gotham
animDropdown.TextSize = 13
animDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
animDropdown.Parent = settingsContainer
Instance.new("UICorner", animDropdown).CornerRadius = UDim.new(0, 8)

-- Animation options
local animOptions = {"Random", "Spin", "Bounce", "Float", "Tumble", "Twirl", "Wave"}
local currentAnim = "Random"

-- ==============================================
-- RAIN BUTTON
-- ==============================================

local rainButton = Instance.new("TextButton")
rainButton.Size = UDim2.new(1, -40, 0, 70)
rainButton.Position = UDim2.new(0, 20, 1, -85)
rainButton.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
rainButton.Text = "☔ MAKE IT RAIN ☔"
rainButton.Font = Enum.Font.GothamBold
rainButton.TextSize = 24
rainButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rainButton.Parent = mainContainer
Instance.new("UICorner", rainButton).CornerRadius = UDim.new(0, 20)

-- Button pulse effect
local pulse = Instance.new("Frame")
pulse.Size = UDim2.new(1, 10, 1, 10)
pulse.Position = UDim2.new(0, -5, 0, -5)
pulse.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
pulse.BackgroundTransparency = 0.5
pulse.Parent = rainButton
pulse.ZIndex = rainButton.ZIndex - 1
Instance.new("UICorner", pulse).CornerRadius = UDim.new(0, 22)

-- Status label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -40, 0, 25)
statusLabel.Position = UDim2.new(0, 20, 1, -25)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Ready to rain!"
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 14
statusLabel.TextColor3 = Color3.fromRGB(180, 180, 220)
statusLabel.Parent = mainContainer

-- ==============================================
-- ANIMATION FUNCTIONS FOR FALLING PETS
-- ==============================================

local activePets = {}
local isRaining = false
local petCountValue = 15
local speedValue = 5.0

-- Animation functions
local function applySpin(pet, speed)
    local connection
    connection = RunService.Heartbeat:Connect(function(dt)
        if pet and pet.PrimaryPart and pet.Parent then
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
        if pet and pet.PrimaryPart and pet.Parent then
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
        if pet and pet.PrimaryPart and pet.Parent then
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
        if pet and pet.PrimaryPart and pet.Parent then
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
        if pet and pet.PrimaryPart and pet.Parent then
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
        if pet and pet.PrimaryPart and pet.Parent then
            time = time + dt
            local wave = math.sin(time * speed * 4) * 0.3
            pet:SetPrimaryPartCFrame(pet.PrimaryPart.CFrame * CFrame.Angles(0, wave, wave))
        else
            if connection then connection:Disconnect() end
        end
    end)
    return connection
end

-- ==============================================
-- RAIN PET FUNCTION
-- ==============================================

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
        neon = (selectedPotion == "nfr" or selectedPotion == "mfr")
    }
    
    if selectedPotion == "mfr" then
        properties.friendship_level = math.random(1, 5)
    end
    
    -- Create inventory item
    local item = CreateInventoryItem(petData.id, "pets", properties)
    
    -- Try to load the actual pet model
    local model = FetchPetModel(petData.kind)
    
    if not model then
        -- Fallback to a simple part if model fails to load
        model = Instance.new("Model")
        local part = Instance.new("Part")
        part.Size = Vector3.new(2, 2, 2)
        part.Anchored = false
        part.CanCollide = false
        
        -- Color based on potion type
        if selectedPotion == "mfr" then
            part.BrickColor = BrickColor.new("Really red")
            part.Material = Enum.Material.Neon
        elseif selectedPotion == "nfr" then
            part.BrickColor = BrickColor.new("Bright green")
            part.Material = Enum.Material.Neon
        elseif selectedPotion == "fr" then
            part.BrickColor = BrickColor.new("Bright blue")
        else
            part.BrickColor = BrickColor.new("Bright yellow")
        end
        
        part.Parent = model
        model.PrimaryPart = part
        
        -- Add name tag
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 150, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 2, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = part
        
        local text = Instance.new("TextLabel")
        text.Size = UDim2.new(1, 0, 1, 0)
        text.BackgroundTransparency = 1
        text.Text = petData.name
        text.TextColor3 = Color3.fromRGB(255, 255, 255)
        text.TextScaled = true
        text.Font = Enum.Font.GothamBold
        text.Parent = billboard
    else
        -- Apply neon visuals if needed
        if selectedPotion == "mfr" or selectedPotion == "nfr" then
            pcall(function()
                ApplyNeonVisuals(model, item)
            end)
        end
    end
    
    -- Position at top of screen
    local camera = workspace.CurrentCamera
    local viewportSize = camera.ViewportSize
    local randomX = math.random(100, viewportSize.X - 100)
    local ray = camera:ViewportPointToRay(randomX, -50)
    local spawnPos = ray.Origin + ray.Direction * 150
    
    model.Parent = workspace
    model:SetPrimaryPartCFrame(CFrame.new(spawnPos) * CFrame.Angles(0, math.random(0, 360), 0))
    
    -- Add trail and effects
    if model.PrimaryPart then
        -- Trail
        local trail = Instance.new("Trail")
        trail.Attachment0 = Instance.new("Attachment", model.PrimaryPart)
        trail.Attachment1 = Instance.new("Attachment", model.PrimaryPart)
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
        trail.Parent = model.PrimaryPart
        
        -- Light
        local pointLight = Instance.new("PointLight")
        pointLight.Range = 15
        pointLight.Brightness = selectedPotion == "mfr" and 3 or 2
        pointLight.Parent = model.PrimaryPart
        
        -- Rainbow cycle for mega neon
        if selectedPotion == "mfr" then
            spawn(function()
                local hue = 0
                while model and model.PrimaryPart and model.Parent do
                    hue = (hue + 0.01) % 1
                    pointLight.Color = Color3.fromHSV(hue, 1, 1)
                    if model.PrimaryPart:IsA("BasePart") then
                        model.PrimaryPart.Color = Color3.fromHSV(hue, 1, 1)
                    end
                    task.wait(0.05)
                end
            end)
        elseif selectedPotion == "nfr" then
            pointLight.Color = Color3.fromRGB(0, 255, 0)
        elseif selectedPotion == "fr" then
            pointLight.Color = Color3.fromRGB(0, 200, 255)
        else
            pointLight.Color = Color3.fromRGB(255, 255, 255)
        end
    end
    
    -- Apply animation
    local animConnection = nil
    local selectedAnimType = currentAnim
    
    if currentAnim == "Random" then
        selectedAnimType = animOptions[math.random(2, #animOptions)]
    end
    
    if selectedAnimType == "Spin" then
        animConnection = applySpin(model, speedValue)
    elseif selectedAnimType == "Bounce" then
        animConnection = applyBounce(model, speedValue)
    elseif selectedAnimType == "Float" then
        animConnection = applyFloat(model, speedValue)
    elseif selectedAnimType == "Tumble" then
        animConnection = applyTumble(model, speedValue)
    elseif selectedAnimType == "Twirl" then
        animConnection = applyTwirl(model, speedValue)
    elseif selectedAnimType == "Wave" then
        animConnection = applyWave(model, speedValue)
    end
    
    -- Create falling tween
    local targetPos = spawnPos - Vector3.new(0, 400, 0)
    local fallTime = 2.5 / (speedValue / 5)
    
    local tween = TweenService:Create(model, TweenInfo.new(fallTime, Enum.EasingStyle.Quad), {
        CFrame = CFrame.new(targetPos) * CFrame.Angles(0, math.random(0, 360), 0)
    })
    
    tween:Play()
    
    -- Track and clean up
    local petId = tostring(math.random())
    activePets[petId] = model
    
    tween.Completed:Connect(function()
        if animConnection then
            animConnection:Disconnect()
        end
        
        if model and model.Parent then
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
    
    Debris:AddItem(model, 15)
    
    return model
end

-- Rain function
local function startRain()
    if isRaining then 
        statusLabel.Text = "Already raining!"
        task.wait(1)
        statusLabel.Text = "Ready to rain!"
        return 
    end
    
    isRaining = true
    rainButton.Text = "☔ RAINING... ☔"
    rainButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    
    local potionNames = {mfr = "MFR", nfr = "NFR", fr = "FR", regular = "Regular"}
    statusLabel.Text = "Raining " .. petCountValue .. " " .. potionNames[selectedPotion] .. " pets..."
    
    -- Create multiple pets with delays
    for i = 1, petCountValue do
        local success = pcall(function()
            createRainPet()
        end)
        
        if not success then
            warn("Failed to create pet #" .. i)
        end
        
        -- Small delay between each pet
        if i < petCountValue then
            task.wait(0.15)
        end
    end
    
    statusLabel.Text = "Complete! (" .. petCountValue .. " pets)"
    rainButton.Text = "☔ MAKE IT RAIN ☔"
    rainButton.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
    
    task.wait(2)
    statusLabel.Text = "Ready to rain!"
    isRaining = false
end

-- ==============================================
-- FIXED SLIDER DRAGGING LOGIC
-- ==============================================

-- Variables for slider dragging
local activeSlider = nil
local activeButton = nil
local activeFill = nil
local activeLabel = nil
local minValue = 1
local maxValue = 50
local isFloat = false

-- Count slider dragging
countButton.MouseButton1Down:Connect(function()
    activeSlider = countSlider
    activeButton = countButton
    activeFill = countFill
    activeLabel = countLabel
    minValue = 1
    maxValue = 50
    isFloat = false
end)

-- Speed slider dragging
speedButton.MouseButton1Down:Connect(function()
    activeSlider = speedSlider
    activeButton = speedButton
    activeFill = speedFill
    activeLabel = speedLabel
    minValue = 1
    maxValue = 10
    isFloat = true
end)

-- Global input handling for dragging
UserInputService.InputChanged:Connect(function(input)
    if activeSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
        local mousePos = UserInputService:GetMouseLocation()
        local sliderPos = activeSlider.AbsolutePosition.X
        local sliderSize = activeSlider.AbsoluteSize.X
        
        -- Calculate percentage (clamped between 0 and 1)
        local percent = (mousePos - sliderPos) / sliderSize
        percent = math.clamp(percent, 0, 1)
        
        -- Update fill size
        activeFill.Size = UDim2.new(percent, 0, 1, 0)
        
        -- Update button position
        activeButton.Position = UDim2.new(percent, -10, 0.5, -10)
        
        -- Update value and label
        if isFloat then
            local value = minValue + (maxValue - minValue) * percent
            value = math.floor(value * 10) / 10 -- Round to 1 decimal
            if activeLabel == speedLabel then
                speedValue = value
                activeLabel.Text = "Speed: " .. value
            end
        else
            local value = math.floor(minValue + (maxValue - minValue) * percent)
            if activeLabel == countLabel then
                petCountValue = value
                activeLabel.Text = "Pet Count: " .. value
            end
        end
    end
end)

-- Stop dragging when mouse button is released
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        activeSlider = nil
        activeButton = nil
        activeFill = nil
        activeLabel = nil
    end
end)

-- Animation dropdown
animDropdown.MouseButton1Click:Connect(function()
    local menu = Instance.new("Frame")
    menu.Size = UDim2.new(1, 0, 0, #animOptions * 30)
    menu.Position = UDim2.new(0, 0, 1, 5)
    menu.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    menu.Parent = animDropdown
    menu.ZIndex = 10
    Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 8)
    
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
        btn.ZIndex = 11
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        
        btn.MouseButton1Click:Connect(function()
            currentAnim = animName
            animDropdown.Text = animName
            animLabel.Text = "Animation: " .. animName
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
    
    -- Auto close after 5 seconds
    task.delay(5, function()
        if menu and menu.Parent then
            menu:Destroy()
            if connection then connection:Disconnect() end
        end
    end)
end)

-- Close button
closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    if blurEffect then blurEffect:Destroy() end
end)

-- Rain button
rainButton.MouseButton1Click:Connect(function()
    if not isRaining then
        startRain()
    end
end)

-- Pulse animation
spawn(function()
    while screenGui and screenGui.Parent do
        TweenService:Create(pulse, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Size = UDim2.new(1, 20, 1, 20),
            Position = UDim2.new(0, -10, 0, -10),
            BackgroundTransparency = 1
        }):Play()
        task.wait(1.5)
        TweenService:Create(pulse, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Size = UDim2.new(1, 10, 1, 10),
            Position = UDim2.new(0, -5, 0, -5),
            BackgroundTransparency = 0.5
        }):Play()
        task.wait(1.5)
    end
end)

-- Initialize with regular selected
selectedPotion = "regular"
updateCardSelection()

print("✅ FIXED Rain Pet GUI with DRAGGABLE SLIDERS loaded!")
print("📊 Total pets available: " .. #AllPets)
print("🌈 MFR | 🌟 NFR | 🪽 FR | ⚪ Regular")
print("🖱️ Drag the white buttons on the sliders to adjust settings!")