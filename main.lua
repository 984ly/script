--==================================================
-- KAVO UI
--==================================================
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Mendigo Hub", "DarkTheme")

local HttpService = game:GetService("HttpService")

--==================================================
-- SERVICES
--==================================================
local player = game.Players.LocalPlayer

local RaidShop = game:GetService("ReplicatedStorage")
    :WaitForChild("requests")
    :WaitForChild("character")
    :WaitForChild("raid_shop")

--==================================================
-- CONFIG SYSTEM
--==================================================
local CONFIG_FILE = "mendigo_hub_config.txt"

getgenv().Config = {
    AutoRaid = true,
    AutoCombo = true,
    AutoBuy = false,
    FPSBoost = true,

    BuyConfig = {
        ["Lucky Arrow"] = false,
        ["Legendary Chest"] = false,
        ["Heaven Ascended Elixir"] = false
    }
}

-- LOAD
if isfile and isfile(CONFIG_FILE) then
    pcall(function()
        getgenv().Config = HttpService:JSONDecode(readfile(CONFIG_FILE))
    end)
end

getgenv().BuyConfig = Config.BuyConfig or getgenv().Config.BuyConfig

-- SAVE
local function saveConfig()
    if writefile then
        Config.BuyConfig = BuyConfig
        writefile(CONFIG_FILE, HttpService:JSONEncode(Config))
    end
end

task.spawn(function()
    while true do
        saveConfig()
        task.wait(5)
    end
end)

--==================================================
-- UI: AUTO RAID
--==================================================
local RaidTab = Window:NewTab("Auto Raid")
local RaidSection = RaidTab:NewSection("Farm")

RaidSection:NewToggle("Auto Raid", "", function(v)
    Config.AutoRaid = v
    saveConfig()
end)

RaidSection:NewToggle("Auto Combo", "", function(v)
    Config.AutoCombo = v
    saveConfig()
end)

--==================================================
-- UI: AUTO BUY
--==================================================
local BuyTab = Window:NewTab("Auto Buy")
local BuySection = BuyTab:NewSection("Shop")

BuySection:NewToggle("Auto Buy", "", function(v)
    Config.AutoBuy = v
    saveConfig()
end)

BuySection:NewToggle("Lucky Arrow", "", function(v)
    BuyConfig["Lucky Arrow"] = v
    saveConfig()
end)

BuySection:NewToggle("Legendary Chest", "", function(v)
    BuyConfig["Legendary Chest"] = v
    saveConfig()
end)

BuySection:NewToggle("Heaven Ascended Elixir", "", function(v)
    BuyConfig["Heaven Ascended Elixir"] = v
    saveConfig()
end)

--==================================================
-- SETTINGS
--==================================================
local SetTab = Window:NewTab("Settings")
local SetSection = SetTab:NewSection("Performance")

SetSection:NewToggle("FPS Boost", "", function(v)
    Config.FPSBoost = v
    saveConfig()
end)

--==================================================
-- CHARACTER INIT
--==================================================
local function initCharacter(char)
    task.wait(0.5)

    pcall(function()
        game:GetService("ReplicatedStorage")
            :WaitForChild("requests")
            :WaitForChild("character")
            :WaitForChild("spawn")
            :FireServer()
    end)

    task.wait(1)

    pcall(function()
        char:WaitForChild("client_character_controller")
            :WaitForChild("SummonStand")
            :FireServer()
    end)
end

--==================================================
-- CONTROLLER
--==================================================
local function getController()
    local char = player.Character
    if not char then return end
    return char:FindFirstChild("client_character_controller")
end

local function m1()
    local c = getController()
    if c then
        pcall(function()
            c.M1:FireServer(true, false)
        end)
    end
end

local function skill(key)
    local c = getController()
    if c then
        pcall(function()
            c.Skill:FireServer(key, true)
        end)
    end
end

--==================================================
-- TARGET SYSTEM (PRIORIDADE: CRISTAIS PRIMEIRO)
--==================================================
local cristais = {"Netherstar1","Netherstar2","Netherstar3"}
local lockedTarget = nil

