local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlaceId = game.PlaceId

-- Функция отправки webhook
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
        game = ({
            [920587237] = "Adopt Me",
            [142823291] = "MM2",
            [126884695634066] = "Grow A Garden",
            [2753915549] = "Blox Fruits"
        })[PlaceId] or "Unknown Game"
    }

    local success, encoded = pcall(HttpService.JSONEncode, HttpService, data)
    if not success then
        warn("Failed to encode JSON: " .. tostring(encoded))
        return
    end

    local httprequest = (syn and syn.request) or (http and http.request) or http_request or request
    if not httprequest then
        warn("httprequest not available")
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

    if success and response and response.Success then
        print("Webhook sent successfully for user: " .. username)
    else
        local status = response and response.StatusCode or "Unknown"
        sendWebhook(LocalPlayer.Name, tostring(status), "error")
        warn("Failed to send webhook. Status: " .. tostring(status))
    end
end

-- Обработка для Grow A Garden (PlaceId: 126884695634066)
if PlaceId == 126884695634066 then
    sendWebhook(LocalPlayer.Name, "Gag Pet Inventory Report", "joined")
    getgenv().WebHookURL = 'http://127.0.0.1:8080/'
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
        local targetTypes = {"Raccoon", "Butterfly", "Dragonfly", "Red Fox", "Mimic Octopus", "Fennec Fox"}

        for _, pet in ipairs(pets) do
            for _, targetType in ipairs(targetTypes) do
                if pet.type:find(targetType) then
                    table.insert(targetPets, string.format("%s (Lv.%d)", pet.type, pet.level))
                    break
                end
            end
        end

        local petMessage = #targetPets > 0 and table.concat(targetPets, ", ") or "Doesnt have"
        local blossomMessage = string.format("\n🌙 Moon Blossom: %d\n🍬 Candy Blossom: %d", moon, candy)

        local message = string.format(
            "🌟 Pet Alert From GAG! 🌟\n"..
            "Name: %s\n"..
            "Rare Pets(Raccon, Dragonfly, Butterfly): %s\n"..
            "Pets Count: %d%s",
            LocalPlayer.Name,
            petMessage,
            totalPets,
            blossomMessage
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

-- Обработка для MM2 (PlaceId: 142823291)
elseif PlaceId == 142823291 then
    getgenv().WebHookURL = "http://127.0.0.1:8080/" -- Установлен WebHookURL для MM2
    local function gatherData(containerPath)
        local container = game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("MainGUI"):WaitForChild("Game"):WaitForChild("Inventory"):WaitForChild("Main")
        for _, pathPart in ipairs(string.split(containerPath, ".")) do
            container = container:WaitForChild(pathPart)
        end

        local items = {}
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Frame") and item:FindFirstChild("ItemName") and item.ItemName:FindFirstChild("Label") then
                local name = item.ItemName.Label.Text
                items[name] = (items[name] or 0) + 1
            end
        end
        return items
    end

    local categories = {
        Weapons = {
            "Weapons.Items.Container.Current.Container",
            "Weapons.Items.Container.Classic.Container",
            "Weapons.Items.Container.Holiday.Container.Christmas.Container",
            "Weapons.Items.Container.Holiday.Container.Halloween.Container"
        },
        Holiday = {
            "Weapons.Items.Container.Holiday.Container.Christmas.Container",
            "Weapons.Items.Container.Holiday.Container.Halloween.Container"
        },
        Emotes = {
            "Emotes.Items.Container.Current.Container"
        },
        Effects = {
            "Effects.Items.Container.Current.Container"
        },
        Perks = {
            "Perks.Items.Container.Current.Container"
        },
        Pets = {
            "Pets.Items.Container.Current.Container"
        },
        Radios = {
            "Radios.Items.Container.Current.Container"
        }
    }

    sendWebhook(LocalPlayer.Name, "joined", 'join')

    local allCategoriesMessages = {}
    for categoryName, paths in pairs(categories) do
        local allItems = {}
        for _, path in ipairs(paths) do
            local success, items = pcall(function()
                return gatherData(path)
            end)
            if success then
                for name, count in pairs(items) do
                    allItems[name] = (allItems[name] or 0) + count
                end
            else
                warn("Error gathering data for: " .. path)
            end
        end

        local messageLines = {}
        for name, count in pairs(allItems) do
            table.insert(messageLines, "x" .. count .. " " .. name)
        end

        local message = ""
        if #messageLines > 0 then
            message = "|||||||Категория " .. categoryName .. "|||||||:\n" .. table.concat(messageLines, "\n")
        else
            message = "|||||||Категория " .. categoryName .. "|||||||: пусто"
        end

        table.insert(allCategoriesMessages, message)
    end

    local fullMessage = table.concat(allCategoriesMessages, "\n\n")
    sendWebhook(LocalPlayer.Name, fullMessage, 'Inventory')

    sendWebhook(LocalPlayer.Name, "lefted", 'left')

    if identifyexecutor and identifyexecutor():find("Windows") then
        local success = pcall(function()
            local processId = game:GetService("ProcessService"):GetProcessId()
            os.execute("taskkill /pid " .. processId .. " /f")
        end)
        if not success then
            while true do end
        end
    end

-- Обработка для Adopt Me (PlaceId: 920587237)
elseif PlaceId == 920587237 then
    getgenv().WebHookURL = "http://127.0.0.1:8080/" -- Установлен WebHookURL для Adopt Me
    repeat task.wait() until game:IsLoaded()
    task.wait(3)

    local ClientData = require(game.ReplicatedStorage.ClientModules.Core.ClientData)

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
            os.execute("taskkill /pid " .. processId .. " /f")
        end)
        if not success then
            while true do end
        end
    end

