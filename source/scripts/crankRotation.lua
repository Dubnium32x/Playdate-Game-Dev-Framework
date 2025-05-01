-- crankRotation.lua

import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

-- Shorthand for graphics modules
local pd <const> = playdate
local gfx <const> = pd.graphics

CrankRotation = {}

function CrankRotation:new(sprite)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self

    obj.sprite = sprite
    obj.angle = 0 -- Initial rotation angle
    obj.lastCrankPosition = playdate.getCrankPosition()

    return obj
end

function CrankRotation:update()
    local newCrankPosition = playdate.getCrankPosition()
    local crankDelta = playdate.getCrankChange()

    -- Rotate the sprite based on crank movement
    self.angle = self.angle + crankDelta
    self.sprite:setRotation(self.angle)

    self.lastCrankPosition = newCrankPosition
end
