-- Level.lua
-- Represents a single level and its data
local Level = {}
Level.__index = Level

function Level.new(levelName, layerName)
    local self = setmetatable({}, Level)
    self.levelName = levelName
    self.layerName = layerName or nil
    self.tilemap = nil
    self.playerStart = {x = 0, y = 0}
    self:load()
    return self
end

function Level:load()
    -- Load the tilemap for this level
    self.tilemap = LDtk.create_tilemap(self.levelName, self.layerName)
    -- TODO: Load player start position from entities or fields if present
end

function Level:draw(x, y)
    if self.tilemap then
        self.tilemap:draw(x or 0, y or 0)
    end
end

return Level
