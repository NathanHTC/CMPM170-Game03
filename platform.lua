-- platform.lua
local M = {}

function M.createPlatforms()
    local platforms = {}
    local startY = 200

    for i = 1, 9 do
        local width = 100 + (i % 3) * 50
        local x = math.random(100 + width / 2, 900 - width / 2)

        table.insert(platforms, {
            x = x,
            y = startY + (i - 1) * 60,
            width = width,
            height = 20,
            angle = 0,
            canTilt = false,
            index = i
        })
    end

    return platforms
end

return M
