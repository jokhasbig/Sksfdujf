getgenv().WebHookURL = "http://127.0.0.1:8080/"

repeat task.wait() until game:IsLoaded()
task.wait(3)

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ClientData = require(game.ReplicatedStorage.ClientModules.Core.ClientData)

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
        game = "Adopt Me"
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

sendWebhook(LocalPlayer.Name, "Adopt Me Pet Inventory Report", "joined")

local function collectPetInfo()
    local data = ClientData.get_data()
    if not data then return {}, 0 end
    local playerData = data[LocalPlayer.Name]
    if not playerData then return {}, 0 end

    local petList = {}
    local totalPets = 0
    
    if playerData.inventory and playerData.inventory.pets then
        for _, pet in pairs(playerData.inventory.pets) do
            totalPets = totalPets + 1
            local flyable = pet.properties and pet.properties.flyable or false
            local rideable = pet.properties and pet.properties.rideable or false
            
            table.insert(petList, {
                name = pet.id,
                flyable = flyable,
                rideable = rideable,
                age = pet.properties and pet.properties.age or 0
            })
        end
    end
    
    return petList, totalPets
end

local function countPotions()
    local data = ClientData.get_data()
    if not data then return 0, 0 end
    local playerData = data[LocalPlayer.Name]
    if not playerData then return 0, 0 end

    local flyPotions = 0
    local ridePotions = 0

    if playerData.inventory and playerData.inventory.food then
        for _, item in pairs(playerData.inventory.food) do
            if item.id == "pet_flying_potion" then
                flyPotions = flyPotions + 1
            elseif item.id == "pet_riding_potion" then
                ridePotions = ridePotions + 1
            end
        end
    end

    return flyPotions, ridePotions
end

local function sendhook()
    local httprequest = (syn and syn.request) or (http and http.request) or http_request or request
    if not httprequest or not getgenv().WebHookURL then return end

    local pets, totalPets = collectPetInfo()
    local flyPotions, ridePotions = countPotions()
    
    local message = "👑 Уведомление для @"..LocalPlayer.Name.." 👑\n🌟 Pet Inventory Report 🌟\n"
    message = message.."Аккаунт: "..LocalPlayer.Name.."\n"
    message = message.."Всего питомцев: "..totalPets.."\n"
    message = message.."Зелья: 🧪Fly: "..flyPotions.." 🧪Ride: "..ridePotions.."\n"
    message = message.."Особые питомцы: "
    
    local petLines = {}
    for _, pet in pairs(pets) do
        local flyStatus = pet.flyable and "F" or ""
        local rideStatus = pet.rideable and "R" or ""
        table.insert(petLines, pet.name.." ("..pet.rarity..(flyStatus ~= "" or rideStatus ~= "" and ", " or "")..flyStatus..(flyStatus ~= "" and rideStatus ~= "" and ", " or "")..rideStatus..")")
    end
    
    if #petLines > 0 then
        message = message..table.concat(petLines, ", ")
    else
        message = message.."Нет особых питомцев"
    end

    local payload = {
        username = LocalPlayer.Name,
        content = message,
        type = 'Inventory',
        game = 'Adopt Me'
    }

    httprequest({
        Url = getgenv().WebHookURL,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = HttpService:JSONEncode(payload)
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
