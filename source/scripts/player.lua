-- playerMovement.lua

-- Import the CoreLibs modules for essential functionalities
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"

-- Import the AnimatedSprite module
import "extensions/AnimatedSprite"

-- Shorthand for the graphics modules and playdate specific functions
local pd <const> = playdate
local gfx <const> = pd.graphics

-- Create Player class
Player = {}
Player.__index = Player

-- Constructor to initialize the player object with animations
function Player:new(spriteSheetPath, frameWidth, frameHeight, startX, startY)
    local self = setmetatable({}, Player)

    -- DEBUG
    print("Player.new() called with spriteSheetPath: " .. spriteSheetPath)
    
    -- Load the player sprite sheet
    local spriteTable = gfx.imagetable.new(spriteSheetPath, 8, 16) -- Example frame dimensions
    assert(spriteTable, "Failed to load player sprite sheet! Check file path and format.") -- Use this to check if the image is loaded successfully
    
    self.sprite = AnimatedSprite.new(spriteTable) -- Create an animated sprite using the sprite sheet
    assert(self.sprite, "Failed to create player sprite!") -- Use this to check if the sprite is created successfully

    -- Set the player sprite properties
    self.sprite:setSize(frameWidth, frameHeight)
    self.sprite:moveTo(startX, startY) -- Set the player sprite position
    self.sprite:add() -- Add the player sprite to the update loop
    
    -- Add animation states
    self.sprite:addState("idle", 1, 1, {tickStep = 1, loop = true})
    self.sprite:addState("walk", 2, 4, {tickStep = 0.1, loop = true})
    self.sprite:playAnimation("idle") -- Play the idle animation by default 
    
    return self
end

-- Update function to handle player movement and animation
function Player:update()
    local moveSpeed = 2 -- Pixels per frame
    local isMoving = false -- Track if the player is moving

    -- Movement and state switching logic
    if playdate.buttonIsPressed(playdate.kButtonUp) then
        self.sprite:moveBy(0, -moveSpeed)
        isMoving = true
    end
    if playdate.buttonIsPressed(playdate.kButtonRight) then
        self.sprite:moveBy(moveSpeed, 0)
        isMoving = true
    end
    if playdate.buttonIsPressed(playdate.kButtonDown) then
        self.sprite:moveBy(0, moveSpeed)
        isMoving = true
    end
    if playdate.buttonIsPressed(playdate.kButtonLeft) then
        self.sprite:moveBy(-moveSpeed, 0)
        isMoving = true
    end

    -- Update animation state based on movement
    if isMoving then
        self.sprite:playAnimation("walk") -- Play walk animation if moving
    else
        self.sprite:playAnimation("idle") -- Default to idle if not moving
    end
end

return Player