-- An interceptor jet. Medium health, fires pulse cannon.

return function (positionX, positionY, velocityX, velocityY)
    return {
        bullet = { name = 'bullet.pulse', speed = 250 },
        fire = { interval = 1 },
        position = { x = positionX, y = positionY },
        velocity = { x = velocityX, y = velocityY },
        size = 10
    }
end
