-- player.lua

-- Import the CoreLibs modules for essential functionalities
import "CoreLibs/object"
import "var"
import "game_physics"

-- Player state enums
local PlayerState = {
    IDLE = 1,
    WALK = 2,
    RUN = 3,
    JUMP = 4,
    FALL = 5,
    ROLL = 6,
    HURT = 7,
    DEAD = 8
}

local KeyDefine = {
    LEFT = playdate.kButtonLeft,
    RIGHT = playdate.kButtonRight,
    UP = playdate.kButtonUp,
    DOWN = playdate.kButtonDown,
    ACTION = playdate.kButtonA,
    ACTION2 = playdate.kButtonB
}

local Sensor = {
    BOTTOM_LEFT = 1,
    BOTTOM_RIGHT = 2,
    MIDDLE_LEFT = 3,
    MIDDLE_RIGHT = 4,
    TOP_LEFT = 5,
    TOP_RIGHT = 6
}

-- Shorthand for the graphics modules and playdate specific functions
local pd <const> = playdate
local gfx <const> = pd.graphics


local Player = {
    image = nil,
    x = 0,
    y = 0
}
Player.__index = Player


function Player:new(spriteSheetPath, frameWidth, frameHeight, startX, startY)
    local self = setmetatable({}, Player)
    self.var = var
    self.physics = GamePhysics:new()

    -- DEBUG
    print("Player.new() called with spriteSheetPath: " .. tostring(spriteSheetPath))

    -- Load the player static image
    self.image = gfx.image.new(spriteSheetPath)
    assert(self.image, "Failed to load player image! Check file path and format.")
    self.x = startX
    self.y = startY

    -- Initialize player state
    self.xspeed = 0
    self.yspeed = 0
    self.grounded = false
    self.rings = 0
    self.lives = 3
    self.score = 0
    self.facing = 1 -- 1 for right, -1 for left
function Player:draw()
    if self.image then
        self.image:draw(self.x, self.y)
    end
end
end

function Player:processInput()
    self.keyLeft = playdate.buttonIsPressed(KeyDefine.LEFT)
    self.keyRight = playdate.buttonIsPressed(KeyDefine.RIGHT)
    self.keyUp = playdate.buttonIsPressed(KeyDefine.UP)
    self.keyDown = playdate.buttonIsPressed(KeyDefine.DOWN)
    self.keyActionPressed = playdate.buttonJustPressed(KeyDefine.ACTION)
    self.keyActionHeld = playdate.buttonIsPressed(KeyDefine.ACTION)
    self.keyAction2Pressed = playdate.buttonJustPressed(KeyDefine.ACTION2)
end

function Player:updateSensors()
    local x = self.var.x
    local y = self.var.y
    local w = self.var.widthrad
    local h = self.var.heightrad
    self.sensors[Sensor.BOTTOM_LEFT]  = {x = x - w * 0.7, y = y + h}
    self.sensors[Sensor.BOTTOM_RIGHT] = {x = x + w * 0.7, y = y + h}
    self.sensors[Sensor.MIDDLE_LEFT]  = {x = x - w, y = y}
    self.sensors[Sensor.MIDDLE_RIGHT] = {x = x + w, y = y}
    self.sensors[Sensor.TOP_LEFT]     = {x = x - w * 0.7, y = y - h}
    self.sensors[Sensor.TOP_RIGHT]    = {x = x + w * 0.7, y = y - h}
end

function Player:update()
    -- Basic gravity
    local gravity = 0.5
    self.yspeed = self.yspeed + gravity
    self.y = self.y + self.yspeed
    -- Simple ground collision at y = 180
    if self.y > 180 then
        self.y = 180
        self.yspeed = 0
    end
    self:processInput()
    local moveSpeed = self.physics.topspeed or 2
    local isMoving = false

    -- Simple movement logic (expand with physics/collision later)
    if self.keyUp then
        self.var.y = self.var.y - moveSpeed
        isMoving = true
    end
    if self.keyRight then
        self.var.x = self.var.x + moveSpeed
        isMoving = true
        self.facing = 1
    end
    if self.keyDown then
        self.var.y = self.var.y + moveSpeed
        isMoving = true
    end
    if self.keyLeft then
        self.var.x = self.var.x - moveSpeed
        isMoving = true
        self.facing = -1
    end

    -- Update sensors for collision (stub)
    self:updateSensors()

    -- Move sprite to new position
    self.sprite:moveTo(self.var.x, self.var.y)

    -- State transitions (expand as needed)

    if isMoving then
        self.state = PlayerState.WALK
        self.sprite:playAnimation("walk")
    else
        self.state = PlayerState.IDLE
        self.sprite:playAnimation("idle")
    end
end

function Player:drawSensors()
    -- Debug: draw sensor points
    gfx.setColor(gfx.kColorBlack)
    if self.sensors then
        for _, s in pairs(self.sensors) do
            if s and s.x and s.y then
                gfx.fillCircleAtPoint(s.x, s.y, 2)
            end
        end
    end
end

_G.Player = Player
return Player