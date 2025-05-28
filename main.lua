local Platform = require("platform")
local Part = require("part")
local Bin = require("bin")

-- main.lua
function love.load()
    love.window.setTitle("Factory Part Sorting Game")
    love.window.setMode(1000, 900)
    score = 0
    partLanded = false
    currentPlatformIndex = 1

    platforms = Platform.createPlatforms()
    partTypes = Bin.types
    bins = Bin.bins

    airVents = {
        {x = 250, y = 560, width = 30, height = 20, power = -800},
        {x = 660, y = 680, width = 30, height = 20, power = -800}
    }

    part, currentPlatformIndex = Part.spawnNew(partTypes, platforms)
    groundY = 850
end

function love.update(dt)
    part.onPlatform = false
    for i, platform in ipairs(platforms) do
        local onPlatform = part.y + part.size / 2 >= platform.y -
                               platform.height / 2 and part.y + part.size / 2 <=
                               platform.y + platform.height / 2 and part.x >
                               platform.x - platform.width / 2 and part.x <
                               platform.x + platform.width / 2

        if onPlatform then
            currentPlatformIndex = i
            part.onPlatform = true
            platform.canTilt = true
            part.vy = 0
            part.y = platform.y - platform.height / 2 - part.size / 2
            break
        end
    end

    -- If not on any platform, resume falling
    if not part.onPlatform then
        if part.vy >= 0 then -- Only reset if not already boosted upward
            part.vy = 100
        end
        part.y = part.y + part.vy * dt
    end

    if currentPlatformIndex then
        local platform = platforms[currentPlatformIndex]
        -- Tilt platform if allowed
        if platform.canTilt then
            if love.keyboard.isDown("a") then
                platform.angle = math.max(platform.angle - dt * 2, -0.4)
            elseif love.keyboard.isDown("d") then
                platform.angle = math.min(platform.angle + dt * 2, 0.4)
            else
                platform.angle = platform.angle * 0.9
            end

            if part.onPlatform then
                part.vx = math.sin(platform.angle) * 200
                part.x = part.x + part.vx * dt
            else
                part.vx = 0
            end
        end
    end

    if not partLanded and part.y + part.size / 2 >= groundY then
        partLanded = true
        for _, bin in ipairs(bins) do
            if part.x >= bin.x and part.x <= bin.x + bin.width then
                if bin.color[1] == part.color[1] and bin.color[2] ==
                    part.color[2] and bin.color[3] == part.color[3] then
                    print("log: Correct bin")
                    score = score + 1
                else
                    print("Log: Wrong bin")
                end
            end
        end

        part.vy = 0

        -- Spawn new part after delay
        love.timer.sleep(0.5)
        spawnNewPart()
        partLanded = false
    end

    for _, vent in ipairs(airVents) do
        local touchingVent =
            part.y + part.size / 2 >= vent.y - vent.height / 2 and part.y -
                part.size / 2 <= vent.y + vent.height / 2 and part.x + part.size /
                2 >= vent.x - vent.width / 2 and part.x - part.size / 2 <=
                vent.x + vent.width / 2

        if touchingVent then part.vy = vent.power end
    end
end

function love.draw()
    -- Draw platform
    for _, p in ipairs(platforms) do
        love.graphics.push()
        love.graphics.translate(p.x, p.y)
        love.graphics.rotate(p.angle)
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("fill", -p.width / 2, -p.height / 2, p.width,
                                p.height)
        love.graphics.pop()
    end

    -- Draw part
    love.graphics.setColor(part.color)
    love.graphics.rectangle("fill", part.x - part.size / 2,
                            part.y - part.size / 2, part.size, part.size)

    -- Draw bins
    for _, bin in ipairs(bins) do
        love.graphics.setColor(bin.color)
        love.graphics.rectangle("fill", bin.x, groundY, bin.width, 30)
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Score: " .. score, 10, 10)

    -- Draw air vents
    for _, vent in ipairs(airVents) do
        love.graphics.setColor(0.5, 0.8, 1) -- light blue
        love.graphics.rectangle("fill", vent.x - vent.width / 2,
                                vent.y - vent.height / 2, vent.width,
                                vent.height)
    end
end

function spawnNewPart()
    part, currentPlatformIndex = Part.spawnNew(partTypes, platforms)
end

