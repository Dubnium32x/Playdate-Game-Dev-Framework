import "CoreLibs/graphics"
import "CoreLibs/object"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/ui"

local pd <const> = playdate
local gfx <const> = pd.graphics

local TitleScreen = {}
TitleScreen.selectedIndex = 1
TitleScreen.wipeActive = false
TitleScreen.wipeProgress = 0
TitleScreen.WIPE_DURATION = 0.3 -- seconds
TitleScreen.wipeStarted = false
TitleScreen.wipeStartTime = nil

local monogramFont = gfx.font.new("fonts/monogram-12")
if not monogramFont then
    print("[TitleScreen] Failed to load font: fonts/monogram-12.fnt")
else
    print("[TitleScreen] Font loaded: fonts/monogram-12.fnt")
end
local m6x11Font = gfx.font.new("fonts/m6x11")
if not m6x11Font then
    print("[TitleScreen] Failed to load font: fonts/m6x11.fnt")
else
    print("[TitleScreen] Font loaded: fonts/m6x11.fnt")
end

local titleMusic = pd.sound.fileplayer.new("sounds/music/titleplaceholder.mp3")
local cursorSound = pd.sound.sample.new("sounds/Sonic 3K/S3K_5B.wav")
local exitGameSound = pd.sound.sample.new("sounds/Sonic 3K/S3K_6A.wav")
local selectSound = pd.sound.sample.new("sounds/Sonic 3K/S3K_63.wav")

local gameClose = false

local prealphaText = "Pre-Alpha Version 0.1.2"

local menuSelectionText = {
    "Start Game",
    "Options",
    "Exit"
}

local function drawPreAlphaText()
    gfx.setFont(m6x11Font)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawTextAligned(prealphaText, 200, 220, kTextAlignment.center)
end

function TitleScreen:init()
    -- Load the logo image (update the path if needed)
    self.logo = gfx.image.new("sprites/sprite/title_logo")
    if not self.logo then
        print("[TitleScreen] Failed to load logo image: sprites/sprite/title_logo.png")
    end
    self.t = 0 -- time accumulator for effects
    self.scale = 1
    self.angle = 0
    self.wipeActive = false
    self.wipeProgress = 0
    self.wipeStarted = false
    self.wipeStartTime = nil
    if titleMusic then
        titleMusic:play(1) -- Play the title music
    else
        print("[TitleScreen] Failed to load title music")
    end
end

function TitleScreen:update()
    if playdate.buttonJustPressed(playdate.kButtonA) and not gameClose then
        local ScreenManager = _G.ScreenManager
        if self.selectedIndex == 2 then
            -- Go to Options screen
            local OptionsScreen = _G.OptionsScreen or _G.Options
            if OptionsScreen then
                print("[TitleScreen] Switching to Options screen...")
                ScreenManager.setScreen(OptionsScreen)
                if selectSound then
                    selectSound:play()
                else
                    print("[TitleScreen] Select sound not found!")
                end
            else
                print("[TitleScreen] Options screen not found!")
            end
        elseif self.selectedIndex == 3 then
            print("[TitleScreen] Exiting game...")
            gameClose = true
            if exitGameSound then
                exitGameSound:play()
            end
        else
            -- Stop music and proceed with game start
            if titleMusic then
                titleMusic:stop()
            else
                print("[TitleScreen] Title music not found, cannot stop.")
            end
            -- Play select sound if available
            if selectSound then
                selectSound:play()
            else
                print("[TitleScreen] Select sound not found!")
            end
            -- Start wipe for other selections
            self.wipeActive = true
            self.wipeProgress = 0
            self.wipeStarted = true
            self.wipeStartTime = nil
        end
    end
    -- Handle up/down input
    if pd.buttonJustPressed(pd.kButtonUp) and not gameClose then
        if cursorSound then cursorSound:play() end
        TitleScreen.selectedIndex = TitleScreen.selectedIndex - 1
        if TitleScreen.selectedIndex < 1 then TitleScreen.selectedIndex = #menuSelectionText end
    elseif pd.buttonJustPressed(pd.kButtonDown) and not gameClose then
        if cursorSound then cursorSound:play() end
        TitleScreen.selectedIndex = TitleScreen.selectedIndex + 1
        if TitleScreen.selectedIndex > #menuSelectionText then TitleScreen.selectedIndex = 1 end
    end
    self.t = self.t + 1/45 -- assuming 45 FPS
    -- Scale pulse effect
    self.scale = 1 + math.sin(self.t * 1.5) * 0.08 -- scale between ~0.92 and 1.08
    -- Rotation effect
    self.angle = math.sin(self.t) * 8 -- rotate between -8 and +8 degrees

    if self.wipeActive then
        if not self.wipeStartTime then self.wipeStartTime = pd.getCurrentTimeMilliseconds() end
        local elapsed = (pd.getCurrentTimeMilliseconds() - self.wipeStartTime) / 1000
        local t = math.min(elapsed / self.WIPE_DURATION, 1)
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
            -- Switch to next screen here
            local ScreenManager = _G.ScreenManager
            local NextScreen = _G.GameScreen or _G.InitScreen -- replace with your next screen
            ScreenManager.setScreen(NextScreen)
        end
    end
