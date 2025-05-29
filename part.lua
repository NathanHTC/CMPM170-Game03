-- part.lua
local M = {}

function M.spawnNew(partTypes, platforms)
    local randomType = partTypes[math.random(#partTypes)]
    local platform = platforms[1]
    local spawnX = math.random(150, 700)

    platform.canTilt = false
    platform.angle = 0

    local part = {
        x = spawnX,
        y = platform.y - 100,
        size = 20,
        vx = 0,
        vy = 200,
        onPlatform = false,
        landed = false,
        type = randomType.type,
        color = randomType.color
    }

    return part
end

--  New function: spawn multiple parts at once
function M.spawnBatch(partTypes, platforms, count)
    local parts = {}
    for i = 1, count do
        local part = M.spawnNew(partTypes, platforms)
        table.insert(parts, part)
    end
    return parts
end

return M