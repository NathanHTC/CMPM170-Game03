-- main.lua
local robotFaces = {}
local currentFace = "happy"
local previousFace = "happy"
local showHurt = false
local hurtTimer = 0
local lastHappiness = 100

local waitToSpawnTimer = 0
local waitingToSpawn = false
local spawnTimer = 0
local spawnInterval = 2

-- Conveyor belt variables
local conveyorDirection = 0
local arrowAnimationTimer = 0
local arrowSpacing = 40
local arrowSpeed = 2

local Platform = require("platform")
local Part = require("part")
local Bin = require("bin")

function love.load()
    love.window.setTitle("Factory Part Sorting Game")
    love.window.setMode(1000, 900)
    score = 0

    -- Load assets
    background = love.graphics.newImage("assets/factory_background.png")
    robotFaces = {
        happy = love.graphics.newImage("assets/robotsmile.png"),
        neutral = love.graphics.newImage("assets/robotneutral.png"),
        sad = love.graphics.newImage("assets/robotsad.png"),
        hurt = love.graphics.newImage("assets/robothurt.png")
    }

    -- Happiness settings
    maxHappiness = 100
    currentHappiness = maxHappiness
    happinessDecreasePerScore = 5
    happinessIncreasePerMistake = 5

    happinessBar = {
        x = 880,
        y = 180,
        width = 30,
        height = 400,
        borderWidth = 2
    }

    platforms = Platform.createPlatforms()
    partTypes = Bin.types
    bins = Bin.bins

    -- Spawn initial set of parts
    parts = Part.spawnBatch(partTypes, platforms, math.random(1, 3))
    groundY = 850
end

-- Determines color of the happiness bar
function getHappinessColor(happiness, maxHappiness)
    local ratio = happiness / maxHappiness
    if ratio > 0.5 then
        local t = (1.0 - ratio) * 2
        return {t, 1, 0}
    else
        local t = ratio * 2
        return {1, t, 0}
    end
end

-- Draws animated arrows on platforms
function drawConveyorArrows(platform)
    if conveyorDirection == 0 then return end
    love.graphics.setColor(0.8, 0.8, 0.8, 0.7)
    local arrowSize = 8
    local platformLeft = platform.x - platform.width / 2
    local platformRight = platform.x + platform.width / 2
    local platformY = platform.y - platform.height / 2 - 5
    local animatedOffset = (arrowAnimationTimer * arrowSpeed * 60) % arrowSpacing
    local startX = conveyorDirection == -1 and platformRight - animatedOffset or platformLeft + animatedOffset
    local numArrows = math.ceil(platform.width / arrowSpacing) + 2

    for i = 0, numArrows do
        local arrowX = conveyorDirection == 1 and (startX + i * arrowSpacing) or (startX - i * arrowSpacing)
        if arrowX >= platformLeft and arrowX <= platformRight then
            if conveyorDirection == 1 then
                love.graphics.polygon("fill",
                    arrowX - arrowSize, platformY - arrowSize / 2,
                    arrowX + arrowSize, platformY,
                    arrowX - arrowSize, platformY + arrowSize / 2)
            else
                love.graphics.polygon("fill",
                    arrowX + arrowSize, platformY - arrowSize / 2,
                    arrowX - arrowSize, platformY,
                    arrowX + arrowSize, platformY + arrowSize / 2)
            end
        end
    end
end