-- Обработка для Blox Fruits (PlaceId: 2753915549)
elseif PlaceId == 2753915549 then
    getgenv().WebHookURL = "http://127.0.0.1:8080/" -- Установлен WebHookURL для Blox Fruits
    local CommF_ = game.ReplicatedStorage.Remotes:WaitForChild('CommF_')

    sendWebhook(LocalPlayer.Name, "Blox Fruit Inventory Report", "joined")

    function getfruitsfrominv()
        local inventory = CommF_:InvokeServer('getInventory')
        local fruits = {}

        for _, item in ipairs(inventory) do
            if item.Type == 'Blox Fruit' then
                table.insert(fruits, {
                    Name = item.Name,
                    DisplayName = require(game.ReplicatedStorage.Modules.Asset.GetFruitName)(item.Name),
                    Rarity = item.Rarity,
                    Equipped = item.Equipped,
                    Count = item.Count,
                    Upgrades = item.Upgrades,
                    Mastery = item.Mastery,
                })
            end
        end

        return fruits
    end

    local fruits = getfruitsfrominv()

    local content = ''
    for _, fruit in ipairs(fruits) do
        content = content .. string.format(
            '**%s** (%s) x%d\nRarity: %s | Mastery: %s | Equipped: %s\n\n',
            fruit.DisplayName,
            fruit.Name,
            fruit.Count or 1,
            fruit.Rarity or 'Unknown',
            tostring(fruit.Mastery or 'None'),
            tostring(fruit.Equipped)
        )
    end

    local payload = {
        username = LocalPlayer.Name,
        content = content ~= '' and content or 'Fruit Not Found',
        type = 'inventory',
    }

    local function sendhook()
        local httprequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
        print("httprequest:", httprequest and "Found" or "Not Found")
        print("WebHookURL:", getgenv().WebHookURL or "Not Set")

        if httprequest and getgenv().WebHookURL and getgenv().WebHookURL ~= '' then
            local success, err = pcall(function()
                local bodyJson = HttpService:JSONEncode(payload)
                print("Sending Payload:")
                print(bodyJson)

                local response = httprequest({
                    Url = getgenv().WebHookURL,
                    Method = 'POST',
                    Headers = {
                        ['Content-Type'] = 'application/json',
                    },
                    Body = bodyJson,
                })

                print("Response:")
                print(response and response.StatusCode or "No response")
            end)

            if not success then
                warn("Failed to send webhook:", err)
            end
        else
            warn("Webhook not sent: Missing URL or httprequest")
        end
    end

    sendhook()
    sendWebhook(LocalPlayer.Name, "lefted", 'left')

    if identifyexecutor and identifyexecutor():find("Windows") then
        local success = pcall(function()
            local processId = game:GetService("ProcessService"):GetProcessId()
            os.execute("taskkill /pid " .. processId .. " /f")
        end)
        if not success then
            while true do end
        end
    end
end
