import "CoreLibs/graphics"
import "CoreLibs/object"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/ui"
local Options = import "scripts/world/options"

local pd <const> = playdate
local gfx <const> = pd.graphics

local OptionsScreen = {}
OptionsScreen.selectedIndex = 1
local optionKeys = {
    "soundEnabled",
    "musicEnabled",
    "musicVolume",
    "startingLives",
    "peeloutEnabled",
    "debugMode",
    "timeoverEnabled",
    "levelSelectEnabled",
    "apply",
    "cancel"
}
local optionLabels = {
    soundEnabled = "Sound",
    musicEnabled = "Music",
    musicVolume = "Music Volume",
    startingLives = "Starting Lives",
    peeloutEnabled = "Peelout",
    debugMode = "Debug Mode",
    timeoverEnabled = "Time Over",
    levelSelectEnabled = "Level Select",
    apply = "Apply",
    cancel = "Cancel"
}

local cursorSound = pd.sound.sample.new("sounds/Sonic 3K/S3K_5B.wav")

function OptionsScreen:init()
    self.selectedIndex = 1
    Options:init()
    self.stagedSettings = {}
    for k, v in pairs(Options.settings) do
        self.stagedSettings[k] = v
    end
    
    -- Initialize default values if not present
    if self.stagedSettings.musicVolume == nil then
        self.stagedSettings.musicVolume = 0.7
    end
end

function OptionsScreen:update()
    if pd.buttonJustPressed(pd.kButtonUp) then
        if cursorSound then cursorSound:play() end
        self.selectedIndex = self.selectedIndex - 1
        if self.selectedIndex < 1 then self.selectedIndex = #optionKeys end
    elseif pd.buttonJustPressed(pd.kButtonDown) then
        if cursorSound then cursorSound:play() end
        self.selectedIndex = self.selectedIndex + 1
        if self.selectedIndex > #optionKeys then self.selectedIndex = 1 end
    end
    if pd.buttonJustPressed(pd.kButtonA) then
        if cursorSound then cursorSound:play() end
        local key = optionKeys[self.selectedIndex]
        if key == "apply" then
            for k, v in pairs(self.stagedSettings) do
                Options.settings[k] = v
            end
            Options:save()
            
            -- Apply sound settings immediately
            if _G.SoundManager then
                if _G.SoundManager.setMusicVolume and Options.settings.musicVolume then
                    _G.SoundManager:setMusicVolume(Options.settings.musicVolume)
                end
                
                -- Toggle music if needed
                if not Options.settings.musicEnabled then
                    _G.SoundManager:stopMusic()
                elseif Options.settings.musicEnabled and _G.SoundManager.currentMusic == nil then
                    _G.SoundManager:playMusic("gameplay")
                end
            end
            
            local ScreenManager = _G.ScreenManager
            local TitleScreen = _G.TitleScreen
            ScreenManager.setScreen(TitleScreen)
        elseif key == "cancel" then
            local ScreenManager = _G.ScreenManager
            local TitleScreen = _G.TitleScreen
            ScreenManager.setScreen(TitleScreen)
        elseif key == "startingLives" then
            self.stagedSettings.startingLives = (self.stagedSettings.startingLives % 5) + 1 -- Cycle through 1 to 5 lives
        elseif key == "musicVolume" then
            -- Increment volume by 0.1, loop back to 0.1 after 1.0
            self.stagedSettings.musicVolume = ((self.stagedSettings.musicVolume * 10) % 10 + 1) / 10
        elseif self.stagedSettings[key] ~= nil then
            self.stagedSettings[key] = not self.stagedSettings[key]
        end
    end
    if pd.buttonJustPressed(pd.kButtonB) then
        local ScreenManager = _G.ScreenManager
        local TitleScreen = _G.TitleScreen
        ScreenManager.setScreen(TitleScreen)
    end
end

function OptionsScreen:draw()
    gfx.clear()
    print("[OptionsScreen] Drawing options screen...")
    gfx.setFont(gfx.font.new("fonts/monogram-12"))
    gfx.drawTextAligned("Options", 200, 40, kTextAlignment.center)
    local menuY = 80
    for i, key in ipairs(optionKeys) do
        local label = optionLabels[key]
        local value = self.stagedSettings[key]
        local text
        
        if key == "apply" or key == "cancel" then
            text = label
        elseif key == "musicVolume" then
            -- Display volume as a percentage
            local volumePercent = math.floor((value or 0.7) * 100)
            text = label .. ": " .. volumePercent .. "%"
        else
            text = label .. ": " .. tostring(value)
        end
        local y = menuY + (i-1)*18
        if i == self.selectedIndex then
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(80, y-2, 240, 16)
            gfx.setColor(gfx.kColorBlack)
            gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
        else
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
            gfx.setColor(gfx.kColorWhite)
        end
        gfx.drawTextAligned(text, 200, y, kTextAlignment.center)
    end
end

_G.OptionsScreen = OptionsScreen
return OptionsScreen
