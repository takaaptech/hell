-- Title screen.

local Scene = require('game.scene'):extend()

local Entity = require 'game.entity'
local Music = require 'game.music'


function Scene:load (level, entities)

    if not level then
        Music.play('intro.it')
    end

    local function restart ()
        Music.play('level01.mod')
        level = require('game.level.01')()
        entities = { Entity('player') }
    end

    self:on('draw', function (dt)
        love.graphics.setColor(255, 255, 255)
        love.graphics.print('Hell version ' .. _G.HELL_VERSION, 50, 50)
        if level then
            love.graphics.print('Press "escape" to resume', 50, 100)
            love.graphics.print('Press "q" to quit', 50, 150)
        else
            love.graphics.print('Press "p" to play', 50, 100)
        end
        if _G.HELL_DEBUG then
            love.graphics.setColor(255, 0, 0)
            love.graphics.print('Debug mode on', 50, 300)
        end
    end)

    self:on('keypressed', function(key)
        if key == 'p' or level and key == 'escape' then
            if not level then
                restart()
            end
            self.stage:loadScene('play', level, entities)
        elseif level and key == 'q' then
            self.stage:loadScene('menu')
        end
    end)

end

return Scene
