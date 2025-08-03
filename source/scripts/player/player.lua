-- player.lua

-- Import the CoreLibs modules for essential functionalities
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

import "extensions/AnimatedSprite"

local pd <const> = playdate
local gfx <const> = pd.graphics

local GamePhysics = import "scripts/player/game_physics"
local var = import "scripts/player/var"
local TileCollision = import "scripts/world/tile_collision"
-- Import PixelCollision at the global level to prevent scope issues
_G.PixelCollision = import "scripts/world/pixel_collision"

-- Player state enums
local PlayerState = {
    IDLE = 1,
    IMPATIENT = 2,
    IDLE_BALANCE_F = 3,
    IDLE_BALANCE_B = 4,
    CROUCH = 5,
    LOOK_UP = 6,
    WALK = 7,
    RUN = 8,
    DASH = 9,
    PEELOUT = 10,
    SPINDASH_CHARGE = 11,
    ROLL = 12,
    JUMP = 13,
    JUMP_FALL = 14,
    FALLING = 15,
    HURT = 16,
    DEAD = 17,
    SPINNING = 18
}

local Character = {
    Sonic,
    Amy,
    Honey
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
    local obj = setmetatable({}, self)
    self.__index = self
    -- Initialization code here
    self.var = var
    self.physics = GamePhysics:new()
    -- PixelCollision is available globally

    -- DEBUG
    print("Player.new() called with spriteSheetPath: " .. tostring(spriteSheetPath))

    -- Load the player static image
    self.image = gfx.image.new(tostring(spriteSheetPath))
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
    self.startTime = playdate.getCurrentTimeMilliseconds()

    -- Initialize player Character
    self.character = Character.Sonic -- Default character
    self.state = PlayerState.IDLE

    return obj
end

function Player:updateSensors()
    -- Initialize sensors array if needed
    if not self.sensors then
        self.sensors = {}
    end
    
    -- Make sure width and height radii are properly set
    self.widthrad = self.widthrad or 14  -- Default to half sprite width
    self.heightrad = self.heightrad or 20 -- Default to half sprite height
    
    -- Bottom sensors (for ground detection) - positioned at the feet
    self.sensors[Sensor.BOTTOM_LEFT] = {
        x = self.x - self.widthrad * 0.8,  -- Further out for better edge detection
        y = self.y + self.heightrad
    }
    self.sensors[Sensor.BOTTOM_RIGHT] = {
        x = self.x + self.widthrad * 0.8,  -- Further out for better edge detection
        y = self.y + self.heightrad
    }
    
    -- Middle sensors (for wall detection) - positioned at the center of the body sides
    self.sensors[Sensor.MIDDLE_LEFT] = {
        x = self.x - self.widthrad,
        y = self.y
    }
    self.sensors[Sensor.MIDDLE_RIGHT] = {
        x = self.x + self.widthrad,
        y = self.y
    }
    
    -- Top sensors (for ceiling detection) - positioned at the head
    self.sensors[Sensor.TOP_LEFT] = {
        x = self.x - self.widthrad * 0.7,  -- Adjusted for better ceiling detection
        y = self.y - self.heightrad
    }
    self.sensors[Sensor.TOP_RIGHT] = {
        x = self.x + self.widthrad * 0.7,  -- Adjusted for better ceiling detection
        y = self.y - self.heightrad
    }
end

function Player:init()
    -- Initialize sprite with animations
    local states = {
        { name = "idle", frames = {1}, loop = true },
        { name = "walk", frames = {2,3,4,5}, loop = true },
        { name = "run", frames = {2,3,4,5}, loop = true }, -- Reuse walk frames for now
        { name = "jump", frames = {1}, loop = false },
        { name = "jump_fall", frames = {1}, loop = false },
        { name = "falling", frames = {1}, loop = false }
        -- Add other states as needed
    }
    self.sprite = AnimatedSprite:new(self.image, states)
    self.sprite:moveTo(self.x, self.y)
    self.sprite:setScale(1.0)
    
    -- Play the initial idle animation directly
    self.sprite:playAnimation("idle")
    
    -- Initialize sensors
    self.sensors = {}
    
    -- Set physics properties using GamePhysics
    if not self.physics then
        self.physics = GamePhysics:new()
    end
    
    -- Player dimensions - set to match sprite dimensions (29x40 divided by 2)
    self.widthrad = 14  -- Half of 29 (rounded down)
    self.heightrad = 20 -- Half of 40
    
    -- Physics constants (fallbacks if not in physics object)
    self.gravity = self.physics.gravity or 0.3125
    self.maxFallSpeed = self.physics.maxFallSpeed or 14.0
    self.jumpforce = 6.0 -- Consistent with var.jumpforce
    self.groundStabilityCounter = 0
    self.framesNotGrounded = 0
    
    -- Initialize player state for collision
    self.isRolling = false
    self.rollTimer = 0
    self.canExitRoll = false
    
    -- Initialize ground stability system - prevent single frame air states
    self.groundStabilityCounter = 0
    self.groundStabilityMax = 8 -- Increased to prevent "in air" flashes
    self.framesNotGrounded = 0
    self.groundedToleranceFrames = 3 -- Allow this many frames of being "ungrounded" before truly being in air
    
    -- Initialize sensors manually
    self:updateSensors()
    
    print("Player initialized at position:", self.x, self.y)
    print("Physics settings: gravity =", self.gravity, "maxFall =", self.maxFallSpeed)
end

function Player:draw(cameraX, cameraY)
    cameraX = cameraX or 0
    cameraY = cameraY or 0
    
    -- Draw player sprite
    if self.image then
        self.image:drawCentered(self.x - cameraX, self.y - cameraY)
    end
end

function Player:setSprite(sprite)
    if not sprite then
        print("Warning: setSprite called with nil sprite")
        return
    end

    -- Try to play animation based on state, with fallback
    local success = false
    
    if self.state == PlayerState.IDLE then 
        success = sprite:playAnimation("idle")
    elseif self.state == PlayerState.IMPATIENT then 
        success = sprite:playAnimation("impatient") 
    elseif self.state == PlayerState.IDLE_BALANCE_F then 
        success = sprite:playAnimation("idle_balance_f")
    elseif self.state == PlayerState.IDLE_BALANCE_B then 
        success = sprite:playAnimation("idle_balance_b")
    elseif self.state == PlayerState.CROUCH then 
        success = sprite:playAnimation("crouch")
    elseif self.state == PlayerState.LOOK_UP then 
        success = sprite:playAnimation("look_up")
    elseif self.state == PlayerState.WALK then 
        success = sprite:playAnimation("walk")
    elseif self.state == PlayerState.RUN then 
        success = sprite:playAnimation("run")
    elseif self.state == PlayerState.DASH then 
        success = sprite:playAnimation("dash")
    elseif self.state == PlayerState.PEELOUT then 
        success = sprite:playAnimation("peelout")
    elseif self.state == PlayerState.SPINDASH_CHARGE then 
        success = sprite:playAnimation("spindash_charge")
    elseif self.state == PlayerState.ROLL then 
        success = sprite:playAnimation("roll")
    elseif self.state == PlayerState.JUMP then 
        success = sprite:playAnimation("jump")
    elseif self.state == PlayerState.JUMP_FALL then 
        success = sprite:playAnimation("jump_fall")
    elseif self.state == PlayerState.FALLING then 
        success = sprite:playAnimation("falling")
    elseif self.state == PlayerState.HURT then 
        success = sprite:playAnimation("hurt")
    elseif self.state == PlayerState.DEAD then 
        success = sprite:playAnimation("dead")
    elseif self.state == PlayerState.SPINNING then 
        success = sprite:playAnimation("spinning")
    end
    
    -- Default to idle if no animation matched or if previous attempt failed
    if not success then
        sprite:playAnimation("idle")
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

function Player:update()
    -- Import collision handler module if needed
    if not self.collisionHandler then
        self.collisionHandler = import "scripts/world/collision_handler"
    end
    
    self:processInput()
    
    -- Store previous position for collision
    local prevX, prevY = self.x, self.y
    
    -- Apply variable gravity based on jump state
    if not self.grounded then
        local gravityValue = self.physics.gravity or 0.3125
        
        -- Apply sonic-style jump physics
        if self.yspeed < 0 and self.keyActionHeld then
            -- Lower gravity when holding jump button during ascent (but less reduction)
            self.yspeed = self.yspeed + gravityValue * 0.85
        else
            -- Regular gravity otherwise
            self.yspeed = self.yspeed + gravityValue
        end
        
        -- Clamp maximum fall speed
        if self.yspeed > self.physics.maxFallSpeed then
            self.yspeed = self.physics.maxFallSpeed
        end
    end
    
    -- Handle jumping - use the jumpforce property
    if self.grounded and self.keyActionPressed then
        -- Apply jump force
        self.yspeed = -self.jumpforce
        self.grounded = false
        
        -- Change state to jumping
        self.state = PlayerState.JUMP
        
        -- Clear ground stability counter
        self.groundStabilityCounter = 0
    end
    
    -- Ground movement
    if self.grounded then
        -- Get physics values
        local acc = self.physics.acceleration or 0.046875
        local dec = self.physics.deceleration or 0.5
        local fric = self.physics.friction or 0.046875
        local top = self.physics.topspeed or 6.0
        
        if self.keyLeft and not self.keyRight then
            -- If moving right but trying to go left, apply deceleration (turn-around)
            if self.xspeed > 0 then
                self.xspeed = self.xspeed - dec
                -- If deceleration would reverse direction, stop at 0
                if self.xspeed < 0 then self.xspeed = 0 end
            -- Normal acceleration to the left
            else
                self.xspeed = self.xspeed - acc
                -- Cap maximum speed
                if self.xspeed < -top then
                    self.xspeed = -top
                end
            end
            
            -- Update state and facing
            if self.state ~= PlayerState.JUMP and self.state ~= PlayerState.JUMP_FALL then
                if math.abs(self.xspeed) > 3.0 then
                    self.state = PlayerState.RUN -- Higher speed = run
                else
                    self.state = PlayerState.WALK -- Lower speed = walk
                end
                self.facing = -1
            end
        elseif self.keyRight and not self.keyLeft then
            -- If moving left but trying to go right, apply deceleration (turn-around)
            if self.xspeed < 0 then
                self.xspeed = self.xspeed + dec
                -- If deceleration would reverse direction, stop at 0
                if self.xspeed > 0 then self.xspeed = 0 end
            -- Normal acceleration to the right
            else
                self.xspeed = self.xspeed + acc
                -- Cap maximum speed
                if self.xspeed > top then
                    self.xspeed = top
                end
            end
            
            -- Update state and facing
            if self.state ~= PlayerState.JUMP and self.state ~= PlayerState.JUMP_FALL then
                if math.abs(self.xspeed) > 3.0 then
                    self.state = PlayerState.RUN -- Higher speed = run
                else
                    self.state = PlayerState.WALK -- Lower speed = walk
                end
                self.facing = 1
            end
        else
            -- No input - apply friction
            if math.abs(self.xspeed) > fric then
                if self.xspeed > 0 then
                    self.xspeed = self.xspeed - fric
                else
                    self.xspeed = self.xspeed + fric
                end
            else
                -- If speed is very low, just stop completely
                self.xspeed = 0
            end
            
            -- Update state if virtually stopped
            if math.abs(self.xspeed) < 0.1 and self.state ~= PlayerState.JUMP and self.state ~= PlayerState.JUMP_FALL then
                self.state = PlayerState.IDLE
            end
        end
    else
        -- Air movement - according to Sonic Physics Guide
        local airAcc = 0.09375 -- Air acceleration (0.09375 per frame in Sonic games)
        local airTopSpeed = self.physics.topspeed or 6.0 -- Same as ground top speed
        
        if self.keyLeft and not self.keyRight then
            -- Apply air acceleration to the left
            self.xspeed = self.xspeed - airAcc
            
            -- Cap maximum speed
            if self.xspeed < -airTopSpeed then
                self.xspeed = -airTopSpeed
            end
            
            self.facing = -1
        elseif self.keyRight and not self.keyLeft then
            -- Apply air acceleration to the right
            self.xspeed = self.xspeed + airAcc
            
            -- Cap maximum speed
            if self.xspeed > airTopSpeed then
                self.xspeed = airTopSpeed
            end
            
            self.facing = 1
        end
        
        -- Update state for jumping/falling
        if self.yspeed < 0 then
            self.state = PlayerState.JUMP
        else
            self.state = PlayerState.JUMP_FALL
        end
    end
    
    -- Apply movement
    self.x = self.x + self.xspeed
    self.y = self.y + self.yspeed
    
    -- Reset grounded state before collision checks
    if self.groundStabilityCounter <= 0 then
        self.grounded = false
    else
        self.groundStabilityCounter = self.groundStabilityCounter - 1
    end
    
    -- Update sensor positions after movement but before collision
    self:updateSensors()
    
    -- Check for and resolve collisions using the new CollisionHandler
    if self.level and (self.level.csv_ground1 or self.level.csv_semisolid1) then
        -- Get the collision tileset
        local tileset = self.collisionTileset
        
        -- Try to initialize tileset if not already done
        if not tileset then
            self.collisionTileset = gfx.imagetable.new("sprites/tileset/SPGSolidTileHeightCollision_flipped-table-16-16")
            tileset = self.collisionTileset
        end
        
        -- Use the collision handler to check collisions
        self.collisionHandler.checkTileCollision(self, self.level, 16, tileset)
        
        -- Handle ground stability
        if self.grounded then
            -- Always keep the stability counter at maximum while grounded
            self.groundStabilityCounter = self.groundStabilityMax or 8
            self.framesNotGrounded = 0
            
            -- Change the player state based on grounding and speed
            if math.abs(self.xspeed) > 3.0 then
                self.state = PlayerState.RUN
            elseif math.abs(self.xspeed) > 0.5 then
                self.state = PlayerState.WALK
            else
                self.state = PlayerState.IDLE
            end
        else
            -- Increment frames not grounded
            self.framesNotGrounded = (self.framesNotGrounded or 0) + 1
            
            -- Tolerance for short un-grounded periods
            if self.framesNotGrounded <= (self.groundedToleranceFrames or 3) then
                self.grounded = true
            end
        end
    else
        -- Debug output to trace which condition failed
        if not self.level then
            print("No level reference!")
        elseif not self.level.csv_ground1 and not self.level.csv_semisolid1 then
            print("No ground or semisolid layer found in level!")
        end
    end
    
    -- Update sensor positions again after collision resolution
    self:updateSensors()
    
    -- Update sprite animation based on state (safely)
    if self.sprite then
        -- Set the animation based on player state
        if self.state == PlayerState.IDLE then 
            self.sprite:playAnimation("idle")
        elseif self.state == PlayerState.WALK or self.state == PlayerState.RUN then 
            self.sprite:playAnimation("walk")
        elseif self.state == PlayerState.JUMP then
            self.sprite:playAnimation("jump")
        elseif self.state == PlayerState.JUMP_FALL or self.state == PlayerState.FALLING then
            self.sprite:playAnimation("jump_fall")
        else
            -- Default to idle if animation not available
            self.sprite:playAnimation("idle")
        end
        
        -- Update sprite position
        self.sprite:moveTo(self.x, self.y)
        
        -- Update sprite facing direction if supported
        if self.sprite.setScale then
            self.sprite:setScale(self.facing, 1) -- Flip sprite based on facing direction
        end
    end
    
    -- Store ground speed for reference (useful for loops and slopes later)
    self.groundspeed = self.xspeed
end

function Player:drawSensors(cameraX, cameraY)
    -- Import collision handler module if needed
    if not self.collisionHandler then
        self.collisionHandler = import "scripts/world/collision_handler"
    end
    
    -- Default camera values if not provided
    cameraX = cameraX or 0
    cameraY = cameraY or 0
    
    -- Save the original position to restore later
    local originalX, originalY = self.x, self.y
    
    -- Temporarily offset the player by camera position for proper drawing
    self.x = self.x - cameraX
    self.y = self.y - cameraY
    
    -- Update sensors to the adjusted position
    self:updateSensors()
    
    -- Set NXOR drawing mode for better text visibility
    gfx.setImageDrawMode(gfx.kDrawModeNXOR)
    
    -- Draw detailed physics debugging information
    gfx.drawText("Status: " .. (self.grounded and "GROUNDED" or "IN AIR"), 10, 80)
    gfx.drawText(string.format("Pos: %.1f, %.1f", originalX, originalY), 10, 100)
    gfx.drawText(string.format("Speed: %.1f, %.1f", self.xspeed, self.yspeed), 10, 120)
    
    -- Draw current state name (compact)
    local stateNames = {
        [1] = "IDLE", [2] = "IMPATIENT", [3] = "I_BAL_F", [4] = "I_BAL_B",
        [5] = "CROUCH", [6] = "LOOK_UP", [7] = "WALK", [8] = "RUN",
        [9] = "DASH", [10] = "PEELOUT", [11] = "SDASH", [12] = "ROLL",
        [13] = "JUMP", [14] = "J_FALL", [15] = "FALL", [16] = "HURT",
        [17] = "DEAD", [18] = "SPIN"
    }
    local stateName = stateNames[self.state] or "?"
    gfx.drawText("State: " .. stateName, 10, 140)
    
    -- Enable debug drawing in collision handler
    self.collisionHandler.DEBUG = true
    
    -- Draw collision debug information
    self.collisionHandler.drawDebug(self)
    
    -- PixelCollision debug information
    local PixelCollision = import "scripts/world/pixel_collision"
    PixelCollision.DEBUG = true
    PixelCollision.drawDebug()
    
    -- Reset debug flags after drawing
    self.collisionHandler.DEBUG = false
    PixelCollision.DEBUG = false
    
    -- Reset to normal drawing mode
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    
    -- Restore original position
    self.x = originalX
    self.y = originalY
    
    -- Update sensors back to the original position
    self:updateSensors()
end

-- This function has been replaced by the CollisionHandler module
--[[
function Player:checkCollisions(level, tileSize)
    -- This legacy function is no longer used
    -- See collision_handler.lua for the new implementation
end
]]

_G.Player = Player
return Player
