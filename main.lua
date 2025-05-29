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

-- Game state variables
local gameState = "start" -- "start", "playing", "gameOver"
local startButton = {
    x = 500,
    y = 450,
    radius = 80,
    hovered = false,
    cogRotation = 0
}

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

    scrapImages = {
        love.graphics.newImage("assets/scrap_part1.png"),
        love.graphics.newImage("assets/scrap_part2.png"),
        love.graphics.newImage("assets/scrap_part3.png")
    }



    -- Happiness settings
    maxHappiness = 100
    currentHappiness = maxHappiness
    happinessDecreasePerScore = 25
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

    -- Initialize empty parts table for start screen
    parts = {}
    groundY = 850

    -- Load bin images
    for _, bin in ipairs(bins) do
        if bin.image then
            bin.imageAsset = love.graphics.newImage(bin.image)
        end
    end

end

function initializeGame()
    score = 0
    currentHappiness = maxHappiness
    currentFace = "happy"
    previousFace = "happy"
    showHurt = false
    hurtTimer = 0
    lastHappiness = 100
    waitToSpawnTimer = 0
    waitingToSpawn = false
    conveyorDirection = 0
    arrowAnimationTimer = 0
    
    -- Spawn initial set of parts
    parts = Part.spawnBatch(partTypes, platforms, math.random(1, 3))
end

-- Draw a cog/gear shape
function drawCog(x, y, radius, rotation)
    local teeth = 8
    local innerRadius = radius * 0.6
    local toothHeight = radius * 0.2
    
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(rotation)
    
    -- Draw outer teeth
    love.graphics.setColor(0.7, 0.7, 0.7)
    for i = 0, teeth - 1 do
        local angle1 = (i / teeth) * math.pi * 2
        local angle2 = ((i + 0.3) / teeth) * math.pi * 2
        local angle3 = ((i + 0.7) / teeth) * math.pi * 2
        local angle4 = ((i + 1) / teeth) * math.pi * 2
        
        local x1, y1 = math.cos(angle1) * radius, math.sin(angle1) * radius
        local x2, y2 = math.cos(angle2) * (radius + toothHeight), math.sin(angle2) * (radius + toothHeight)
        local x3, y3 = math.cos(angle3) * (radius + toothHeight), math.sin(angle3) * (radius + toothHeight)
        local x4, y4 = math.cos(angle4) * radius, math.sin(angle4) * radius
        
        love.graphics.polygon("fill", x1, y1, x2, y2, x3, y3, x4, y4)
    end
    
    -- Draw main circle
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.circle("fill", 0, 0, radius)
    
    -- Draw inner circle (hole)
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.circle("fill", 0, 0, innerRadius)
    
    love.graphics.pop()
end

-- Check if point is inside circle
function pointInCircle(px, py, cx, cy, radius)
    local dx = px - cx
    local dy = py - cy
    return (dx * dx + dy * dy) <= (radius * radius)
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
    if gameState == "start" then
        -- Update cog rotation
        startButton.cogRotation = startButton.cogRotation + dt * 0.5
        
        -- Check if mouse is hovering over start button
        local mx, my = love.mouse.getPosition()
        startButton.hovered = pointInCircle(mx, my, startButton.x, startButton.y, startButton.radius)
        
    elseif gameState == "playing" then
        -- Check for game over condition
        if currentHappiness <= 0 then
            gameState = "gameOver"
            return
        end
        
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
end

function love.draw()
    if gameState == "start" then
        drawStartScreen()
    elseif gameState == "playing" then
        drawGameScreen()
    elseif gameState == "gameOver" then
        drawGameOverScreen()
    end
end

function drawStartScreen()
    -- Draw background
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(background, 0, 0, 0,
        love.graphics.getWidth() / background:getWidth(),
        love.graphics.getHeight() / background:getHeight())
    
    -- Dim the background
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw start button (cog)
    local buttonScale = startButton.hovered and 1.1 or 1.0
    local buttonRadius = startButton.radius * buttonScale
    
    -- Button background circle
    love.graphics.setColor(0.2, 0.3, 0.4, 0.8)
    love.graphics.circle("fill", startButton.x, startButton.y, buttonRadius + 10)
    
    -- Draw the cog
    drawCog(startButton.x, startButton.y, buttonRadius, startButton.cogRotation)
    
    -- Draw a subtle glow effect if hovered
    if startButton.hovered then
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.circle("line", startButton.x, startButton.y, buttonRadius + 15)
    end
end

