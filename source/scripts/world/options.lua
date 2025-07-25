import "CoreLibs/save"

local pd <const> = playdate
local gfx <const> = pd.graphics

local Options = {}
Options.settings = {
    soundEnabled = true,
    musicEnabled = true,
    startingLives = 3,
    peeloutEnabled = true,
    debugMode = false,
    timeoverEnabled = true,
    levelSelectEnabled = false
}

function Options:load()
    local savedData = pd.datastore.read("options")
    if savedData then
        self.settings = savedData
    else
        print("[Options] No saved options found, using defaults.")
    end
end

function Options:save()
    pd.datastore.write("options", self.settings)
end

function Options:init()
    self:load()
    print("[Options] Settings loaded:", self.settings)
end

function Options:toggleSound()
    self.settings.soundEnabled = not self.settings.soundEnabled
    self:save()
end

function Options:toggleMusic()
    self.settings.musicEnabled = not self.settings.musicEnabled
    self:save()
end

function Options:setStartingLives(lives)
    self.settings.startingLives = lives
    self:save()
end

function Options:togglePeelout()
    self.settings.peeloutEnabled = not self.settings.peeloutEnabled
    self:save()
end

function Options:toggleDebugMode()
    self.settings.debugMode = not self.settings.debugMode
    self:save()
end

function Options:toggleTimeover()
    self.settings.timeoverEnabled = not self.settings.timeoverEnabled
    self:save()
end

function Options:toggleLevelSelect()
    self.settings.levelSelectEnabled = not self.settings.levelSelectEnabled
    self:save()
end

_G.Options = Options

return Options