-- main.lua

import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/ui"

local ScreenManager = import "scripts/world/screen_manager"
local TitleScreen = import "scripts/screens/title_screen"
local ModeAndOptions = import "scripts/screens/mode_and_options"
local GameScreen = import "scripts/screens/game_screen"
_G.GameScreen = GameScreen
local InitScreen = import "scripts/screens/init_screen"
local OptionsScreen = import "scripts/screens/options_screen"
local Options = import "scripts/world/options"
_G.OptionsScreen = OptionsScreen

local pd <const> = playdate
local gfx <const> = pd.graphics

-- Use import for Playdate Lua, do not use require

-- Set the initial screen (e.g., InitScreen)
ScreenManager.setScreen(InitScreen)

function pd.init()
    ScreenManager.setScreen(InitScreen)
    pd.setRefreshRate(45) -- Set the refresh rate to 45 FPS
end


function pd.update()
    ScreenManager.update()
    ScreenManager.draw()
    pd.timer.updateTimers()
end

function playdate.AButtonDown()
    if ScreenManager.currentScreen and ScreenManager.currentScreen.AButtonDown then
        ScreenManager.currentScreen:AButtonDown()
    end
end

-- Example: Switch to another screen (call this from a screen's update method)

-- Correct way: create an instance and set as current screen
-- local gameScreenInstance = GameScreen:new()
-- ScreenManager.setScreen(gameScreenInstance)