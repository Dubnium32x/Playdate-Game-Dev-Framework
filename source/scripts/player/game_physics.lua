import "var"

local GamePhysics = {}
GamePhysics.__index = GamePhysics
setmetatable(GamePhysics, { __index = var })

function GamePhysics:new(...)
    local self = setmetatable({}, GamePhysics)
    -- Insert default values for physics properties
    self.groundmode = "floor"
    self.acceleration = 0.06
    self.deceleration = 0.08
    self.friction = 0.046875
    self.topspeed = 6.0
    self.maxspeed = 8.5
    self.gravity = 0.26
    self.maxFallSpeed = 14.0

    -- Rolling physics constants
    self.rollingFriction = 0.023
    self.rollingDeceleration = 0.04
    self.minSpeedToStartRoll = 2.0

    -- Hitbox dimensions
    self.normalWidthRad = 9.0
    self.normalHeightRad = 19.0
    self.rollingWidthRad = 9.0
    self.rollingHeightRad = 9.0
    self.sincoslist = {
        0, 6, 12, 18, 25, 31, 37, 43, 49, 56, 62, 68, 74, 80, 86, 92, 97, 103, 109, 115, 120, 126, 131, 136, 142, 147, 152, 157, 162, 167, 171, 176, 181, 185, 189, 193, 197, 201, 205, 209, 212, 216, 219, 222, 225, 228, 231, 234, 236, 238, 241, 243, 244, 246, 248, 249, 251, 252, 253, 254, 254, 255, 255, 255,
        256, 255, 255, 255, 254, 254, 253, 252, 251, 249, 248, 246, 244, 243, 241, 238, 236, 234, 231, 228, 225, 222, 219, 216, 212, 209, 205, 201, 197, 193, 189, 185, 181, 176, 171, 167, 162, 157, 152, 147, 142, 136, 131, 126, 120, 115, 109, 103, 97, 92, 86, 80, 74, 68, 62, 56, 49, 43, 37, 31, 25, 18, 12, 6,
        0, -6, -12, -18, -25, -31, -37, -43, -49, -56, -62, -68, -74, -80, -86, -92, -97, -103, -109, -115, -120, -126, -131, -136, -142, -147, -152, -157, -162, -167, -171, -176, -181, -185, -189, -193, -197, -201, -205, -209, -212, -216, -219, -222, -225, -228, -231, -234, -236, -238, -241, -243, -244, -246, -248, -249, -251, -252, -253, -254, -254, -255, -255, -255,
        -256, -255, -255, -255, -254, -254, -253, -252, -251, -249, -248, -246, -244, -243, -241, -238, -236, -234, -231, -228, -225, -222, -219, -216, -212, -209, -205, -201, -197, -193, -189, -185, -181, -176, -171, -167, -162, -157, -152, -147, -142, -136, -131, -126, -120, -115, -109, -103, -97, -92, -86, -80, -74, -68, -62, -56, -49, -43, -37, -31, -25, -18, -12, -6
    }
    self.anglelist = {
        0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 7, 8, 8, 8, 8, 8, 8, 8, 9, 9, 9, 9, 9, 9, 10, 10, 10, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 12, 12, 12, 12, 12, 12, 12, 13, 13, 13, 13, 13, 13, 13, 14, 14, 14, 14, 14, 14, 14, 15, 15, 15, 15, 15, 15, 15, 16, 16, 16, 16, 16, 16, 16, 17, 17, 17, 17, 17, 17, 17, 17, 18, 18, 18, 18, 18, 18, 18, 19, 19, 19, 19, 19, 19, 19, 19, 20, 20, 20, 20, 20, 20, 20, 20, 21, 21, 21, 21, 21, 21, 21, 21, 21, 22, 22, 22, 22, 22, 22, 22, 22, 23, 23, 23, 23, 23, 23, 23, 23, 23, 24, 24, 24, 24, 24, 24, 24, 24, 24, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 26, 26, 26, 26, 26, 26, 26, 26, 26, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 32, 32, 32, 32, 32, 32, 32, 0
    }
    
    return self
end

function GamePhysics:angleHexSin(hex_ang)
    local list_index = hex_ang % 256
    return self.sincoslist[list_index]
end

function GamePhysics:angleHexCos(hex_ang)
    local list_index = (hex_ang + 64) % 256
    return self.sincoslist[list_index]
end


function GamePhysics:angleHexPointDirection(xdist, ydist)
    if xdist == 0 and ydist == 0 then
        return 64
    end

    import "CoreLibs/math"
    local xx = math.abs(xdist)
    local yy = math.abs(ydist)

    local angle = 0

    if ydist >= xx then
        local compare = (xx*256) / yy
        angle = 64 - anglelist[compare]
    else 
        local compare = (yy*256) / xx
        angle = anglelist[compare]
    end

    -- check angle
    if xdist <= 0 then
        angle = 128 - angle
    end
    if ydist <= 0 then
        angle = 256 - angle
    end

    return angle
end

function GamePhysics:angleHexToDegrees(hex_ang) 
    return math.floor(((256 - hex_ang) / 256) * 360)
end

function GamePhysics:angleDegreesToHex(degrees)
    return math.floor(((360 - degrees) / 360) * 256)
end

_G.GamePhysics = GamePhysics
return GamePhysics