end

function TitleScreen:draw()
    playdate.graphics.clear()
    if self.logo then
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        local x, y = 200, 80
        local scale = self.scale or 1
        local angle = self.angle or 0
        self.logo:drawRotated(x, y, angle, scale)
    end
    -- Draw menu options
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    gfx.setFont(monogramFont)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.setColor(gfx.kColorWhite)
    local menuY = 140
    for i, text in ipairs(menuSelectionText) do
        local y = menuY + (i-1)*18
        if i == TitleScreen.selectedIndex then
            -- Draw selection box (white rectangle behind text)
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(120, y-2, 160, 16)
            gfx.setColor(gfx.kColorBlack)
            gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
        else
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
            gfx.setColor(gfx.kColorWhite)
        end
        gfx.drawTextAligned(text, 200, y, kTextAlignment.center)
    end
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    -- Draw pre-alpha text at the bottom
    gfx.setFont(m6x11Font)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextAligned(prealphaText, 200, 220, kTextAlignment.center)
    -- Wipe effect
    if self.wipeActive then
        playdate.graphics.setColor(playdate.graphics.kColorWhite)
        local wipeWidth = math.floor(self.wipeProgress)
        playdate.graphics.fillRect(400 - wipeWidth, 0, wipeWidth, 240)
        playdate.graphics.setColor(playdate.graphics.kColorBlack)
    end

    if gameClose then
        -- If the game is set to close, draw a message
        gfx.clear()
        gfx.setFont(m6x11Font)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawTextAligned("You may close the game now. Use the menu button to exit.", 200, 220, kTextAlignment.center)
    end
end
function TitleScreen:AButtonDown()
    if not self.wipeActive and not self.wipeStarted then
        local ScreenManager = _G.ScreenManager
        if TitleScreen.selectedIndex == 2 then
            -- Go to Options screen
            local OptionsScreen = _G.OptionsScreen or _G.Options
            if OptionsScreen then
                ScreenManager.setScreen(OptionsScreen)
            else
                print("[TitleScreen] Options screen not found!")
            end
        elseif TitleScreen.selectedIndex == 3 then
            -- Exit the game
            print("[TitleScreen] Exiting game...")
            playdate.simulator.exit()
        else
            -- Start wipe for other selections
            self.wipeActive = true
            self.wipeProgress = 0
            self.wipeStarted = true
            self.wipeStartTime = nil
        end
    end
end

function TitleScreen:DrawYouMayCloseTheGame()
    gfx.setFont(m6x11Font)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawTextAligned("You may close the game now. Use the menu button to exit.", 200, 220, kTextAlignment.center)
end

_G.TitleScreen = TitleScreen
return TitleScreen
