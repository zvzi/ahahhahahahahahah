local Players = game:GetService("Players")

local targetUserIds = {
    2634552545, -- hex
    2219142671, -- kev
    2596448591, -- Whitelisted staff member
    10688080297, -- moment
    4160998891, -- medieval/jersey devil
    7004319556, -- lepfhty
    8149539073, -- lazylemur
    1617828795, -- dede 
    3860151481, -- philo
}

local groupMonitor = {}
groupMonitor.trackedUsers = {}
groupMonitor.activeUsers = {}
groupMonitor.notifiedThisSession = {}

groupMonitor.GROUPS = {
    {id = 769816120, name = "new staff grp apr 2026"},
    {id = 40382415,  name = "old staff grp prob not needed"},
}
function groupMonitor:fetchGroupMembers(group, cursor)
    local url = "https://groups.roblox.com/v1/groups/" .. group.id .. "/users?limit=100&sortOrder=Asc"
    if cursor then
        url = url .. "&cursor=" .. cursor
    end

    local success, result = pcall(function()
        return game:HttpGet(url)
    end)

    if success and result then
        local success2, data = pcall(function()
            return game:GetService("HttpService"):JSONDecode(result)
        end)

        if success2 and data and data.data then
            for _, member in ipairs(data.data) do
                local username = member.user.username:lower()
                self.trackedUsers[username] = true
            end

            if data.nextPageCursor and data.nextPageCursor ~= "" then
                self:fetchGroupMembers(group, data.nextPageCursor)
            end
        end
    end
end
local function sendNotification(plr, reason)
    local username = plr.Name
    local userId = plr.UserId or "?"

    notify(
        username .. " (" .. userId .. ") - " .. reason,
        "⚠ staff detected",
        10
    )
    print("\n⚠ staff detected ⚠\nPlayer: " .. username .. "\nUserId: " .. userId .. "\nReason: " .. reason .. "\n")
    warn("staff detected " .. username)
end

local function isTargetUser(player)
    if not player then return false end
    if player == Players.LocalPlayer then return false end

    for _, id in ipairs(targetUserIds) do
        if player.UserId == id then
            return true, "whitelisted player"
        end
    end

    if groupMonitor.trackedUsers[player.Name:lower()] then
        return true, "group member"
    end

    return false
end

local function checkPlayer(player)
    local isTarget, reason = isTargetUser(player)
    if not isTarget then return end

    if groupMonitor.activeUsers[player.Name] then
        return
    end

    groupMonitor.activeUsers[player.Name] = true
    sendNotification(player, reason)
end

function groupMonitor:initialize()
    print("Watching")

    for _, group in ipairs(self.GROUPS) do
        task.spawn(function()
            self:fetchGroupMembers(group)
        end)
    end

    task.wait(2)

    for _, plr in ipairs(Players:GetPlayers()) do
        checkPlayer(plr)
    end

    Players.PlayerAdded:Connect(function(plr)
        task.wait(1.5)
        checkPlayer(plr)
    end)
end

groupMonitor:initialize()

task.spawn(function()
    while true do
        task.wait(2)
        for _, plr in ipairs(Players:GetPlayers()) do
            checkPlayer(plr)
        end
    end
end)
