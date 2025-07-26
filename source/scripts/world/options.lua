import "CoreLibs/save"

local pd <const> = playdate
local gfx <const> = pd.graphics

-- Define Options module with default settings
local Options = {}
Options.settings = {
    soundEnabled = true,
    musicEnabled = true,
    musicVolume = 0.7, -- Default music volume (70%)
    startingLives = 3,
    peeloutEnabled = true,
    debugMode = true,  -- Set to true during development
    timeoverEnabled = true,
    levelSelectEnabled = false
}

-- Create a safer load function with error handling
function Options:load()
    local success, savedData = pcall(function() return pd.datastore.read("options") end)
    
    if success and savedData then
        -- Merge saved data with defaults to ensure all properties exist
        for key, value in pairs(savedData) do
            self.settings[key] = value
        end
        print("[Options] Settings loaded successfully")
    else
        print("[Options] No saved options found or error loading, using defaults.")
    end
end

function Options:save()
    local success, err = pcall(function() 
        pd.datastore.write("options", self.settings) 
    end)
    
    if success then
        print("[Options] Settings saved successfully")
    else
        print("[Options] Error saving settings:", err)
    end
end

function Options:init()
    -- Make Options accessible globally immediately
    _G.Options = self
    
    -- Try to load saved settings, but use defaults if there's an error
    local success, err = pcall(function() self:load() end)
    
    if not success then
        print("[Options] Error during initialization:", err)
        print("[Options] Using default settings instead")
    end
    
    -- Print current settings for debugging
    print("[Options] Debug mode:", self.settings.debugMode)
    print("[Options] Sound enabled:", self.settings.soundEnabled)
    print("[Options] Music enabled:", self.settings.musicEnabled)
    print("[Options] Music volume:", self.settings.musicVolume)
    
    return self
end

function Options:toggleSound()
    self.settings.soundEnabled = not self.settings.soundEnabled
    self:save()
    return self.settings.soundEnabled
end

function Options:toggleMusic()
    self.settings.musicEnabled = not self.settings.musicEnabled
    self:save()
end

function Options:setMusicVolume(volume)
    self.settings.musicVolume = volume
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