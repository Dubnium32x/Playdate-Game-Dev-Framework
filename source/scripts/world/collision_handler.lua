-- collision_handler.lua
-- Advanced collision detection and resolution system for platformers

local pd <const> = playdate
local gfx <const> = pd.graphics

-- Import needed modules
local PixelCollision = import "scripts/world/pixel_collision"
local TileCollision = import "scripts/world/tile_collision"

local CollisionHandler = {}

-- Debug flag for showing collision info
CollisionHandler.DEBUG = false

-- Constants for different collision types
CollisionHandler.TYPE = {
    NONE = 0,
    FLOOR = 1,
    CEILING = 2,
    WALL_LEFT = 3,
    WALL_RIGHT = 4,
    PLATFORM = 5
}

-- Collision response struct - what was hit and how to resolve
CollisionHandler.Response = {}
CollisionHandler.Response.__index = CollisionHandler.Response

function CollisionHandler.Response.new(collided, type, tileId, tileX, tileY, resolveX, resolveY)
    local self = setmetatable({}, CollisionHandler.Response)
    self.collided = collided or false
    self.type = type or CollisionHandler.TYPE.NONE
    self.tileId = tileId or 0
    self.tileX = tileX or 0
    self.tileY = tileY or 0
    self.resolveX = resolveX or 0
    self.resolveY = resolveY or 0
    return self
end

-- Check collision between an entity and level tiles
function CollisionHandler.checkTileCollision(entity, level, tileSize, tileset)
    if not entity or not level then return end
    
    -- Default tileSize if not specified
    tileSize = tileSize or 16
    
    -- Store original position for reference
    local originalX, originalY = entity.x, entity.y
    
    -- Make sure sensors are updated
    if entity.updateSensors then
        entity.updateSensors(entity)
    end
    
    -- Check for null sensors
    if not entity.sensors then
        print("WARNING: Entity has no sensors!")
        return
    end
    
    -- Setup collection of collision responses
    local responses = {}
    
    -- Check floor collision first (most important for platformers)
    CollisionHandler:checkFloorCollision(entity, level, tileSize, tileset, responses)
    
    -- Check wall collisions next
    CollisionHandler:checkWallCollision(entity, level, tileSize, tileset, responses)
    
    -- Check ceiling collision last
    CollisionHandler:checkCeilingCollision(entity, level, tileSize, tileset, responses)
    
    -- Apply all responses
    for _, response in ipairs(responses) do
        if response.collided then
            -- Apply response positioning
            if response.type == CollisionHandler.TYPE.FLOOR then
                entity.y = response.resolveY
                entity.yspeed = 0
                entity.grounded = true
            elseif response.type == CollisionHandler.TYPE.CEILING then
                entity.y = response.resolveY
                entity.yspeed = 0
            elseif response.type == CollisionHandler.TYPE.WALL_LEFT then
                entity.x = response.resolveX
                entity.xspeed = 0
            elseif response.type == CollisionHandler.TYPE.WALL_RIGHT then
                entity.x = response.resolveX
                entity.xspeed = 0
            elseif response.type == CollisionHandler.TYPE.PLATFORM then
                -- Only land on platforms if falling
                if entity.yspeed >= 0 then
                    entity.y = response.resolveY
                    entity.yspeed = 0
                    entity.grounded = true
                end
            end
        end
    end
    
    -- Update sensors after resolving positions
    if entity.updateSensors then
        entity.updateSensors(entity)
    end
    
    -- Return whether any collision happened
    return #responses > 0
end

