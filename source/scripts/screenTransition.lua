-- screenTransition.lua

-- functionality does not work, rather this is just a simple framework for someone to use

import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

-- Shorthand for graphics modules
local pd <const> = playdate
local gfx <const> = pd.graphics

ScreenTransition = {}

-- Create ScreenTransition
function ScreenTransition:new(speed)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self

    obj.alpha = 0       -- Opacity (0 = fully transparent, 1 = fully black)
    obj.speed = speed or 0.05 -- Speed of fade
    obj.fadingIn = false
    obj.fadingOut = false
    obj.onComplete = nil

    return obj
end

-- Effect Managers
function ScreenTransition:startFadeOut(onComplete)
    self.fadingOut = true
    self.fadingIn = false
    self.onComplete = onComplete
end

function ScreenTransition:startFadeIn(onComplete)
    self.fadingIn = true
    self.fadingOut = false
    self.onComplete = onComplete
end

-- Update
function ScreenTransition:update()
    if self.fadingOut then
        self.alpha = math.min(self.alpha + self.speed, 1)
        if self.alpha >= 1 then
            self.fadingOut = false
            if self.onComplete then self.onComplete() end -- Trigger callback
        end
    elseif self.fadingIn then
        self.alpha = math.max(self.alpha - self.speed, 0)
        if self.alpha <= 0 then
            self.fadingIn = false
            if self.onComplete then self.onComplete() end -- Trigger callback
        end
    end
end

function ScreenTransition:draw()
    if self.alpha > 0 then
        gfx.setColor(gfx.kColorBlack)
        gfx.setDitherPattern(self.alpha) -- Smooth fade effect
        gfx.fillRect(0, 0, 400, 240)
    end
end

