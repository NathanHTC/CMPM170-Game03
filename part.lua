-- part.lua
local M = {}

function M.spawnNew(partTypes, platforms)
    local randomType = partTypes[math.random(#partTypes)]
    local currentPlatformIndex = 1
    local platform = platforms[currentPlatformIndex]
    local spawnX = math.random(150, 700)

    platform.canTilt = false
    platform.angle = 0

    local part = {
        x = spawnX,
        y = platforms[1].y - 100,
        size = 20,
        vx = 0,
        vy = 200,
        onPlatform = false,
        type = randomType.type,
        color = randomType.color
    }

    return part, currentPlatformIndex
end

return M
