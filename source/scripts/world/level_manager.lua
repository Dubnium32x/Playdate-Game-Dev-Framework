-- LevelManager.lua
-- Handles loading and switching between levels
import "CoreLibs/object"
import "CoreLibs/graphics"


local Level = import("level")
local LevelManager = {}
LevelManager.__index = LevelManager

function LevelManager.new(levelList)
    local self = setmetatable({}, LevelManager)
    self.levelList = levelList or {}
    self.currentIndex = 1
    self.currentLevel = nil
    self:loadCurrentLevel()
    return self
end

function LevelManager:loadCurrentLevel()
    local entry = self.levelList[self.currentIndex]
    if entry then
        self.currentLevel = Level.new(entry.levelName, entry.layerName)
    end
end

function LevelManager:nextLevel()
    if self.currentIndex < #self.levelList then
        self.currentIndex = self.currentIndex + 1
        self:loadCurrentLevel()
    end
end

function LevelManager:prevLevel()
    if self.currentIndex > 1 then
        self.currentIndex = self.currentIndex - 1
        self:loadCurrentLevel()
    end
end

function LevelManager:draw()
    if self.currentLevel then
        self.currentLevel:draw()
    end
end

return LevelManager
