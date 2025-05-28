-- part.lua
local M = {}

function M.spawnNew(partTypes, platforms)
    local randomType = partTypes[math.random(#partTypes)]
    local currentPlatformIndex = 1
    local platform = platforms[currentPlatformIndex]

    platform.canTilt = false
    platform.angle = 0

    local part = {
        x = platform.x,
        y = platform.y - 100,
        size = 20,
        vx = 0,
        vy = 100,
        onPlatform = false,
        type = randomType.type,
        color = randomType.color
    }

    return part, currentPlatformIndex
end

return M
