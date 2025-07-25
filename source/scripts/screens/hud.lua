-- hud.lua
-- Simple HUD for Sonic-style platformer

import "CoreLibs/graphics"
local gfx <const> = playdate.graphics

local HUD = {}

HUD.score = 0
HUD.rings = 0
HUD.lives = 3
HUD.time = 0
HUD.levelName = "LEVEL 1"

function HUD:setState(state)
    if state.score then self.score = state.score end
    if state.rings then self.rings = state.rings end
    if state.lives then self.lives = state.lives end
    if state.levelName then self.levelName = state.levelName end
    if state.time then self.time = state.time end
end

HUD.font = gfx.font.new("fonts/m6x11")

function HUD:update(dt)
    -- Update time (dt in seconds)
    self.time = self.time + dt
end

function HUD:draw()
    gfx.setFont(self.font)
    gfx.setImageDrawMode(gfx.kDrawModeNXOR) -- Use XOR mode for better contrast
    -- Score
    gfx.drawText("SCORE: " .. tostring(self.score), 10, 10)
    -- Rings
    gfx.drawText("RINGS: " .. tostring(self.rings), 10, 46)
    -- Lives
    gfx.drawText("LIVES: " .. tostring(self.lives), 10, 220)
    -- Time (mm:ss)
    local minutes = math.floor(self.time / 60)
    local seconds = math.floor(self.time % 60)
    gfx.drawText(string.format("TIME: %02d:%02d", minutes, seconds), 10, 28)
    -- Nevermind on level name...
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

return HUD
