-- game_screen.lua
import "CoreLibs/graphics"
import "CoreLibs/object"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/ui"

local csv_loader = import "scripts/util/csv_loader"
local gfx <const> = playdate.graphics

local GameScreen = {}

function GameScreen:init()
	-- Load level CSV
	self.level_data = csv_loader.load_csv("world/LevelMaps/Level_0/Level_0_SemiSolids1.csv")
	self.tileSize = 16
	self.imageTable = gfx.imagetable.new("sprites/tileset/SPGSolidTileHeightCollision_flipped-table-16-16.png")
	print("[DEBUG] Loaded level with rows:", #self.level_data)
end

function GameScreen:update()
	-- No player logic yet
end

function GameScreen:draw()
	gfx.clear()
	-- Draw the tilemap
	for y, row in ipairs(self.level_data) do
		for x, tile in ipairs(row) do
			if tile and tile ~= 0 and tile ~= -1 then
				local img = self.imageTable:getImage(tile)
				if img then
					img:draw((x-1)*self.tileSize, (y-1)*self.tileSize)
				end
			end
		end
	end
end

return GameScreen
