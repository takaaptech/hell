local Update = {}

local System = require 'lib.knife.system'
local Event = require 'lib.knife.event'

local Input = require 'game.input'
local Vector = require 'game.vector'
local Entity = require 'game.entity'

local function checkCollision (posA, sizeA, posB, sizeB)
    local dx = math.abs(posA.x - posB.x)
    local dy = math.abs(posA.y - posB.y)
    local size = sizeA + sizeB

    return dx < size and dy < size
end

local function spawn (entities, amount, name, ...)
    local offset = #entities + 1

    for index = offset, offset + amount do
        entities[index] = Entity(name, ...)
    end
end

-- update player velocity from input position

local colliderComponents = { 'position', 'size', 'health', '_entity', '_index' }

Update.collision = System(
{ 'position', 'size', 'damage', '_entity', '_index', '_entities' },
function (posA, sizeA, damage, entityA, indexA, entities)
    for posB, sizeB, health, entityB, indexB
    in System.each(entities, colliderComponents) do
        if (posA ~= posB) and checkCollision(posA, sizeA, posB, sizeB) then
            -- Event.dispatch('collision', entityA, entityB)
            health.pain = health.pain + damage.value
            health.value = health.value - damage.value
            table.remove(entities, indexA)
            spawn(entities, 10, 'particle.spark', posA.x, posA.y)
            System.invalidate(entities)
        end
    end
end)

Update.death = System(
{'position', 'health', '_index', '_entities'},
function (p, health, index, entities, dt)
    if health.value <= 0 then
        table.remove(entities, index)
        spawn(entities, 5, 'particle.explosion', p.x, p.y)
        System.invalidate(entities)
    end
end, System.reverse)

-- update player velocity from input position

Update.playerPosition = System(
{ 'isPlayer', 'position', 'velocity', 'maxSpeed', 'easeFactor' },
function (_, p, v, maxSpeed, easeFactor, dt)
    local ease = dt * easeFactor
    local vx, vy = Vector.fromPoints(p.x, p.y, Input.getPosition())
    v.x, v.y = Vector.limit(vx / ease, vy / ease, maxSpeed)
end)

-- handle player fire button

Update.playerFire = System(
{ 'isPlayer', 'position', 'fireDelay', 'fireInterval', '_entities' },
function (_, p, fireDelay, fireInterval, entities, dt)
    if not Input.getFireButton() then
        return
    end
    if fireDelay.value > 0 then
        return
    end
    fireDelay.value = fireInterval
    entities[#entities + 1] = Entity('bullet.player', p.x, p.y, 0, -500)
end)

-- update position from velocity

Update.velocity = System(
{ 'position', 'velocity' },
function (p, v, dt)
    p.x = p.x + v.x * dt
    p.y = p.y + v.y * dt
end)

-- update delay time until next bullet can be fired

Update.fireDelay = System(
{ 'fireDelay' },
function (fireDelay, dt)
    if fireDelay.value > 0 then
        fireDelay.value = fireDelay.value - dt
    end
    if fireDelay.value < 0 then
        fireDelay.value = 0
    end
end)

-- track player position and update fire angle

Update.trackingAngle = System(
{ 'position', 'trackingAngle', '_entities' },
function (p, trackingAngle, entities, dt)
    local player = entities[1]
    local x, y = player.position.x, player.position.y
    trackingAngle.value = Vector.toAngle(Vector.fromPoints(p.x, p.y, x, y))
end)

-- fire a bullet at player

Update.trackingFire = System(
{ 'position', 'trackingAngle', 'fireDelay', 'fireInterval', 'bulletType',
    'bulletSpeed', '_entities' },
function (p, a, fireDelay, fireInterval, bulletType, bulletSpeed, entities, dt)
    if fireDelay.value > 0 then
        return
    end
    fireDelay.value = fireInterval
    local vx, vy = Vector.fromAngle(a.value)
    vx = vx * bulletSpeed; vy = vy * bulletSpeed
    entities[#entities + 1] = Entity(bulletType, p.x, p.y, vx, vy)
    System.invalidate(entities)
end)

-- fire bullets at multiple angles

Update.multiFire = System(
{ 'position', 'fireAngles', 'fireDelay', 'fireInterval', 'bulletType',
    'bulletSpeed', '_entities' },
function (p, fireAngles, fireDelay, fireInterval, bulletType, bulletSpeed, entities, dt)
    if fireDelay.value > 0 then
        return
    end
    fireDelay.value = fireInterval
    for _, angle in ipairs(fireAngles) do
        local vx, vy = Vector.fromAngle(angle)
        vx = vx * bulletSpeed; vy = vy * bulletSpeed
        entities[#entities + 1] = Entity(bulletType, p.x, p.y, vx, vy)
    end
    System.invalidate(entities)
end)

-- fire a bullet straight ahead

Update.forwardFire = System(
{ 'position', 'velocity', 'fireDelay', 'fireInterval', 'bulletType',
    'bulletSpeed', '_entities' },
function (p, v, fireDelay, fireInterval, bulletType, bulletSpeed, entities, dt)
    if fireDelay.value > 0 then
        return
    end
    fireDelay.value = fireInterval
    local vx, vy = Vector.normalize(v.x, v.y)
    vx = vx * bulletSpeed; vy = vy * bulletSpeed
    entities[#entities + 1] = Entity(bulletType, p.x, p.y, vx, vy)
    System.invalidate(entities)
end)

-- remove entities when they go out of bounds

local boundaryMargin = 64
local windowHeight = love.window.getHeight()
local windowWidth = love.window.getWidth()

Update.boundaryRemoval = System(
{ 'position', '_entities', '_index' },
function (p, entities, index)
    if p.y < -boundaryMargin or p.y > windowHeight + boundaryMargin
    or p.x < -boundaryMargin or p.x > windowWidth + boundaryMargin then
        table.remove(entities, index)
        System.invalidate(entities)
    end
end, System.reverse)

-- fade entities out and remove them

Update.fade = System(
{ 'fade', '_entities', '_index' },
function (fade, entities, index, dt)
    fade.value = fade.value + fade.speed * dt
    if fade.value >= 1 then
        table.remove(entities, index)
        System.invalidate(entities)
    end
end, System.reverse)

Update.pain = System(
{ 'health' },
function (health, dt)
    if health.pain > 0 then
        health.pain = health.pain - dt * 4
    end
end)

Update.scale = System(
{ 'scale' },
function (scale, dt)
    if scale.delta then
        scale.value = scale.value + scale.delta * dt
    end
end)

return Update