-- Check floor collision using bottom sensors
function CollisionHandler:checkFloorCollision(entity, level, tileSize, tileset, responses)
    -- Only check if falling
    if entity.yspeed < 0 then return end
    
    -- Get the bottom sensors
    local bottomLeft = entity.sensors[1]  -- BOTTOM_LEFT
    local bottomRight = entity.sensors[2] -- BOTTOM_RIGHT
    
    if not bottomLeft or not bottomRight then
        print("WARNING: Missing bottom sensors!")
        return
    end
    
    -- Calculate which tiles to check
    local leftTileX = math.floor(bottomLeft.x / tileSize)
    local leftTileY = math.floor(bottomLeft.y / tileSize)
    local rightTileX = math.floor(bottomRight.x / tileSize)
    local rightTileY = math.floor(bottomRight.y / tileSize)
    
    -- Check all ground layers
    local layers = {}
    if level.csv_ground1 then table.insert(layers, {data = level.csv_ground1, name = "Ground1"}) end
    if level.csv_ground2 then table.insert(layers, {data = level.csv_ground2, name = "Ground2"}) end
    if level.csv_ground3 then table.insert(layers, {data = level.csv_ground3, name = "Ground3"}) end
    
    -- Add semisolid layers after ground layers
    if level.csv_semisolid1 then table.insert(layers, {data = level.csv_semisolid1, name = "SemiSolid1"}) end
    if level.csv_semisolid2 then table.insert(layers, {data = level.csv_semisolid2, name = "SemiSolid2"}) end
    if level.csv_semisolid3 then table.insert(layers, {data = level.csv_semisolid3, name = "SemiSolid3"}) end
    
    -- Check each layer
    for _, layer in ipairs(layers) do
        local layerData = layer.data
        local layerName = layer.name
        
        -- Skip layer if no data
        if not layerData then goto continue end
        
        -- Check left sensor
        if leftTileX >= 0 and leftTileY >= 0 and 
           leftTileY < #layerData and leftTileX < #layerData[leftTileY + 1] then
            
            local tileId = layerData[leftTileY + 1][leftTileX + 1]
            if tileId and tileId > 0 then
                -- Determine if it's a platform
                local isSemiSolid = string.sub(layerName, 1, 9) == "SemiSolid"
                
                -- Check pixel-perfect collision if tileset provided
                local hasPixelCollision = true -- Default to true if no tileset
                if tileset then
                    hasPixelCollision = PixelCollision.checkSensorPixelCollision(
                        tileset,
                        tileId + 1, -- Lua indexing adjustment
                        bottomLeft.x,
                        bottomLeft.y,
                        leftTileX,
                        leftTileY,
                        tileSize
                    )
                end
                
                if hasPixelCollision then
                    local resolveY = leftTileY * tileSize - entity.heightrad - 0.1
                    
                    local responseType = isSemiSolid and CollisionHandler.TYPE.PLATFORM or 
                                        CollisionHandler.TYPE.FLOOR
                                        
                    -- Only add platform collision if actually falling onto it from above
                    if responseType ~= CollisionHandler.TYPE.PLATFORM or 
                       (entity.yspeed >= 0 and entity.y - entity.heightrad <= leftTileY * tileSize) then
                        
                        table.insert(responses, CollisionHandler.Response.new(
                            true, responseType, tileId, leftTileX, leftTileY, 0, resolveY
                        ))
                    end
                end
            end
        end
        
        -- Check right sensor
        if rightTileX >= 0 and rightTileY >= 0 and 
           rightTileY < #layerData and rightTileX < #layerData[rightTileY + 1] then
            
            local tileId = layerData[rightTileY + 1][rightTileX + 1]
            if tileId and tileId > 0 then
                -- Determine if it's a platform
                local isSemiSolid = string.sub(layerName, 1, 9) == "SemiSolid"
                
                -- Check pixel-perfect collision if tileset provided
                local hasPixelCollision = true -- Default to true if no tileset
                if tileset then
                    hasPixelCollision = PixelCollision.checkSensorPixelCollision(
                        tileset,
                        tileId + 1, -- Lua indexing adjustment
                        bottomRight.x,
                        bottomRight.y,
                        rightTileX,
                        rightTileY,
                        tileSize
                    )
                end
                
                if hasPixelCollision then
                    local resolveY = rightTileY * tileSize - entity.heightrad - 0.1
                    
                    local responseType = isSemiSolid and CollisionHandler.TYPE.PLATFORM or 
                                        CollisionHandler.TYPE.FLOOR
                                        
                    -- Only add platform collision if actually falling onto it from above
                    if responseType ~= CollisionHandler.TYPE.PLATFORM or 
                       (entity.yspeed >= 0 and entity.y - entity.heightrad <= rightTileY * tileSize) then
                        
                        table.insert(responses, CollisionHandler.Response.new(
                            true, responseType, tileId, rightTileX, rightTileY, 0, resolveY
                        ))
                    end
                end
            end
        end
        
        ::continue::
    end
