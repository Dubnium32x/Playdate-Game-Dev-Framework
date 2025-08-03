-- AlphaCollision.lua
-- Advanced collision detection using alpha channel information from tiles
-- This provides more precise collision than simple tile-based detection

local pd <const> = playdate
local gfx <const> = pd.graphics

local AlphaCollision = {}

-- Cache for processed tile collision data
local tileCollisionCache = {}

-- Helper function to get collision data for a tile
function AlphaCollision.getTileCollisionData(tileset, tileId)
    local cacheKey = tostring(tileset) .. "_" .. tostring(tileId)
    
    if not tileCollisionCache[cacheKey] then
        -- Load the tile image and process its collision data
        local tileImage = tileset:getImage(tileId)
        if not tileImage then
            return nil
        end
        
        local width, height = tileImage:getSize()
        local collisionData = {}
        
        -- Sample every pixel to build collision map
        for y = 0, height - 1 do
            collisionData[y] = {}
            for x = 0, width - 1 do
                -- Check if pixel is opaque (1) or transparent (0)
                local alpha = tileImage:sample(x, y)
                collisionData[y][x] = alpha > 0
            end
        end
        
        tileCollisionCache[cacheKey] = {
            data = collisionData,
            width = width,
            height = height
        }
    end
    
    return tileCollisionCache[cacheKey]
end

-- Check if a point collides with a solid pixel in a tile
function AlphaCollision.checkPointCollision(tileset, tileId, localX, localY)
    if not tileset or not tileId or tileId <= 0 then
        return false
    end
    
    local collisionData = AlphaCollision.getTileCollisionData(tileset, tileId)
    if not collisionData then
        return false
    end
    
    -- Clamp coordinates to tile bounds
    localX = math.max(0, math.min(collisionData.width - 1, math.floor(localX)))
    localY = math.max(0, math.min(collisionData.height - 1, math.floor(localY)))
    
    return collisionData.data[localY] and collisionData.data[localY][localX] or false
end

-- Find the height of solid pixels at a given X coordinate (for ground collision)
function AlphaCollision.getHeightAt(tileset, tileId, localX)
    if not tileset or not tileId or tileId <= 0 then
        return -1
    end
    
    local collisionData = AlphaCollision.getTileCollisionData(tileset, tileId)
    if not collisionData then
        return -1
    end
    
    localX = math.max(0, math.min(collisionData.width - 1, math.floor(localX)))
    
    -- Scan from top to bottom to find first solid pixel
    for y = 0, collisionData.height - 1 do
        if collisionData.data[y] and collisionData.data[y][localX] then
            return y
        end
    end
    
    return -1 -- No solid pixels found
end

-- Find the ceiling height at a given X coordinate (for ceiling collision)
function AlphaCollision.getCeilingAt(tileset, tileId, localX)
    if not tileset or not tileId or tileId <= 0 then
        return -1
    end
    
    local collisionData = AlphaCollision.getTileCollisionData(tileset, tileId)
    if not collisionData then
        return -1
    end
    
    localX = math.max(0, math.min(collisionData.width - 1, math.floor(localX)))
    
    -- Scan from bottom to top to find first solid pixel
    for y = collisionData.height - 1, 0, -1 do
        if collisionData.data[y] and collisionData.data[y][localX] then
            return y
        end
    end
    
    return -1 -- No solid pixels found
end

-- Check collision for a sensor point with world coordinates
function AlphaCollision.checkSensorCollision(tileset, tileId, sensorX, sensorY, tileX, tileY, tileSize)
    -- Convert world coordinates to local tile coordinates
    local localX = sensorX - (tileX * tileSize)
    local localY = sensorY - (tileY * tileSize)
    
    return AlphaCollision.checkPointCollision(tileset, tileId, localX, localY)
end

-- Get ground height for a sensor at world coordinates
function AlphaCollision.getSensorGroundHeight(tileset, tileId, sensorX, tileY, tileSize)
    local localX = sensorX - (math.floor(sensorX / tileSize) * tileSize)
    local height = AlphaCollision.getHeightAt(tileset, tileId, localX)
    
    if height >= 0 then
        return (tileY * tileSize) + height
    end
    
    return -1
end

-- Clear the collision cache (useful for memory management)
function AlphaCollision.clearCache()
    tileCollisionCache = {}
end

return AlphaCollision