-- var.lua
-- Player and game state variables

local var = {}

-- Player state
var.x = 0
var.y = 0
var.xspeed = 0
var.yspeed = 0
var.groundspeed = 0
var.groundangle = 0
var.widthrad = 9
var.heightrad = 19
var.jumpforce = 6.0 -- Reduced jump force for less floaty jumps
var.pushradius = 10

var.grounded = false

var.rings = 0
var.lives = 3
var.score = 0
var.timemicroseconds = 0
var.timeseconds = 0
var.timeminutes = 0

var.checkpoint = 0

var.damageinvincibility = false
var.invincible = false
var.speedshoes = false
var.dead = false

var.framesnotgrounded = 0
var.grounddebounceframes = 3
var.groundsnaptolerance = 4.0
var.highspeedsnaptolerance = 12.0
var.minslopeheight = 1.0

-- Example enum for player states
var.ShieldState = {
    NONE = 0,
    FIRE = 1,
    LIGHTNING = 2,
    WATER = 3,
    HONEY = 4
}

var.shield = var.ShieldState.NONE



_G.var = var
return var