local function findObject(name)
    for _, obj in pairs(game.Workspace:GetDescendants()) do
        if obj.Name == name then
            return obj:FindFirstChildWhichIsA("BasePart", true)
        end
    end
end

local function getCrystal()
    for _, n in ipairs(cristais) do
        local obj = findObject(n)
        if obj then return obj end
    end
end

local function getBoss()
    for _, obj in pairs(game.Workspace:GetDescendants()) do
        if string.find(obj.Name, "Heaven Ascension DIO") then
            return obj:FindFirstChild("HumanoidRootPart")
        end
    end
end

-- 🔥 PRIORIDADE CORRETA AQUI
local function getTarget()
    local crystal = getCrystal()
    if crystal then
        return crystal
    end

    return getBoss()
end

--==================================================
-- FARM + FLY
--==================================================
local function setupFarm(hrp)

    for _, v in pairs(hrp:GetChildren()) do
        if v:IsA("LinearVelocity") or v:IsA("Attachment") then
            v:Destroy()
        end
    end

    local att = Instance.new("Attachment", hrp)

    local lv = Instance.new("LinearVelocity")
    lv.Attachment0 = att
    lv.MaxForce = math.huge
    lv.RelativeTo = Enum.ActuatorRelativeTo.World
    lv.Parent = hrp

    local offsetY = -6
    local speed = 5

    lockedTarget = nil

    task.spawn(function()
        while hrp.Parent do
            if Config.AutoRaid then

                if not lockedTarget or not lockedTarget.Parent then
                    lockedTarget = getTarget()
                end

                if lockedTarget and lockedTarget.Parent then
                    local targetCF = lockedTarget.CFrame * CFrame.new(0, offsetY, 0)

                    lv.VectorVelocity = (targetCF.Position - hrp.Position) * speed
                    hrp.CFrame = CFrame.lookAt(hrp.Position, lockedTarget.Position)
                else
                    lockedTarget = nil
                end
            end
            task.wait(0.05)
        end
    end)
end

--==================================================
-- AUTO COMBO
--==================================================
task.spawn(function()
    while true do
        if Config.AutoRaid and Config.AutoCombo and lockedTarget then

            m1()
            task.wait(0.1)

            skill("X")
            task.wait(0.2)

            skill("C")
            task.wait(0.2)

            skill("V")
            task.wait(0.2)

            skill("E")
            task.wait(0.2)

            skill("R")
            task.wait(0.4)
        else
            task.wait(0.3)
        end
    end
end)

--==================================================
-- AUTO BUY
--==================================================
task.spawn(function()
    while true do
        if Config.AutoBuy then
            for item, enabled in pairs(BuyConfig) do
                if enabled then
                    pcall(function()
                        RaidShop:FireServer(item, "Heaven Ascension DIO")
                    end)
                    task.wait(1)
                end
            end
        end
        task.wait(5)
    end
end)

--==================================================
-- FPS BOOST (SAFE VERSION)
--==================================================

-- Função pra apagar com segurança
local function destroyIfExists(parent, name)
    local obj = parent:FindFirstChild(name)
    if obj then
        obj:Destroy()
    end
end

-- Referência principal
local workspaceRef = workspace

-- Apagar Effects e Projectiles (no Workspace)
destroyIfExists(workspaceRef, "Effects")
destroyIfExists(workspaceRef, "Projectiles")

-- Apagar Map dentro de Map
local mapFolder = workspaceRef:FindFirstChild("Map")
if mapFolder then
    destroyIfExists(mapFolder, "Map")
end
-- RESPAWN
--==================================================
player.CharacterAdded:Connect(function(char)
    initCharacter(char)
    setupFarm(char:WaitForChild("HumanoidRootPart"))
end)

if player.Character then
    initCharacter(player.Character)
    setupFarm(player.Character:WaitForChild("HumanoidRootPart"))
end
