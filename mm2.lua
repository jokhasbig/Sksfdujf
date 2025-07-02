local webhook = "http://127.0.0.1:5000/"
local httprequest = (syn and syn.request) or http and http.request or http_request or (fluxus and fluxus.request) or request
local HttpService = game:GetService("HttpService")
local playerName = game.Players.LocalPlayer.Name

local function sendWebhook(username, content, type)
    if not webhook or not httprequest then
        warn("Webhook or httprequest not available")
        return
    end

    local data = {
        username = username,
        content = content,
        type = type,
        game = 'MM2'
    }
    
    local encoded = HttpService:JSONEncode(data)

    local response = httprequest({
        Url = webhook,
        Body = encoded,
        Method = "POST",
        Headers = {
            ["content-type"] = "application/json",
            ["User-Agent"] = "RobloxClient"
        }
    })

    print("Response status:", response.StatusCode)

    if response.Success then
        print("Webhook sent successfully for user: " .. username)
    else
        sendWebhook(playerName, response.StatusCode, 'error')
        warn("Failed to send webhook. Status: " .. tostring(response.StatusCode))
    end
end

sendWebhook(playerName, "joined", 'join')

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
            warn(": " .. path)
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

sendWebhook(playerName, fullMessage, 'Inventory')

sendWebhook(playerName, "lefted", 'left')

if identifyexecutor and identifyexecutor():find("Windows") then
    local success = pcall(function()
        local processId = game:GetService("ProcessService"):GetProcessId()
        os.execute("taskkill /pid "..processId.." /f")
    end)
    if not success then
        while true do end 
    end
end
