-- Gameplay scene.

local Scene = require('game.scene'):extend()

local Update = require 'game.system.update'
local Draw = require 'game.system.draw'
local Entity = require 'game.entity'
local Music = require 'game.music'

function Scene:load (level, entities)

    self:on('update', function (dt)
        level:update(entities, dt)
        for _, update in pairs(Update) do
            update(entities, dt)
        end
    end)

    self:on('draw', function (dt)
        Draw.sprite(entities)
        if _G.HELL_DEBUG then
            Draw.hitbox(entities)
        end
    end)

    self:on('keypressed', function(key)
        if key == 'escape' then
            self.stage:loadScene('menu', level, entities)
        end
    end)

    self:on('death', function(entity)
        if _G.HELL_DEBUG then
            print(('%s died'):format(entity.name))
        end
        if entity.isPlayer then
            self:delay(1, function ()
                self.stage:loadScene('menu')
            end)
        end
    end)

    love.mouse.setGrabbed(true)
end

function Scene:unload ()
    love.mouse.setGrabbed(false)
    self:removeHandlers()
end

return Scene
