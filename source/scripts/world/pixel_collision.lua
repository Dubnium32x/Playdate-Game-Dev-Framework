-- pixel_collision.lua
-- Advanced pixel-perfect collision detection for tiles

local pd <const> = playdate
local gfx <const> = pd.graphics

local PixelCollision = {}

-- Debug flag - set to true for visual debugging, false for production
PixelCollision.DEBUG = false

-- Cache for tile images to avoid reloading and improve performance
local tileImageCache = {}

-- Cache size limit to prevent memory issues
local CACHE_SIZE_LIMIT = 100
local cacheAccessOrder = {}

-- Helper function to get a tile image from cache or load it
function PixelCollision.getTileImage(tileset, tileId)
    if not tileset or not tileId then return nil end
    
    local cacheKey = tostring(tileset) .. "_" .. tostring(tileId)
    
    if tileImageCache[cacheKey] then
        -- Move this item to the front of the access order (most recently used)
        for i, key in ipairs(cacheAccessOrder) do
            if key == cacheKey then
                table.remove(cacheAccessOrder, i)
                break
            end
        end
        table.insert(cacheAccessOrder, 1, cacheKey)
        return tileImageCache[cacheKey]
    end
    
    -- Image not in cache, load it
    local tileImage = tileset:getImage(tileId)
    
    if tileImage then
        -- Check if cache is full
        if #cacheAccessOrder >= CACHE_SIZE_LIMIT then
            -- Remove least recently used item
            local oldKey = cacheAccessOrder[#cacheAccessOrder]
            tileImageCache[oldKey] = nil
            table.remove(cacheAccessOrder)
        end
        
        -- Add new item to cache
        tileImageCache[cacheKey] = tileImage
        table.insert(cacheAccessOrder, 1, cacheKey)
    end
    
    return tileImage
end

-- Check if a point collides with an opaque pixel in a tile
function PixelCollision.checkPixelCollision(tileset, tileId, localX, localY)
    if not tileset or not tileId or tileId <= 0 then
        if PixelCollision.DEBUG then
            print("PixelCollision: Invalid parameters - tileset:", tileset, "tileId:", tileId)
        end
        return false
    end
    
    -- Get the tile image
    local tileImage = PixelCollision.getTileImage(tileset, tileId)
    if not tileImage then
        if PixelCollision.DEBUG then
            print("PixelCollision: Failed to get tile image for tileId:", tileId)
        end
        return false
    end
    
    -- Get image dimensions
    local width, height = tileImage:getSize()
    
    -- Make sure coordinates are within bounds
    if localX < 0 or localX >= width or localY < 0 or localY >= height then
        if PixelCollision.DEBUG then
            print("PixelCollision: Coordinates out of bounds - localX:", localX, "localY:", localY, 
                  "size:", width, "x", height)
        end
        return false
    end
    
    -- On Playdate, we can use the sample method to check if a pixel is opaque
    local alpha = tileImage:sample(localX, localY)
    
    -- In Playdate 1-bit graphics, alpha is either 0 (transparent) or 1 (opaque)
    local result = alpha > 0
    
    if result and PixelCollision.DEBUG then
        print("PixelCollision: Collision detected at", localX, localY, "in tile", tileId)
    end
    
    return result
end

-- Check collision between a sensor point and a tile with pixel precision
function PixelCollision.checkSensorPixelCollision(tileset, tileId, sensorX, sensorY, tileX, tileY, tileSize)
    -- Calculate local coordinates within the tile
    local localX = math.floor(sensorX - tileX * tileSize)
    local localY = math.floor(sensorY - tileY * tileSize)
    
    if PixelCollision.DEBUG then
        print("Checking sensor collision at:", sensorX, sensorY, "tile:", tileX, tileY, 
              "local coords:", localX, localY)
    end
    
    -- Check if the local coordinates are within the tile bounds
    if localX < 0 or localX >= tileSize or localY < 0 or localY >= tileSize then
        if PixelCollision.DEBUG then
            print("Sensor coords outside tile bounds")
        end
        return false
    end
    
    -- Check pixel collision
    return PixelCollision.checkPixelCollision(tileset, tileId, localX, localY)
end

-- Enhanced collision check with multiple sample points for better precision
function PixelCollision.checkMultiPointCollision(tileset, tileId, x, y, width, height, tileX, tileY, tileSize)
    -- Calculate local coordinates within the tile
    local localX = math.floor(x - tileX * tileSize)
    local localY = math.floor(y - tileY * tileSize)
    
    -- Check a 3x3 grid of points within the collision box for better precision
    local halfWidth = width / 2
    local halfHeight = height / 2
    
    -- Check center point
    if PixelCollision.checkPixelCollision(tileset, tileId, localX, localY) then
        return true
    end
    
    -- Check corners and edges
    local points = {
        {localX - halfWidth, localY - halfHeight}, -- Top-left
        {localX, localY - halfHeight},            -- Top-center
        {localX + halfWidth, localY - halfHeight}, -- Top-right
        {localX - halfWidth, localY},             -- Middle-left
        {localX + halfWidth, localY},             -- Middle-right
        {localX - halfWidth, localY + halfHeight}, -- Bottom-left
        {localX, localY + halfHeight},            -- Bottom-center
        {localX + halfWidth, localY + halfHeight}  -- Bottom-right
    }
    
    for _, point in ipairs(points) do
        local px, py = point[1], point[2]
        if px >= 0 and px < tileSize and py >= 0 and py < tileSize then
            if PixelCollision.checkPixelCollision(tileset, tileId, px, py) then
                return true
            end
        end
    end
    
    return false
end

-- Visual debug drawing for collision detection
function PixelCollision.drawDebug()
    if not PixelCollision.DEBUG then return end
    
    -- Set drawing style for debug visualization
    gfx.setColor(gfx.kColorWhite)
    gfx.setDitherPattern(0.5)
    
    -- Draw cache information
    gfx.drawText("Collision Cache: " .. #cacheAccessOrder .. "/" .. CACHE_SIZE_LIMIT, 10, 180)
    
    -- Reset drawing style
    gfx.setColor(gfx.kColorBlack)
    gfx.setDitherPattern(1)
end

-- Clear tile image cache (use when switching levels)
function PixelCollision.clearCache()
    tileImageCache = {}
    cacheAccessOrder = {}
    collectgarbage("collect")
    if PixelCollision.DEBUG then
        print("PixelCollision: Cache cleared")
    end
end

return PixelCollision