function love.update(dt)
    arrowAnimationTimer = arrowAnimationTimer + dt

    -- Check collision and apply gravity
    for _, part in ipairs(parts) do
        part.onPlatform = false
        for _, platform in ipairs(platforms) do
            local partLeft = part.x - part.size / 2
            local partRight = part.x + part.size / 2
            local partBottom = part.y + part.size / 2
            local partTop = part.y - part.size / 2
            local platformLeft = platform.x - platform.width / 2
            local platformRight = platform.x + platform.width / 2
            local platformTop = platform.y - platform.height / 2
            local platformBottom = platform.y + platform.height / 2

            local verticalOverlap = partBottom >= platformTop and partTop <= platformBottom
            local horizontalOverlap = partRight > platformLeft and partLeft < platformRight

            if verticalOverlap and horizontalOverlap then
                part.onPlatform = true
                part.vy = 0
                part.y = platformTop - part.size / 2
                break
            end
        end

        if not part.onPlatform then
            if part.vy >= 0 then part.vy = 300 end
            part.y = part.y + part.vy * dt
        end
    end

    -- Conveyor control
    if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
        conveyorDirection = -1
    elseif love.keyboard.isDown("d") or love.keyboard.isDown("right") then
        conveyorDirection = 1
    else
        conveyorDirection = 0
    end

    -- Move parts on conveyor
    for _, part in ipairs(parts) do
        if part.onPlatform and conveyorDirection ~= 0 then
            local conveyorSpeed = 150
            part.vx = conveyorDirection * conveyorSpeed
            part.x = part.x + part.vx * dt
        else
            part.vx = 0
        end
    end

    -- Update robot expression
    if showHurt then
        hurtTimer = hurtTimer - dt
        if hurtTimer <= 0 then
            showHurt = false
            currentFace = previousFace
        end
    end

    if not showHurt then
        if currentHappiness < 40 then
            currentFace = "sad"
        elseif currentHappiness < 65 then
            currentFace = "neutral"
        else
            currentFace = "happy"
        end
    end

    if not showHurt and currentHappiness < lastHappiness - 4.9 then
        showHurt = true
        hurtTimer = 1.0
        previousFace = currentFace
        currentFace = "hurt"
    end

    lastHappiness = currentHappiness

    -- Check part landing on ground
    local allLanded = true
    for _, part in ipairs(parts) do
        if not part.landed and part.y + part.size / 2 >= groundY then
            part.landed = true
            local hitBin = false
            for _, bin in ipairs(bins) do
                if part.x >= bin.x and part.x <= bin.x + bin.width then
                    hitBin = true
                    if bin.color[1] == part.color[1] and bin.color[2] == part.color[2] and bin.color[3] == part.color[3] then
                        score = score + 1
                        currentHappiness = math.max(0, currentHappiness - happinessDecreasePerScore)
                    else
                        score = math.max(0, score - 1)
                        currentHappiness = math.min(maxHappiness, currentHappiness + happinessIncreasePerMistake)
                    end
                    break
                end
            end
            part.vy = 0
        end
        if not part.landed then allLanded = false end
    end

    -- Delay before new spawn
    if allLanded and not waitingToSpawn then
        waitingToSpawn = true
        waitToSpawnTimer = 0.5
    end

    if waitingToSpawn then
        waitToSpawnTimer = waitToSpawnTimer - dt
        if waitToSpawnTimer <= 0 then
            spawnNewPart()
            waitingToSpawn = false
        end
    end
end

function love.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(background, 0, 0, 0,
        love.graphics.getWidth() / background:getWidth(),
        love.graphics.getHeight() / background:getHeight())

    -- Platforms
    for _, p in ipairs(platforms) do
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("fill", p.x - p.width / 2, p.y - p.height / 2, p.width, p.height)
    end

    -- Parts
    for _, part in ipairs(parts) do
        love.graphics.setColor(part.color)
        love.graphics.rectangle("fill", part.x - part.size / 2, part.y - part.size / 2, part.size, part.size)
    end

    -- Bins
    for _, bin in ipairs(bins) do
        love.graphics.setColor(bin.color)
        love.graphics.rectangle("fill", bin.x, groundY, bin.width, 30)
    end

    -- Happiness Bar
    local bar = happinessBar
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", bar.x - bar.borderWidth, bar.y - bar.borderWidth,
        bar.width + bar.borderWidth * 2, bar.height + bar.borderWidth * 2)

    local ratio = currentHappiness / maxHappiness
    local fillHeight = bar.height * ratio
    local fillY = bar.y + bar.height - fillHeight
    love.graphics.setColor(getHappinessColor(currentHappiness, maxHappiness))
    love.graphics.rectangle("fill", bar.x, fillY, bar.width, fillHeight)

    -- Robot face
    if robotFaces[currentFace] then
        local faceImage = robotFaces[currentFace]
        local scale = 0.2
        local drawX = bar.x - faceImage:getWidth() * scale + 115
        local drawY = bar.y - faceImage:getHeight() * scale + 10
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(faceImage, drawX, drawY, 0, scale, scale)
    end

    -- Labels
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(math.floor(currentHappiness) .. "%", bar.x - 5, bar.y + bar.height + 10)
    love.graphics.print("Score: " .. score, 10, 10)
    love.graphics.print("Hold A/D or Left/Right to move conveyor", 10, 30)
end

-- Spawn 1-3 parts using batch function
function spawnNewPart()
    parts = Part.spawnBatch(partTypes, platforms, math.random(1, 3))
end

-- Testing damage
function love.keypressed(key)
    if key == "h" then
        showHurt = true
        hurtTimer = 1.0
        currentFace = "hurt"
    end
end
