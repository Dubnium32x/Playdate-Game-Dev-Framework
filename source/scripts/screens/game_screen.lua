-- game_screen.lua
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local pd <const> = playdate
local gfx <const> = pd.graphics

local Options = import "scripts/world/options"
local ScreenManager = import "scripts/world/screen_manager"
local Player = import "scripts/player/player"
local csv_loader = import "scripts/util/csv_loader"
local SoundManager = import "scripts/util/sound_manager"
local HUD = import "scripts/screens/hud"

local GameScreen = {}

local currentLevel = 0

GameScreen.cameraX = 0
GameScreen.cameraY = 0

-- Cache tileset to avoid loading it every frame
local cachedTileset = nil
local tileSize = 16

function GameScreen:init() 
    -- Initialize SoundManager if not already initialized
    if SoundManager.init then
        SoundManager:init()
    end
    
    -- Load tileset once during initialization - try different path formats
    cachedTileset = gfx.imagetable.new("sprites/tileset/SPGSolidTileHeightCollision_flipped-table-16-16")
    if not cachedTileset then
        print("Failed to load tileset! Check path and file.")
    else
        print("Tileset loaded successfully with " .. cachedTileset:getLength() .. " images")
    end
    -- Player drawing will be handled in the player script
    self.level = {
        name = "Level_" .. currentLevel,
        tiles = {},
        enemies = {},
        items = {},
        csv_objects1 = nil,
        csv_objects2 = nil,
        csv_objects3 = nil,
        csv_ground1 = csv_loader.load_csv("world/LevelMaps/Level_" .. currentLevel .. "/Level_" .. currentLevel .. "_Ground1.csv"),
        csv_ground2 = nil,
        csv_ground3 = nil,
        csv_semisolid1 = csv_loader.load_csv("world/LevelMaps/Level_" .. currentLevel .. "/Level_" .. currentLevel .. "_SemiSolids1.csv"),
        csv_semisolid2 = nil,
        csv_semisolid3 = nil,
        csv_hazards = nil,
        csv_enemies = nil,
    }
    
    -- Debug CSV loading
    if self.level.csv_ground1 then
        print("Ground1 layer loaded successfully with " .. #self.level.csv_ground1 .. " rows")
    else
        print("Failed to load Ground1 layer!")
    end
    
    if self.level.csv_semisolid1 then
        print("SemiSolid1 layer loaded successfully with " .. #self.level.csv_semisolid1 .. " rows")
    else
        print("Failed to load SemiSolid1 layer!")
    end
    
    -- Pre-process level data for optimization
    self:preprocessLevelData()
    
    -- Initialize Player
    self.player = Player:new("sprites/sprite/sonicanim_idle.png", 29, 40, 100, 200) -- Adjust path and position as needed
    self.player:init()
    
    -- Critical: Set the level reference for the player to enable collision detection
    self.player.level = self.level
    
    -- Initialize HUD
    self.hud = HUD
    
    -- Set frame rate to 45 FPS
    pd.display.setRefreshRate(45)
    
    -- Create a draw buffer for level tiles if supported
    if gfx.lockFocus and pd.display.getWidth then
        self.levelBuffer = gfx.image.new(pd.display.getWidth(), pd.display.getHeight())
        print("Created level buffer for faster drawing")
    end
    
    -- Start gameplay music
    if SoundManager.playMusic then
        SoundManager:playMusic("gameplay")
    end
end

-- Pre-process level data to optimize rendering
function GameScreen:preprocessLevelData()
    -- Pre-process each layer that exists
    if self.level.csv_ground1 then self:preprocessLayer(self.level.csv_ground1) end
    if self.level.csv_ground2 then self:preprocessLayer(self.level.csv_ground2) end
    if self.level.csv_ground3 then self:preprocessLayer(self.level.csv_ground3) end
    if self.level.csv_semisolid1 then self:preprocessLayer(self.level.csv_semisolid1) end
    if self.level.csv_semisolid2 then self:preprocessLayer(self.level.csv_semisolid2) end
    if self.level.csv_semisolid3 then self:preprocessLayer(self.level.csv_semisolid3) end
    
    print("Level data preprocessing complete")
end

-- Pre-process a layer to optimize rendering
function GameScreen:preprocessLayer(layer)
    -- Convert string tile IDs to numbers for faster access
    for row = 1, #layer do
        for col = 1, #layer[row] do
            if layer[row][col] and layer[row][col] ~= "" then
                layer[row][col] = tonumber(layer[row][col])
            else
                layer[row][col] = 0
            end
        end
    end
end

-- Duplicate preprocessLayer function - remove one
function GameScreen:preprocessLayer(layer)
    -- Convert string tile IDs to numbers for faster access
    for row = 1, #layer do
        for col = 1, #layer[row] do
            if layer[row][col] and layer[row][col] ~= "" then
                layer[row][col] = tonumber(layer[row][col])
            else
                layer[row][col] = 0
            end
        end
    end
end

function GameScreen:update()
    if self.player then
        self.player:update()
        -- Camera follows player
        self.cameraX = math.floor(self.player.x - 200) -- 200 = half screen width
        self.cameraY = math.floor(self.player.y - 120) -- 120 = half screen height
        
        -- Update HUD data from player
        if self.hud then
            self.hud:setState({
                score = self.player.score,
                rings = self.player.rings,
                lives = self.player.lives,
                time = (pd.getCurrentTimeMilliseconds() - self.player.startTime) / 1000
            })
        end
    end
    self:handleLevelUpdates()
end


function GameScreen:draw()
    -- Clear the screen
    gfx.clear()

    -- Draw the level tiles
    self:drawLevel()

    -- Draw the player
    if self.player then
        self.player:draw(self.cameraX, self.cameraY)
        
        -- Safely check debug mode setting
        local debugMode = (_G.Options and _G.Options.settings and _G.Options.settings.debugMode) or false
        
        -- Draw debug visuals for sensors only if debug mode is enabled
        if debugMode then
            self.player:drawSensors(self.cameraX, self.cameraY)
        end
    end
    
    -- Draw the HUD last to ensure it's on top of everything else
    self:drawHUD()
end

function GameScreen:drawLevel()
    if not cachedTileset then
        gfx.drawText("Error: Tileset not found!", 10, 30)
        
        -- Try loading tileset again with different path
        cachedTileset = gfx.imagetable.new("sprites/tileset/SPGSolidTileHeightCollision_flipped-table-16-16")
        
        -- If still not loaded, try with just the filename
        if not cachedTileset then
            cachedTileset = gfx.imagetable.new("SPGSolidTileHeightCollision_flipped-table-16-16")
            if not cachedTileset then
                -- Draw placeholder tiles so we can still see something
                for row = 1, 20 do
                    for col = 1, 25 do
                        if (row + col) % 2 == 0 then
                            gfx.fillRect((col-1) * 16 - self.cameraX, 
                                        (row-1) * 16 - self.cameraY, 
                                        16, 16)
                        else
                            gfx.drawRect((col-1) * 16 - self.cameraX, 
                                        (row-1) * 16 - self.cameraY, 
                                        16, 16)
                        end
                    end
                end
                return
            end
        end
    end

    -- Screen dimensions
    local screenWidth = 400
    local screenHeight = 240

    -- Calculate visible tile range
    local startCol = math.max(1, math.floor(self.cameraX / tileSize) + 1)
    local endCol = math.min(startCol + math.ceil(screenWidth / tileSize) + 1, self.level.csv_ground1 and #self.level.csv_ground1[1] or 0)
    local startRow = math.max(1, math.floor(self.cameraY / tileSize) + 1)
    local endRow = math.min(startRow + math.ceil(screenHeight / tileSize) + 1, self.level.csv_ground1 and #self.level.csv_ground1 or 0)

    -- Draw only the layers that exist
    local layers = {}
    if self.level.csv_ground1 then table.insert(layers, {data = self.level.csv_ground1, name = "Ground1"}) end
    if self.level.csv_ground2 then table.insert(layers, {data = self.level.csv_ground2, name = "Ground2"}) end
    if self.level.csv_ground3 then table.insert(layers, {data = self.level.csv_ground3, name = "Ground3"}) end
    if self.level.csv_semisolid1 then table.insert(layers, {data = self.level.csv_semisolid1, name = "SemiSolid1"}) end
    if self.level.csv_semisolid2 then table.insert(layers, {data = self.level.csv_semisolid2, name = "SemiSolid2"}) end
    if self.level.csv_semisolid3 then table.insert(layers, {data = self.level.csv_semisolid3, name = "SemiSolid3"}) end

    -- Only draw object layers if debug mode is enabled
    local debugMode = (_G.Options and _G.Options.settings and _G.Options.settings.debugMode) or false
    if debugMode then
        if self.level.csv_objects1 then table.insert(layers, {data = self.level.csv_objects1, name = "Objects1"}) end
        if self.level.csv_objects2 then table.insert(layers, {data = self.level.csv_objects2, name = "Objects2"}) end
        if self.level.csv_objects3 then table.insert(layers, {data = self.level.csv_objects3, name = "Objects3"}) end
        if self.level.csv_hazards then table.insert(layers, {data = self.level.csv_hazards, name = "Hazards"}) end
        if self.level.csv_enemies then table.insert(layers, {data = self.level.csv_enemies, name = "Enemies"}) end
    end

    for _, layer in ipairs(layers) do
        local csv = layer.data
        if csv then
            for row = startRow, endRow do
                if csv[row] then
                    for col = startCol, endCol do
                        if csv[row][col] and csv[row][col] ~= 0 then
                            local tileId = csv[row][col]
                            -- Draw the tile
                            local x = (col - 1) * tileSize - self.cameraX
                            local y = (row - 1) * tileSize - self.cameraY
                            
                            -- Add 1 to tileId for Lua indexing (already converted to number in preprocessLayer)
                            cachedTileset:drawImage(tileId + 1, x, y)
                        end
                    end
                end
            end
        end
    end

    -- Only show level name in debug mode
    local debugMode = (_G.Options and _G.Options.settings and _G.Options.settings.debugMode) or false
    if debugMode then
        gfx.drawText("Level: " .. self.level.name, 10, 10)
    end
end

function GameScreen:drawHUD()
    -- Use the dedicated HUD module to draw the HUD
    if self.hud then
        self.hud:draw()
    end
    
    -- Show FPS in debug mode only
    local debugMode = (_G.Options and _G.Options.settings and _G.Options.settings.debugMode) or false
    if debugMode then
        gfx.setImageDrawMode(gfx.kDrawModeNXOR)
        gfx.drawText("FPS: " .. math.floor(pd.getFPS() or 0), 320, 10)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end
end

function GameScreen:handleLevelUpdates()
    -- Only perform necessary updates
    -- No empty loops or expensive calculations
    
    -- If we have enemies, update them here
    -- If we have collectibles, check for collection here
    
    -- Check for level boundaries to prevent player from going off-screen
    if self.player.x < 0 then self.player.x = 0 end
    
    -- Calculate level width based on ground layer if available
    local levelWidth = 0
    if self.level.csv_ground1 and self.level.csv_ground1[1] then
        levelWidth = #self.level.csv_ground1[1] * tileSize
    end
    
    -- Prevent camera from showing beyond level boundaries
    if self.cameraX < 0 then self.cameraX = 0 end
    if levelWidth > 0 and self.cameraX > levelWidth - 400 then self.cameraX = levelWidth - 400 end
    if self.cameraY < 0 then self.cameraY = 0 end
end

_G.GameScreen = GameScreen
return GameScreen