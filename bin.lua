-- bin.lua




local M = {}

M.types = {
    { type = "part1", color = {1, 0, 0}, imageIndex = 1 },
    { type = "part2", color = {0, 1, 0}, imageIndex = 2 },
    { type = "part3", color = {0, 0, 1}, imageIndex = 3 },
}

M.bins = {
    { type = "part1", x = 100, y = 950, width = 250, color = {1, 0, 0}, image = "assets/trashbin1.png" },
    { type = "part2", x = 375, y = 955, width = 250, color = {0, 1, 0}, image = "assets/trashbin2.png" },
    { type = "part3", x = 650, y = 960, width = 250, color = {0, 0, 1}, image = "assets/trashbin3.png" }
}

return M
