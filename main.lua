local robotFaces = {}
local currentFace = "happy"
local previousFace = "happy"
local showHurt = false
local hurtTimer = 0
local lastHappiness = 100

local waitToSpawnTimer = 0
local waitingToSpawn = false

-- Conveyor belt variables
local conveyorDirection = 0 -- -1 for left, 1 for right, 0 for stopped
local arrowAnimationTimer = 0
local arrowSpacing = 40
local arrowSpeed = 2 -- Speed of arrow animation

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

    --load robot faces assets
    robotFaces = {
        happy = love.graphics.newImage("assets/robotsmile.png"),
        neutral = love.graphics.newImage("assets/robotneutral.png"),
        sad = love.graphics.newImage("assets/robotsad.png"),
        hurt = love.graphics.newImage("assets/robothurt.png")
    }
    
    -- Happiness bar settings
    maxHappiness = 100
    currentHappiness = maxHappiness
    happinessDecreasePerScore = 5 -- How much happiness decreases per point scored
    happinessIncreasePerMistake = 5 -- How much happiness increases when player makes mistake
    
    -- Happiness bar visual settings
    happinessBar = {
        x = 880,          -- X position (adjusted to center with robot)
        y = 180,           -- Y position from top
        width = 30,       -- Width of the bar
        height = 400,     -- Height of the bar
        borderWidth = 2   -- Border thickness
    }

    platforms = Platform.createPlatforms()
    partTypes = Bin.types
    bins = Bin.bins

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

-- Function to draw conveyor arrows on a platform
function drawConveyorArrows(platform)
    if conveyorDirection == 0 then return end -- No arrows when stopped
    
    love.graphics.setColor(0.8, 0.8, 0.8, 0.7) -- Light gray, semi-transparent
    
    local arrowSize = 8
    local platformLeft = platform.x - platform.width / 2
    local platformRight = platform.x + platform.width / 2
    local platformY = platform.y - platform.height / 2 - 5 -- Slightly above platform
    
    -- Calculate animated offset for moving effect
    local animatedOffset = (arrowAnimationTimer * arrowSpeed * 60) % arrowSpacing
    
    -- Draw arrows across the platform width
    local startX = platformLeft + animatedOffset
    if conveyorDirection == -1 then
        startX = platformRight - animatedOffset
    end
    
    local numArrows = math.ceil(platform.width / arrowSpacing) + 2 -- Extra arrows for smooth animation
    
    for i = 0, numArrows do
        local arrowX
        if conveyorDirection == 1 then -- Right
            arrowX = startX + (i * arrowSpacing)
        else -- Left
            arrowX = startX - (i * arrowSpacing)
        end
        
        -- Only draw arrows within platform bounds
        if arrowX >= platformLeft and arrowX <= platformRight then
            -- Draw arrow pointing in conveyor direction
            if conveyorDirection == 1 then -- Right arrow
                love.graphics.polygon("fill", 
                    arrowX - arrowSize, platformY - arrowSize/2,
                    arrowX + arrowSize, platformY,
                    arrowX - arrowSize, platformY + arrowSize/2
                )
            else -- Left arrow
                love.graphics.polygon("fill", 
                    arrowX + arrowSize, platformY - arrowSize/2,
                    arrowX - arrowSize, platformY,
                    arrowX + arrowSize, platformY + arrowSize/2
                )
            end
        end
    end
end

