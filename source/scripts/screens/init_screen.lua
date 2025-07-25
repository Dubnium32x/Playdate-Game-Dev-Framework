import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/ui" 

local pd <const> = playdate
local gfx <const> = pd.graphics

local waitTime = 0
local waitDuration = 5000

local presentedText = "Original Characters and Gameplay by" 

local InitScreen = {}
InitScreen.wipeActive = false
InitScreen.wipeProgress = 0
InitScreen.WIPE_DURATION = 0.3 -- seconds

function InitScreen:init()
    self.logo = playdate.graphics.image.new("sprites/sprite/sega_logo.png")
    self.myFont = gfx.font.new("fonts/m6x11")
    self.segaJingle = playdate.sound.sampleplayer.new("sounds/jingle0A.wav")
    if not self.segaJingle then
        print("[InitScreen] Failed to load SFX: sounds/jingle0A.wav")
    else
        print("[InitScreen] SFX loaded: sounds/jingle0A.wav")
    end
    self.t = 0
    self.logoX = -100 -- Start off-screen left
    self.logoY = 135 -- Centered vertically with some placement down
    self.logoScale = 0.2 -- Start small
    self.animationDone = false
    self.sfxPlayed = false
    self.startTime = nil
    if not self.myFont then
        print("[InitScreen] Failed to load font: fonts/m6x11.fnt")
    else
        print("[InitScreen] Font loaded: fonts/m6x11.fnt")
    end
end

function InitScreen:update()
    if not self.animationDone then
        self.t = self.t + 1/45
        -- Slide in and scale up over 1 second
        local progress = math.min(self.t, 1)
        self.logoX = -100 + (200 + 100) * progress -- from -100 to 200
        self.logoScale = 0.2 + 0.8 * progress      -- from 0.2 to 1.0
        if self.t >= 1 then
            self.animationDone = true
        end
    end

    if self.animationDone and not self.sfxPlayed then
        -- Play the jingle sound effect
        if self.segaJingle then self.segaJingle:play() end
        self.sfxPlayed = true
        self.startTime = pd.getCurrentTimeMilliseconds()
    end

    if self.sfxPlayed and self.startTime and not self.wipeActive and not self.wipeStarted then
        if pd.getCurrentTimeMilliseconds() - self.startTime >= waitDuration then
            self.wipeActive = true
            self.wipeProgress = 0
            self.wipeStarted = true
        end
    end

    if self.wipeActive then
        -- Eased wipe progress (ease-in-out)
        if not self.wipeStartTime then self.wipeStartTime = pd.getCurrentTimeMilliseconds() end
        local elapsed = (pd.getCurrentTimeMilliseconds() - self.wipeStartTime) / 1000
        local t = math.min(elapsed / self.WIPE_DURATION, 1)
        -- Ease-in-out cubic
        local ease
        if t < 0.5 then
            ease = 4 * t * t * t
        else
            ease = 1 - math.pow(-2 * t + 2, 3) / 2
        end
        self.wipeProgress = ease * 400
        if t >= 1 then
            self.wipeActive = false
            self.wipeStartTime = nil
            local ScreenManager = _G.ScreenManager
            local TitleScreen = _G.TitleScreen
            ScreenManager.setScreen(TitleScreen)
        end
    end
end

function InitScreen:draw()
    playdate.graphics.clear()
    gfx.setFont(self.myFont)
    gfx.setBackgroundColor(gfx.kColorBlack)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    playdate.graphics.drawTextAligned("Original Characters and Gameplay by", 200, 60, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy) -- reset to default after drawing text
    if self.logo then
        local logoW, logoH = self.logo:getSize()
        local drawX = self.logoX - (logoW * self.logoScale) / 2
        local drawY = self.logoY - (logoH * self.logoScale) / 2
        self.logo:drawScaled(drawX, drawY, self.logoScale)
    end
    if self.wipeActive then
        playdate.graphics.setColor(playdate.graphics.kColorWhite)
        playdate.graphics.fillRect(0, 0, math.floor(self.wipeProgress), 240)
        playdate.graphics.setColor(playdate.graphics.kColorBlack)
    end
end

_G.InitScreen = InitScreen
return InitScreen
