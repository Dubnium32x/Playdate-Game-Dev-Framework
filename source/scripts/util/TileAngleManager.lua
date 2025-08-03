-- TileAngleManager.lua
-- Manages tile angles for slope physics and collision detection
-- Uses Sonic-style angle system (0-255 hex values)

local GamePhysics = require "scripts/player/game_physics"

local TileAngleManager = {}

-- Tile angle definitions (in hex values, 0-255 range)
-- 0 = flat, 64 = 90 degrees, 128 = 180 degrees, 192 = 270 degrees
TileAngleManager.tileAngles = {
    [0] = 0,     -- Empty tile
    [1] = 0,     -- Half slab (bottom)
    [2] = 32,    -- 45° slope (1 by 1)
    [3] = 16,    -- 22.5° slope (2 by 1 - gentle part)
    [4] = 16,    -- 22.5° slope (2 by 1 - steep part)
    [5] = 0,     -- Full solid tile
    [6] = 48,    -- 67.5° slope (3 by 1 - steep)
    [7] = 32,    -- 45° slope (3 by 1 - medium)
    [8] = 16,    -- 22.5° slope (3 by 1 - gentle)
    [9] = 45,    -- 63.4° slope (1 by 2 - steep)
    [10] = 19,   -- 26.6° slope (1 by 2 - gentle)
    [11] = 51,   -- 71.6° slope (1 by 3 - steep)
    [12] = 32,   -- 45° slope (1 by 3 - medium)
    [13] = 13,   -- 18.4° slope (1 by 3 - gentle)
    [14] = 0,    -- Half slab (right)
    [15] = 0,    -- Half slab (bottom)
}

-- Height maps for different slope tiles (normalized to 16x16 tile)
TileAngleManager.heightMaps = {
    -- Tile 2: 45° slope (1 by 1)
    [2] = {
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
    },
    
    -- Tile 3: 22.5° slope (2 by 1 - gentle part)
    [3] = {
        0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7
    },
    
    -- Tile 4: 22.5° slope (2 by 1 - steep part)
    [4] = {
        8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13, 14, 14, 15, 15
    },
    
    -- Tile 6: 67.5° slope (3 by 1 - steep)
    [6] = {
        0, 1, 3, 4, 6, 7, 9, 10, 12, 13, 15, 15, 15, 15, 15, 15
    },
    
    -- Tile 7: 45° slope (3 by 1 - medium) 
    [7] = {
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
    },
    
    -- Tile 8: 22.5° slope (3 by 1 - gentle)
    [8] = {
        0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5
    },
    
    -- Add more height maps as needed for other slope tiles
}

-- Get the angle for a specific tile ID
function TileAngleManager.getTileAngle(tileId)
    return TileAngleManager.tileAngles[tileId] or 0
end

-- Get the angle in degrees for a specific tile ID
function TileAngleManager.getTileAngleDegrees(tileId)
    local hexAngle = TileAngleManager.getTileAngle(tileId)
    local physics = GamePhysics:new()
    return physics:angleHexToDegrees(hexAngle)
end

-- Check if a tile is a slope
function TileAngleManager.isSlope(tileId)
    local angle = TileAngleManager.getTileAngle(tileId)
    return angle ~= 0 and TileAngleManager.heightMaps[tileId] ~= nil
end

-- Get height at a specific X position within a tile
function TileAngleManager.getHeightAt(tileId, localX, tileSize)
    tileSize = tileSize or 16
    local heightMap = TileAngleManager.heightMaps[tileId]
    
    if not heightMap then
        -- Non-slope tile
        if TileAngleManager.tileAngles[tileId] == 0 then
            return tileSize - 1 -- Full height for solid tiles
        else
            return -1 -- No collision for empty tiles
        end
    end
    
    -- Clamp localX to valid range
    localX = math.max(0, math.min(tileSize - 1, math.floor(localX)))
    
    -- Scale the index for the height map (assuming 16-pixel resolution)
    local index = math.floor((localX / tileSize) * 16) + 1
    index = math.max(1, math.min(16, index))
    
    local height = heightMap[index]
    if height then
        -- Scale height back to tile size
        return math.floor((height / 15) * (tileSize - 1))
    end
    
    return -1
end

-- Get the surface normal angle at a specific position on a slope
function TileAngleManager.getSurfaceAngle(tileId, localX)
    local baseAngle = TileAngleManager.getTileAngle(tileId)
    
    -- For now, return the base angle
    -- More sophisticated implementations could calculate varying angles
    -- based on the specific position on curved slopes
    return baseAngle
end

-- Check if player should be affected by slope physics
function TileAngleManager.shouldUseSlopePhysics(tileId, playerAngle)
    if not TileAngleManager.isSlope(tileId) then
        return false
    end
    
    local tileAngle = TileAngleManager.getTileAngle(tileId)
    local angleDiff = math.abs(tileAngle - playerAngle)
    
    -- Use slope physics if the angle difference is reasonable
    return angleDiff < 64 -- Within 90 degrees
end

-- Convert tile angle to surface normal vector
function TileAngleManager.angleToNormal(hexAngle)
    local physics = GamePhysics:new()
    
    -- Surface normal is perpendicular to the surface (add 64 to get 90 degrees)
    local normalAngle = (hexAngle + 64) % 256
    
    local normalX = physics:angleHexCos(normalAngle) / 256.0
    local normalY = physics:angleHexSin(normalAngle) / 256.0
    
    return normalX, normalY
end

-- Calculate slope force for physics
function TileAngleManager.getSlopeForce(tileId, gravityStrength)
    if not TileAngleManager.isSlope(tileId) then
        return 0, 0
    end
    
    local angle = TileAngleManager.getTileAngle(tileId)
    local physics = GamePhysics:new()
    
    -- Calculate the component of gravity along the slope
    local slopeForceX = physics:angleHexSin(angle) * gravityStrength / 256.0
    local slopeForceY = physics:angleHexCos(angle) * gravityStrength / 256.0
    
    return slopeForceX, slopeForceY
end

return TileAngleManager