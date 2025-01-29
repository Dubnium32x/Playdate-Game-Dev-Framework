-- main.lua

-- Import CoreLibs modules for essential functionalities
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/ui"

-- Import scripts
import "scripts/playerMovement"

-- Shorthand for the graphics modules and playdate specific functions
local pd <const> = playdate
local gfx <const> = pd.graphics

-- Global variables for your game (if needed)
local currentScreenIndex = 1 -- Example starting screen index
local player = nil

-- INITIALIZE
function pd.init()
    -- Create the player using the Player class from playerMovement.lua
    player = Player.new(nil, "sprites/avatar", 8, 16, 200, 180) -- Example sprite sheet (requires nil first for "self")
    pd:draw()
end

-- UPDATE
function pd.update()
    -- Draw the FPS
    pd.drawFPS(0,0)

    -- Update the player movement and animation
    player:update()

    -- Example input: Change the screen index when the player presses the A or B button
    if pd.buttonJustPressed(pd.kButtonA) then
        currentScreenIndex = currentScreenIndex + 1 -- Increment the screen index    
        pd:draw()
    elseif pd.buttonJustPressed(pd.kButtonB) then
        currentScreenIndex = math.max(1, currentScreenIndex - 1) -- Decrement the screen index, with a minimum of 1
        pd:draw()
    end   
    gfx.sprite.update()
    pd.timer.updateTimers()
    gfx.drawTextAligned("Screen Index: " .. tostring(currentScreenIndex), 200, 120, kTextAlignment.center) -- Draw text centered on the screen

end

-- DRAW BACKGROUND
function pd.draw()
    gfx.clear()
    gfx.setFont(gfx.getSystemFont("normal"), "normal") -- Set the default system font
    gfx.setImageDrawMode(gfx.kDrawModeFillBlack) -- Set the default image draw mode
    gfx.drawTextAligned("Screen Index: " .. tostring(currentScreenIndex), 200, 120, kTextAlignment.center) -- Draw text centered on the screen
end

-- Run initialization
pd.init()