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
    
    -- Happiness bar settings
    maxHappiness = 100
    currentHappiness = maxHappiness
    happinessDecreasePerScore = 5 -- How much happiness decreases per point scored
    happinessIncreasePerMistake = 5 -- How much happiness increases when player makes mistake
    
    -- Happiness bar visual settings
    happinessBar = {
        x = 920,          -- X position (right side of screen)
        y = 50,           -- Y position from top
        width = 30,       -- Width of the bar
        height = 400,     -- Height of the bar
        borderWidth = 2   -- Border thickness
    }

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

-- Function to calculate happiness bar color based on current happiness level
function getHappinessColor(happiness, maxHappiness)
    local ratio = happiness / maxHappiness
    
    if ratio > 0.5 then
        -- Green to Yellow (happiness 100% to 50%)
        -- At 100%: pure green (0, 1, 0)
        -- At 50%: yellow (1, 1, 0)
        local t = (1.0 - ratio) * 2 -- Scale 1.0-0.5 to 0-1
        return {t, 1, 0} -- Red increases, Green stays 1, Blue stays 0
    else
        -- Yellow to Red (happiness 50% to 0%)
        -- At 50%: yellow (1, 1, 0)
        -- At 0%: red (1, 0, 0)
        local t = ratio * 2 -- Scale 0-0.5 to 0-1
        return {1, t, 0} -- Red stays 1, Green decreases, Blue stays 0
    end
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
                    -- Decrease happiness when score increases
                    currentHappiness = math.max(0, currentHappiness - happinessDecreasePerScore)
                else
                    print("Log: Wrong bin")
                    -- Decrease score and increase happiness when player makes mistake
                    score = math.max(0, score - 1) -- Prevent negative scores
                    currentHappiness = math.min(maxHappiness, currentHappiness + happinessIncreasePerMistake)
                end
                break -- Exit loop once we've found the bin the part landed in
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

    -- Draw happiness bar
    local bar = happinessBar
    
    -- Draw border (black outline)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", bar.x - bar.borderWidth, bar.y - bar.borderWidth, 
                            bar.width + bar.borderWidth * 2, bar.height + bar.borderWidth * 2)
    
    -- Draw background (dark gray)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", bar.x, bar.y, bar.width, bar.height)
    
    -- Draw happiness level
    local happinessRatio = currentHappiness / maxHappiness
    local fillHeight = bar.height * happinessRatio
    local fillY = bar.y + bar.height - fillHeight -- Start from bottom
    
    -- Set color based on happiness level
    local happinessColor = getHappinessColor(currentHappiness, maxHappiness)
    love.graphics.setColor(happinessColor)
    love.graphics.rectangle("fill", bar.x, fillY, bar.width, fillHeight)
    
    -- Draw happiness text
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Happiness", bar.x - 20, bar.y - 30)
    love.graphics.print(math.floor(currentHappiness) .. "%", bar.x - 10, bar.y + bar.height + 10)

    -- Draw air vents
    for _, vent in ipairs(airVents) do
        love.graphics.setColor(0.5, 0.8, 1) -- light blue
        love.graphics.rectangle("fill", vent.x - vent.width / 2,
                                vent.y - vent.height / 2, vent.width,
                                vent.height)
    end
    
    -- Draw score (moved this to the end to ensure it's visible)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Score: " .. score, 10, 10)
end

function spawnNewPart()
    part, currentPlatformIndex = Part.spawnNew(partTypes, platforms)
end