end

-- Check wall collision using middle sensors
function CollisionHandler:checkWallCollision(entity, level, tileSize, tileset, responses)
    -- Get the middle sensors
    local middleLeft = entity.sensors[3]  -- MIDDLE_LEFT
    local middleRight = entity.sensors[4] -- MIDDLE_RIGHT
    
    if not middleLeft or not middleRight then
        print("WARNING: Missing middle sensors!")
        return
    end
    
    -- Calculate which tiles to check
    local leftTileX = math.floor(middleLeft.x / tileSize)
    local leftTileY = math.floor(middleLeft.y / tileSize)
    local rightTileX = math.floor(middleRight.x / tileSize)
    local rightTileY = math.floor(middleRight.y / tileSize)
    
    -- Check only ground layers for walls (not semisolids)
    local layers = {}
    if level.csv_ground1 then table.insert(layers, {data = level.csv_ground1, name = "Ground1"}) end
    if level.csv_ground2 then table.insert(layers, {data = level.csv_ground2, name = "Ground2"}) end
    if level.csv_ground3 then table.insert(layers, {data = level.csv_ground3, name = "Ground3"}) end
    
    -- Check each layer
    for _, layer in ipairs(layers) do
        local layerData = layer.data
        local layerName = layer.name
        
        -- Skip layer if no data
        if not layerData then goto continue end
        
        -- Check left sensor if moving left
        if entity.xspeed <= 0 and leftTileX >= 0 and leftTileY >= 0 and 
           leftTileY < #layerData and leftTileX < #layerData[leftTileY + 1] then
            
            local tileId = layerData[leftTileY + 1][leftTileX + 1]
            if tileId and tileId > 0 then
                -- Check pixel-perfect collision if tileset provided
                local hasPixelCollision = true -- Default to true if no tileset
                if tileset then
                    hasPixelCollision = PixelCollision.checkSensorPixelCollision(
                        tileset,
                        tileId + 1, -- Lua indexing adjustment
                        middleLeft.x,
                        middleLeft.y,
                        leftTileX,
                        leftTileY,
                        tileSize
                    )
                end
                
                if hasPixelCollision then
                    local resolveX = (leftTileX + 1) * tileSize + entity.widthrad + 0.1
                    table.insert(responses, CollisionHandler.Response.new(
                        true, CollisionHandler.TYPE.WALL_LEFT, tileId, leftTileX, leftTileY, resolveX, 0
                    ))
                end
            end
        end
        
        -- Check right sensor if moving right
        if entity.xspeed >= 0 and rightTileX >= 0 and rightTileY >= 0 and 
           rightTileY < #layerData and rightTileX < #layerData[rightTileY + 1] then
            
            local tileId = layerData[rightTileY + 1][rightTileX + 1]
            if tileId and tileId > 0 then
                -- Check pixel-perfect collision if tileset provided
                local hasPixelCollision = true -- Default to true if no tileset
                if tileset then
                    hasPixelCollision = PixelCollision.checkSensorPixelCollision(
                        tileset,
                        tileId + 1, -- Lua indexing adjustment
                        middleRight.x,
                        middleRight.y,
                        rightTileX,
                        rightTileY,
                        tileSize
                    )
                end
                
                if hasPixelCollision then
                    local resolveX = rightTileX * tileSize - entity.widthrad - 0.1
                    table.insert(responses, CollisionHandler.Response.new(
                        true, CollisionHandler.TYPE.WALL_RIGHT, tileId, rightTileX, rightTileY, resolveX, 0
                    ))
                end
            end
        end
        
        ::continue::
    end
end

