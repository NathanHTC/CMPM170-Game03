local robot = { x = 64, y = 64, speed = 30 }
local doors = {
    { x = 128, y = 64, open = false }
}
local switches = {
    { x = 32, y = 64, active = false }
}

function love.load()
    love.graphics.setFont(love.graphics.newFont(14))
end

function love.update(dt)
    -- Robot moves automatically if the door is open
    if doors[1].open then
        robot.x = robot.x + robot.speed * dt
    end
end

function love.draw()
    -- Draw Robot
    love.graphics.setColor(0, 1, 0)
    love.graphics.rectangle("fill", robot.x, robot.y, 16, 16)

    -- Draw Door
    love.graphics.setColor(0.3, 0.3, 1)
    if not doors[1].open then
        love.graphics.rectangle("fill", doors[1].x, doors[1].y, 16, 32)
    end

    -- Draw Switch
    love.graphics.setColor(1, 1, 0)
    love.graphics.rectangle("fill", switches[1].x, switches[1].y, 16, 16)
end

function love.mousepressed(x, y, button)
    if button == 1 then
        -- Check if switch is clicked
        local s = switches[1]
        if x >= s.x and x <= s.x + 16 and y >= s.y and y <= s.y + 16 then
            s.active = not s.active
            doors[1].open = not doors[1].open

            -- Twist: activating door also triggers a trap (example logic)
            if s.active then
                print("You unknowingly activated a trap elsewhere...")
            end
        end
    end
end