function drawGameScreen()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(background, 0, 0, 0,
        love.graphics.getWidth() / background:getWidth(),
        love.graphics.getHeight() / background:getHeight())

    -- Draw conveyor arrows
    for _, platform in ipairs(platforms) do
        drawConveyorArrows(platform)
    end

    -- Platforms
    for _, p in ipairs(platforms) do
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("fill", p.x - p.width / 2, p.y - p.height / 2, p.width, p.height)
    end

    -- Parts
   for _, part in ipairs(parts) do
        if part.imageIndex and scrapImages[part.imageIndex] then
            local img = scrapImages[part.imageIndex]
            local scale = part.size / img:getWidth()
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(img, part.x - (img:getWidth() * scale) / 2, part.y - (img:getHeight() * scale) / 2, 0, scale, scale)
        else
            love.graphics.setColor(part.color)
            love.graphics.rectangle("fill", part.x - part.size / 2, part.y - part.size / 2, part.size, part.size)
        end
    end

    -- Bins
    for _, bin in ipairs(bins) do
        if bin.imageAsset then
            love.graphics.setColor(1, 1, 1)

            -- Scale the bin to match width
            local scale = bin.width / bin.imageAsset:getWidth()

            -- Offset logic for specific images
            local yOffset = 30  -- lowers all bins uniformly
            if bin.image:find("trashbin3.png") then
                scale = scale * 0.85  -- skull bin a bit large, scale it down
                yOffset = 45          -- adjust further down if needed
            elseif bin.image:find("trashbin2.png") then
                scale = scale * 1.05  -- bolt bin slightly small, scale it up
                yOffset = 30
            end

        -- Calculate placement
        local binHeight = bin.imageAsset:getHeight() * scale
        local drawX = bin.x
        local drawY = bin.y + yOffset - binHeight

        love.graphics.draw(bin.imageAsset, drawX, drawY, 0, scale, scale)
        
        else
            -- fallback: colored box
            love.graphics.setColor(bin.color)
            love.graphics.rectangle("fill", bin.x, bin.y, bin.width, 30)
        end
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

    -- Score display (using colored rectangles as a visual indicator)
    love.graphics.setColor(1, 1, 1)
    for i = 1, math.min(score, 20) do
        love.graphics.rectangle("fill", 50 + (i-1) * 12, 50, 8, 8)
    end
end

function drawGameOverScreen()
    -- Draw the game screen in the background, but dimmed
    drawGameScreen()
    
    -- Overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Show the sad robot face prominently
    if robotFaces["sad"] then
        local faceImage = robotFaces["sad"]
        local scale = 0.8
        local drawX = (love.graphics.getWidth() - faceImage:getWidth() * scale) / 2
        local drawY = (love.graphics.getHeight() - faceImage:getHeight() * scale) / 2 - 50
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(faceImage, drawX, drawY, 0, scale, scale)
    end
    
    -- Draw a restart button (another cog, smaller)
    local restartButton = {
        x = love.graphics.getWidth() / 2,
        y = love.graphics.getHeight() / 2 + 150,
        radius = 50
    }
    
    local mx, my = love.mouse.getPosition()
    local restartHovered = pointInCircle(mx, my, restartButton.x, restartButton.y, restartButton.radius)
    local restartScale = restartHovered and 1.1 or 1.0
    local restartRadius = restartButton.radius * restartScale
    
    -- Button background
    love.graphics.setColor(0.2, 0.3, 0.4, 0.8)
    love.graphics.circle("fill", restartButton.x, restartButton.y, restartRadius + 5)
    
    -- Draw the restart cog
    drawCog(restartButton.x, restartButton.y, restartRadius, love.timer.getTime() * 0.5)
    
    -- Glow effect if hovered
    if restartHovered then
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.circle("line", restartButton.x, restartButton.y, restartRadius + 10)
    end
end

-- Spawn 1-3 parts using batch function
function spawnNewPart()
    parts = Part.spawnBatch(partTypes, platforms, math.random(1, 3))
end

function love.mousepressed(x, y, button)
    if button == 1 then -- Left mouse button
        if gameState == "start" then
            if pointInCircle(x, y, startButton.x, startButton.y, startButton.radius) then
                gameState = "playing"
                initializeGame()
            end
        elseif gameState == "gameOver" then
            -- Check restart button
            local restartButton = {
                x = love.graphics.getWidth() / 2,
                y = love.graphics.getHeight() / 2 + 150,
                radius = 50
            }
            if pointInCircle(x, y, restartButton.x, restartButton.y, restartButton.radius) then
                gameState = "playing"
                initializeGame()
            end
        end
    end
end

-- Testing damage
function love.keypressed(key)
    if key == "h" and gameState == "playing" then
        showHurt = true
        hurtTimer = 1.0
        currentFace = "hurt"
    elseif key == "escape" then
        if gameState == "playing" or gameState == "gameOver" then
            gameState = "start"
        end
    end
end