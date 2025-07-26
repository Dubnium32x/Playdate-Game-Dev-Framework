-- main.lua

import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/ui"

-- Create default options globally to avoid nil errors
_G.Options = {
    settings = {
        debugMode = true,
        soundEnabled = true,
        musicEnabled = true,
        startingLives = 3
    }
}

-- Uncomment one of these lines to run diagnostic tools
-- import "image_path_tester"
-- import "file_system_tester" 
-- import "test_imagetable"

-- Print working directory to help with debugging paths
print("Working directory information:")

-- List files in sprites directory to find the correct path
local function listFiles(path)
    print("Checking path: " .. path)
    local files, err = playdate.file.listFiles(path)
    if files then
        for i=1, #files do
            print("  " .. files[i])
        end
        return true
    else
        print("  Error: " .. tostring(err))
        return false
    end
end

-- Try to locate the tileset files
listFiles(".")
listFiles("sprites")
listFiles("source/sprites/tileset")

local ScreenManager = import "scripts/world/screen_manager"
local TitleScreen = import "scripts/screens/title_screen"
local GameScreen = import "scripts/screens/game_screen"
_G.GameScreen = GameScreen
local InitScreen = import "scripts/screens/init_screen"
local OptionsScreen = import "scripts/screens/options_screen"
local Options = import "scripts/world/options"
_G.Options = Options  -- Make Options globally accessible
_G.OptionsScreen = OptionsScreen

local pd <const> = playdate
local gfx <const> = pd.graphics

-- Use import for Playdate Lua, do not use require

-- Set the initial screen (e.g., InitScreen)
ScreenManager.setScreen(InitScreen)

function pd.init()
    -- Initialize options first and store in global for safety
    if Options and Options.init then
        Options:init()
        print("Options initialized successfully")
    else
        print("WARNING: Options module not available!")
        -- Create a default Options.settings for safety
        _G.Options = _G.Options or {}
        _G.Options.settings = _G.Options.settings or {
            debugMode = true,  -- Default to debug mode on for safety
            soundEnabled = true,
            musicEnabled = true
        }
    end
    
    -- Then set the screen
    ScreenManager.setScreen(InitScreen)
    
    -- Set refresh rate
    pd.display.setRefreshRate(45) -- Correct way to set refresh rate to 45 FPS
    
    -- Disable unnecessary system features to save CPU
    if pd.setAutoLockDisabled then
        pd.setAutoLockDisabled(true)
    end
end


function pd.update()
    -- Track time for performance monitoring
    local startTime = pd.getCurrentTimeMilliseconds()
    
    -- Process game logic
    ScreenManager.update()
    
    -- Draw game
    ScreenManager.draw()
    
    -- Update timers
    pd.timer.updateTimers()
    
    -- Calculate frame time for performance monitoring
    local frameTime = pd.getCurrentTimeMilliseconds() - startTime
    _G.lastFrameTime = frameTime
end

function pd.draw()
    -- Set NXOR drawing mode for better text visibility
    gfx.setImageDrawMode(gfx.kDrawModeNXOR)
    
    -- Draw FPS counter (always show it during development)
    pd.drawFPS(380, 4)
    
    -- Get debug mode setting safely
    local debugMode = (_G.Options and _G.Options.settings and _G.Options.settings.debugMode) or false
    
    -- Draw frame time if available
    if _G.lastFrameTime then
        local y = 20
        gfx.drawText("Frame: " .. math.floor(_G.lastFrameTime) .. "ms", 300, y)
        
        -- Provide performance warning if frame time is high
        if _G.lastFrameTime > 20 then
            gfx.drawText("⚠️ Heavy frame", 300, y + 15)
        end
    end
    
    -- Reset to normal drawing mode
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function playdate.AButtonDown()
    if ScreenManager.currentScreen and ScreenManager.currentScreen.AButtonDown then
        ScreenManager.currentScreen:AButtonDown()
    end
end

-- Example: Switch to another scr\een (call this from a screen's update method)

-- Correct way: create an instance and set as current screen
-- local gameScreenInstance = GameScreen:new()
-- ScreenManager.setScreen(gameScreenInstance)

pd.init()