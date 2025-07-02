getgenv().WebHookURL = 'http://127.0.0.1:5000/'

local HttpService = game:GetService('HttpService')
local Players = game:GetService('Players')
local LocalPlayer = Players.LocalPlayer
local CommF_ = game.ReplicatedStorage.Remotes:WaitForChild('CommF_')

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
        game = "Blox Fruits"
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

sendWebhook(LocalPlayer.Name, "Blox Fruit Inventory Report", "joined")

function getfruitsfrominv()
    local inventory = CommF_:InvokeServer('getInventory')
    local fruits = {}

    for _, item in ipairs(inventory) do
        if item.Type == 'Blox Fruit' then
            table.insert(fruits, {
                Name = item.Name,
                DisplayName = require(
                    game.ReplicatedStorage.Modules.Asset.GetFruitName
                )(item.Name),
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
    content = content
        .. string.format(
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
    content = content ~= '' and content
        or 'Fruit Not Found',
    type = 'inventory',
}

local function sendhook()
    local httprequest = (syn and syn.request) 
        or (http and http.request) 
        or http_request 
        or (fluxus and fluxus.request) 
        or (getgenv and getgenv().request) 
        or request

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
        warn("Webhook not sent Missing URL or httprequest")
    end
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
