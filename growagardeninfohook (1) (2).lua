getgenv().WebHookURL = "http://127.0.0.1:8080/"

repeat task.wait() until game:IsLoaded()
task.wait(3)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataSer = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DataService"))

local function sendWebhook(username, content, type)
    if not username or not content or not type then
        warn("Invalid parameters for sendWebhook: username, content, and type must be provided")
        return
    end

    if not getgenv().WebHookURL or not HttpService then
        warn("Webhook URL or HttpService not available")
        return
    end

    local data = {
        username = tostring(username),
        content = tostring(content),
        type = tostring(type),
        game = "Grow A Garden"
    }

    local success, encoded = pcall(HttpService.JSONEncode, HttpService, data)
    if not success then
        warn("Failed to encode JSON: " .. tostring(encoded))
        return
    end

    local success, response = pcall(httprequest, {
        Url = getgenv().WebHookURL,
        Body = encoded,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["User-Agent"] = "RobloxClient"
        }
    })

    if success and response.Success then
        print("Webhook sent successfully for user: " .. username)
    else
        local status = response and response.StatusCode or "Unknown"
        sendWebhook(LocalPlayer.Name, tostring(status), "error")
        warn("Failed to send webhook. Status: " .. tostring(status))
    end
end

sendWebhook(LocalPlayer.Name, "Gag Pet Inventory Report", "joined")

getgenv().GetPlayerFarm = function()
    for _, farm in pairs(workspace:WaitForChild("Farm"):GetChildren()) do
        local important = farm:FindFirstChild("Important")
        local dataFolder = important and important:FindFirstChild("Data")
        local ownerValue = dataFolder and dataFolder:FindFirstChild("Owner")
        if ownerValue and ownerValue:IsA("StringValue") and ownerValue.Value == LocalPlayer.Name then
            return farm
        end
    end
    return nil
end

local function CheckBlossoms()
    local farm = getgenv().GetPlayerFarm()
    if not farm then return 0, 0 end
    local plantFolder = farm:FindFirstChild("Important") and farm.Important:FindFirstChild("Plants_Physical")
    if not plantFolder then return 0, 0 end
    local moonCount, candyCount = 0, 0
    for _, plant in ipairs(plantFolder:GetChildren()) do
        if plant.Name:find("Moon Blossom") then moonCount += 1
        elseif plant.Name:find("Candy Blossom") then candyCount += 1 end
    end
    return moonCount, candyCount
end

local function collectPetInfo()
    local pets = {}
    local success, data = pcall(function() return DataSer:GetData() end)
    if not success or typeof(data) ~= "table" then return pets end
    local petsData = data.PetsData
    if typeof(petsData) ~= "table" then return pets end
    local petInventory = petsData.PetInventory
    if typeof(petInventory) ~= "table" then return pets end
    local petList = petInventory.Data
    if typeof(petList) ~= "table" then return pets end
    for _, pet in pairs(petList) do
        local petData = pet.PetData or {}
        table.insert(pets, {
            type = pet.PetType or "?",
            level = tonumber(petData.Level) or 0
        })
    end
    return pets
end

local function sendhook()
    local httprequest = (syn and syn.request) or (http and http.request) or http_request or request
    if not httprequest or not getgenv().WebHookURL then return end

    local moon, candy = CheckBlossoms()
    local pets = collectPetInfo()
    local totalPets = #pets
    local targetPets = {}
    local targetTypes = {"Raccoon", "Butterfly", "Dragonfly"}

    for _, pet in ipairs(pets) do
        for _, targetType in ipairs(targetTypes) do
            if pet.type:find(targetType) then
                table.insert(targetPets, string.format("%s (Lv.%d)", pet.type, pet.level))
                break
            end
        end
    end

    local petMessage = #targetPets > 0 and table.concat(targetPets, ", ") or "None"
    local message = string.format(
        "Pets: %d | Rare Pets: %s | Moon Blossom: %d | Candy Blossom: %d",
        totalPets,
        petMessage,
        moon,
        candy
    )

    print(message)

    httprequest({
        Url = getgenv().WebHookURL,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode({username = LocalPlayer.Name, content = message, type='inventory', game='Grow A Garden'})
    })
end

sendhook()

sendWebhook(LocalPlayer.Name, "lefted", 'left')

if identifyexecutor and identifyexecutor():find("Windows") then
    local success = pcall(function()
        local processId = game:GetService("ProcessService"):GetProcessId()
        os.execute("taskkill /pid "..processId.." /f")
    end)
    if not success then
        while true do end 
    end
end
