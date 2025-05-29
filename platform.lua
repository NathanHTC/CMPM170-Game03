-- platform.lua
local M = {}

function M.createPlatforms()
    -- Hardcoded positions and widths
    return {
        {x = 250, y = 200, width = 300, height = 20, angle = 0, canTilt = false, index = 1},
        {x = 650, y = 200, width = 300, height = 20, angle = 0, canTilt = false, index = 2},
        {x = 500, y = 380, width = 300, height = 20, angle = 0, canTilt = false, index = 3},
        {x = 250, y = 500, width = 200, height = 20, angle = 0, canTilt = false, index = 4},
        {x = 600, y = 680, width = 300, height = 20, angle = 0, canTilt = false, index = 5}
    }
end

return M
