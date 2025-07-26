-- sound_manager.lua
-- Module to handle sound and music playback in the game

import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/timer"

local pd <const> = playdate
local snd <const> = pd.sound

local SoundManager = {}

-- Store music files for reuse
SoundManager.musicTracks = {}
SoundManager.currentMusic = nil
SoundManager.isMusicEnabled = true
SoundManager.isSoundEnabled = true

-- Initialize sound system
function SoundManager:init()
    -- Check if settings are available
    if _G.Options and _G.Options.settings then
        self.isMusicEnabled = _G.Options.settings.musicEnabled
        self.isSoundEnabled = _G.Options.settings.soundEnabled
    end
    
    print("Sound Manager initialized. Music:", self.isMusicEnabled, "Sound:", self.isSoundEnabled)
    
    -- Pre-load music tracks
    self:preloadMusic()
end

-- Preload music tracks to avoid loading delays during gameplay
function SoundManager:preloadMusic()
    -- Music tracks to preload
    local musicFiles = {
        gameplay = "sounds/music/gameplayplaceholder",
    }
    
    -- Load each music file
    for key, path in pairs(musicFiles) do
        print("Loading music track:", path)
        
        -- Use pcall to catch errors in case file is missing
        local success, result = pcall(function()
            local filePath = path .. ".wav"
            local filePlayer = snd.fileplayer.new(filePath)
            
            if filePlayer then
                -- Set default properties
                filePlayer:setVolume(0.7)
                filePlayer:setLoopRange(0, -1) -- Loop the entire file
                filePlayer:setStopOnUnderrun(false)
                
                -- Store in our tracks table
                self.musicTracks[key] = filePlayer
                return true
            else
                return false, "Failed to create file player"
            end
        end)
        
        if not success then
            print("Error loading music track:", result)
        end
    end
    
    print("Music preloading complete")
end

-- Play a music track by key
function SoundManager:playMusic(trackKey, volume, loop)
    -- Default values
    volume = volume or 0.7
    loop = (loop ~= false) -- Default to true
    
    -- Stop current music if playing
    self:stopMusic()
    
    -- Check if music is enabled
    if not self.isMusicEnabled then
        print("Music is disabled, not playing:", trackKey)
        return false
    end
    
    -- Get the track
    local track = self.musicTracks[trackKey]
    if not track then
        print("Music track not found:", trackKey)
        return false
    end
    
    -- Set properties
    track:setVolume(volume)
    
    -- Set looping
    if loop then
        track:setLoopRange(0, -1) -- Loop the entire file
    else
        track:setLoopRange(0, 0) -- No looping
    end
    
    -- Play the track
    local success = track:play()
    if success then
        self.currentMusic = trackKey
        print("Playing music track:", trackKey)
    else
        print("Failed to play music track:", trackKey)
    end
    
    return success
end

-- Stop the currently playing music
function SoundManager:stopMusic()
    if self.currentMusic and self.musicTracks[self.currentMusic] then
        self.musicTracks[self.currentMusic]:stop()
        print("Stopped music track:", self.currentMusic)
        self.currentMusic = nil
    end
end

-- Pause the currently playing music
function SoundManager:pauseMusic()
    if self.currentMusic and self.musicTracks[self.currentMusic] then
        self.musicTracks[self.currentMusic]:pause()
    end
end

-- Resume the currently playing music
function SoundManager:resumeMusic()
    if self.currentMusic and self.musicTracks[self.currentMusic] then
        self.musicTracks[self.currentMusic]:play()
    end
end

-- Set music volume (0.0 to 1.0)
function SoundManager:setMusicVolume(volume)
    if self.currentMusic and self.musicTracks[self.currentMusic] then
        self.musicTracks[self.currentMusic]:setVolume(volume)
    end
end

-- Toggle music on/off
function SoundManager:toggleMusic()
    self.isMusicEnabled = not self.isMusicEnabled
    
    -- Update global settings if available
    if _G.Options and _G.Options.settings then
        _G.Options.settings.musicEnabled = self.isMusicEnabled
    end
    
    -- Stop music if disabled
    if not self.isMusicEnabled and self.currentMusic then
        self:stopMusic()
    elseif self.isMusicEnabled and self.currentMusic then
        -- Restart the last track if re-enabled
        self:playMusic(self.currentMusic)
    end
    
    return self.isMusicEnabled
end

-- Return the module
_G.SoundManager = SoundManager
return SoundManager
