-- main.lua
function love.load()
    love.window.setTitle("Factory Part Sorting Game")
    love.window.setMode(1000, 900)
    score = 0
    partLanded = false
    currentPlatformIndex = 1

    -- Platform
    platforms = {}

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

    partTypes = {
        {type = "red", color = {1, 0, 0}, binX = 200},
        {type = "green", color = {0, 1, 0}, binX = 350},
        {type = "blue", color = {0, 0, 1}, binX = 500}
    }

    -- Choose a random type
    local randomType = partTypes[math.random(#partTypes)]

    part = {
        x = 400,
        y = 0,
        size = 20,
        vx = 0,
        vy = 100,
        onPlatform = false,
        type = randomType.type,
        color = randomType.color
    }
    -- Bins
    bins = {
        {x = 150, width = 150, color = {1, 0, 0}}, -- Red
        {x = 425, width = 150, color = {0, 1, 0}}, -- Green
        {x = 700, width = 150, color = {0, 0, 1}} -- Blue
    }
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
        part.vy = 100
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
end

function spawnNewPart()
    local randomType = partTypes[math.random(#partTypes)]

    currentPlatformIndex = 1
    local platform = platforms[currentPlatformIndex]

    part = {
        x = platform.x,
        y = platform.y - 100,
        size = 20,
        vx = 0,
        vy = 100,
        onPlatform = false,
        type = randomType.type,
        color = randomType.color
    }

    platform.canTilt = false
    platform.angle = 0
end