function love.update(dt)
    -- Update arrow animation timer
    arrowAnimationTimer = arrowAnimationTimer + dt
    
    part.onPlatform = false
    for i, platform in ipairs(platforms) do
        -- Check if the part's left or right edge is on the platform
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
            currentPlatformIndex = i
            part.onPlatform = true
            part.vy = 0
            part.y = platformTop - part.size / 2
            break
        end
    end

    -- If not on any platform, resume falling
    if not part.onPlatform then
        if part.vy >= 0 then -- Only reset if not already boosted upward
            part.vy = 300 -- Increased from 100 to make parts fall faster
        end
        part.y = part.y + part.vy * dt
    end

    -- Conveyor belt control (replaces tilting)
    if love.keyboard.isDown("a") then
        conveyorDirection = -1 -- Move left
    elseif love.keyboard.isDown("d") then
        conveyorDirection = 1  -- Move right
    else
        conveyorDirection = 0  -- Stop
    end

    -- Apply conveyor movement to part when on platform
    if part.onPlatform and conveyorDirection ~= 0 then
        local conveyorSpeed = 150 -- Pixels per second
        part.vx = conveyorDirection * conveyorSpeed
        part.x = part.x + part.vx * dt
    else
        part.vx = 0
    end

    -- Manage robot face based on happiness or damage
    if showHurt then
        hurtTimer = hurtTimer - dt
        if hurtTimer <= 0 then
            showHurt = false
            currentFace = previousFace
        end
    end

    -- Update current expression based on happiness (only when not hurt)
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

    -- Save current happiness for next frame comparison
    lastHappiness = currentHappiness

    if not partLanded and part.y + part.size / 2 >= groundY then
        partLanded = true
        local hitBin = false
        
        for _, bin in ipairs(bins) do
            if part.x >= bin.x and part.x <= bin.x + bin.width then
                hitBin = true
                if bin.color[1] == part.color[1] and bin.color[2] ==
                    part.color[2] and bin.color[3] == part.color[3] then
                    print("log: Correct bin")
                    score = score + 1
                    -- Decrease happiness when score increases (this will trigger hurt animation)
                    currentHappiness = math.max(0, currentHappiness - happinessDecreasePerScore)
                else
                    print("Log: Wrong bin")
                    -- FIXED: Don't trigger hurt animation for wrong bin - robot should be happier
                    -- Decrease score and increase happiness when player makes mistake
                    score = math.max(0, score - 1) -- Prevent negative scores
                    currentHappiness = math.min(maxHappiness, currentHappiness + happinessIncreasePerMistake)
                    
                    -- Update face immediately to reflect increased happiness
                    if currentHappiness >= 65 then
                        currentFace = "happy"
                    elseif currentHappiness >= 40 then
                        currentFace = "neutral"
                    else
                        currentFace = "sad"
                    end
                end
                break -- Exit loop once we've found the bin the part landed in
            end
        end

        part.vy = 0

        -- Trigger delay before spawning new part
        waitingToSpawn = true
        waitToSpawnTimer = 0.5
    end

    if waitingToSpawn then
        waitToSpawnTimer = waitToSpawnTimer - dt
        if waitToSpawnTimer <= 0 then
            spawnNewPart()
            partLanded = false
            waitingToSpawn = false
        end
    end
end

function love.draw()
    -- Draw platforms
    for _, p in ipairs(platforms) do
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("fill", p.x - p.width / 2, p.y - p.height / 2, p.width, p.height)
        
        -- Draw conveyor arrows on platforms when part is on them
        if part.onPlatform and platforms[currentPlatformIndex] == p then
            drawConveyorArrows(p)
        end
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
    
    love.graphics.setColor(1, 1, 1)

    if robotFaces[currentFace] then
        love.graphics.setColor(1, 1, 1)
        local faceImage = robotFaces[currentFace]
        if faceImage then
            local scale = 0.2
            local imgWidth = faceImage:getWidth()
            local imgHeight = faceImage:getHeight()
        
            local offsetX = -115 -- move image left (adjusted for centering)
            local offsetY = 10  -- move image down
            local drawX = happinessBar.x - imgWidth * scale - offsetX
            local drawY = happinessBar.y - imgHeight * scale + offsetY
        
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(faceImage, drawX, drawY, 0, scale, scale)
        end
    end
    
    love.graphics.print(math.floor(currentHappiness) .. "%", bar.x - 5, bar.y + bar.height + 10)
    
    -- Draw score
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Score: " .. score, 10, 10)
    
    -- Draw controls instruction
    love.graphics.print("Hold A/D to move conveyor left/right", 10, 30)
end

function spawnNewPart()
    part, currentPlatformIndex = Part.spawnNew(partTypes, platforms)
end

--for testing
function love.keypressed(key)
    if key == "h" then
        -- Simulate damage
        showHurt = true
        hurtTimer = 1.0
        currentFace = "hurt"
    end
end