-- Check ceiling collision using top sensors
function CollisionHandler:checkCeilingCollision(entity, level, tileSize, tileset, responses)
    -- Only check if moving upward
    if entity.yspeed >= 0 then return end
    
    -- Get the top sensors
    local topLeft = entity.sensors[5]  -- TOP_LEFT
    local topRight = entity.sensors[6] -- TOP_RIGHT
    
    if not topLeft or not topRight then
        print("WARNING: Missing top sensors!")
        return
    end
    
    -- Calculate which tiles to check
    local leftTileX = math.floor(topLeft.x / tileSize)
    local leftTileY = math.floor(topLeft.y / tileSize)
    local rightTileX = math.floor(topRight.x / tileSize)
    local rightTileY = math.floor(topRight.y / tileSize)
    
    -- Check only ground layers for ceiling (not semisolids)
    local layers = {}
    if level.csv_ground1 then table.insert(layers, {data = level.csv_ground1, name = "Ground1"}) end
    if level.csv_ground2 then table.insert(layers, {data = level.csv_ground2, name = "Ground2"}) end
    if level.csv_ground3 then table.insert(layers, {data = level.csv_ground3, name = "Ground3"}) end
    
    -- Check each layer
    for _, layer in ipairs(layers) do
        local layerData = layer.data
        local layerName = layer.name
        
        -- Skip layer if no data
        if not layerData then goto continue end
        
        -- Check left sensor
        if leftTileX >= 0 and leftTileY >= 0 and 
           leftTileY < #layerData and leftTileX < #layerData[leftTileY + 1] then
            
            local tileId = layerData[leftTileY + 1][leftTileX + 1]
            if tileId and tileId > 0 then
                -- Check pixel-perfect collision if tileset provided
                local hasPixelCollision = true -- Default to true if no tileset
                if tileset then
                    hasPixelCollision = PixelCollision.checkSensorPixelCollision(
                        tileset,
                        tileId + 1, -- Lua indexing adjustment
                        topLeft.x,
                        topLeft.y,
                        leftTileX,
                        leftTileY,
                        tileSize
                    )
                end
                
                if hasPixelCollision then
                    local resolveY = (leftTileY + 1) * tileSize + entity.heightrad + 0.1
                    table.insert(responses, CollisionHandler.Response.new(
                        true, CollisionHandler.TYPE.CEILING, tileId, leftTileX, leftTileY, 0, resolveY
                    ))
                end
            end
        end
        
        -- Check right sensor
        if rightTileX >= 0 and rightTileY >= 0 and 
           rightTileY < #layerData and rightTileX < #layerData[rightTileY + 1] then
            
            local tileId = layerData[rightTileY + 1][rightTileX + 1]
            if tileId and tileId > 0 then
                -- Check pixel-perfect collision if tileset provided
                local hasPixelCollision = true -- Default to true if no tileset
                if tileset then
                    hasPixelCollision = PixelCollision.checkSensorPixelCollision(
                        tileset,
                        tileId + 1, -- Lua indexing adjustment
                        topRight.x,
                        topRight.y,
                        rightTileX,
                        rightTileY,
                        tileSize
                    )
                end
                
                if hasPixelCollision then
                    local resolveY = (rightTileY + 1) * tileSize + entity.heightrad + 0.1
                    table.insert(responses, CollisionHandler.Response.new(
                        true, CollisionHandler.TYPE.CEILING, tileId, rightTileX, rightTileY, 0, resolveY
                    ))
                end
            end
        end
        
        ::continue::
    end
end

-- Draw debug information
function CollisionHandler.drawDebug(entity)
    if not CollisionHandler.DEBUG then return end
    
    -- Set drawing style for debug visualization
    gfx.setColor(gfx.kColorWhite)
    gfx.setDitherPattern(0.5)
    
    -- Draw entity bounds
    if entity.x and entity.y and entity.widthrad and entity.heightrad then
        gfx.drawRect(
            entity.x - entity.widthrad, 
            entity.y - entity.heightrad,
            entity.widthrad * 2,
            entity.heightrad * 2
        )
    end
    
    -- Draw sensor points
    if entity.sensors then
        for i, sensor in pairs(entity.sensors) do
            if sensor and sensor.x and sensor.y then
                gfx.fillCircleAtPoint(sensor.x, sensor.y, 2)
                
                -- Draw sensor index
                gfx.drawText(tostring(i), sensor.x + 3, sensor.y - 8)
            end
        end
    end
    
    -- Reset drawing style
    gfx.setColor(gfx.kColorBlack)
    gfx.setDitherPattern(1)
end

return CollisionHandler
