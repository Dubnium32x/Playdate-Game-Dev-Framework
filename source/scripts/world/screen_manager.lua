-- screen_manager.lua
-- Simple screen manager for Playdate, inspired by Presto-Framework

local screen_manager = {}

local currentScreen = nil

function screen_manager.setScreen(screen)
    currentScreen = screen
    if currentScreen and currentScreen.init then currentScreen:init() end
end

function screen_manager.update()
    if currentScreen and currentScreen.update then currentScreen:update() end
end

function screen_manager.draw()
    if currentScreen and currentScreen.draw then currentScreen:draw() end
end

_G.ScreenManager = screen_manager
return screen_manager
