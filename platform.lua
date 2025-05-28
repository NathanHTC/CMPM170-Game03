-- platform.lua
local M = {}

function M.createPlatforms()
    -- Hardcoded positions and widths
    return {
        {x = 200, y = 200, width = 150, height = 20, angle = 0, canTilt = false, index = 1},
        {x = 600, y = 260, width = 200, height = 20, angle = 0, canTilt = false, index = 2},
        {x = 400, y = 320, width = 120, height = 20, angle = 0, canTilt = false, index = 3},
        {x = 700, y = 380, width = 180, height = 20, angle = 0, canTilt = false, index = 4},
        {x = 300, y = 440, width = 170, height = 20, angle = 0, canTilt = false, index = 5},
        {x = 550, y = 500, width = 150, height = 20, angle = 0, canTilt = false, index = 6},
        {x = 350, y = 560, width = 190, height = 20, angle = 0, canTilt = false, index = 7},
        {x = 650, y = 620, width = 140, height = 20, angle = 0, canTilt = false, index = 8},
        {x = 600, y = 680, width = 100, height = 20, angle = 0, canTilt = false, index = 9}
    }
end

return M
