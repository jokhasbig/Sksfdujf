getgenv().WebHookURL = "http://127.0.0.1:8080/"

repeat task.wait() until game:IsLoaded()
task.wait(3)

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ClientData = require(game.ReplicatedStorage.ClientModules.Core.ClientData)

-- Единая функция для получения http-запросов
local function getHTTP()
    return (syn and syn.request) or (http and http.request) or http_request or fluxus and fluxus.request or request
end

local httprequest = getHTTP()

local function sendWebhook(username, content, type)
    if not username or not content or not type then
        warn("Invalid parameters for sendWebhook")
        return
    end

    if not getgenv().WebHookURL or not HttpService then
        warn("Webhook configuration error")
        return
    end

    -- Проверка доступности httprequest
    if not httprequest then
        warn("HTTP request function not available")
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
        warn("JSON encode failed: " .. tostring(encoded))
        return
    end

    local result
    success, result = pcall(httprequest, {
        Url = getgenv().WebHookURL,
        Body = encoded,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        }
    })

    if success then
        if result.Success then
            print("Webhook delivered to " .. username)
        else
            warn("Webhook failed. Status: " .. (result.StatusCode or "No status"))
        end
    else
        warn("HTTP request failed: " .. tostring(result))
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

local function sendInventoryReport()
    if not httprequest or not getgenv().WebHookURL then 
        warn("HTTP components missing")
        return 
    end

    local pets, totalPets = collectPetInfo()
    local flyPotions, ridePotions = countPotions()
    
    local message = "👑 Уведомление для @"..LocalPlayer.Name.." 👑\n🌟 Pet Inventory Report 🌟\n"
    message = message.."Аккаунт: "..LocalPlayer.Name.."\n"
    message = message.."Всего питомцев: "..totalPets.."\n"
    message = message.."Зелья: 🧪Fly: "..flyPotions.." 🧪Ride: "..ridePotions.."\n"
    message = message.."Особые питомцы: "
    
    local petLines = {}
    for _, pet in pairs(pets) do
        local traits = {}
        if pet.flyable then table.insert(traits, "F") end
        if pet.rideable then table.insert(traits, "R") end
        
        local traitStr = ""
        if #traits > 0 then
            traitStr = " ("..table.concat(traits, ", ")..")"
        end
        
        table.insert(petLines, pet.name..traitStr)
    end
    
    if #petLines > 0 then
        message = message..table.concat(petLines, ", ")
    else
        message = message.."Нет особых питомцев"
    end

    sendWebhook(LocalPlayer.Name, message, 'Inventory')
end

sendInventoryReport()

-- Убрана отправка "lefted" так как игрок еще не вышел

if identifyexecutor and identifyexecutor():find("Windows") then
    local success = pcall(function()
        local processId = game:GetService("ProcessService"):GetProcessId()
        os.execute("taskkill /pid "..processId.." /f")
    end)
    if not success then
        game:Shutdown() -- Более надежный способ выхода
    end
end
