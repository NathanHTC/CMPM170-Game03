-- bin.lua
local M = {}

M.bins = {
    {x = 150, width = 150, color = {1, 0, 0}}, -- Red
    {x = 425, width = 150, color = {0, 1, 0}}, -- Green
    {x = 700, width = 150, color = {0, 0, 1}}  -- Blue
}

M.types = {
    {type = "red", color = {1, 0, 0}, binX = 200},
    {type = "green", color = {0, 1, 0}, binX = 350},
    {type = "blue", color = {0, 0, 1}, binX = 500}
}

return M
