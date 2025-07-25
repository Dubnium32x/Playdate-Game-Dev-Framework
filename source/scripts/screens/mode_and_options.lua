local ModeAndOptions = {}

function ModeAndOptions:init()
    -- Placeholder: setup for mode/options screen
end

function ModeAndOptions:update()
    -- Placeholder: handle input for mode/options screen
end

function ModeAndOptions:draw()
    playdate.graphics.clear()
    playdate.graphics.drawTextAligned("Mode & Options Screen (placeholder)", 200, 120, kTextAlignment.center)
end

return ModeAndOptions
