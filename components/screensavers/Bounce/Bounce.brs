' This screensaver updates poster.translation from a repeating timer instead of
' using Vector2DFieldInterpolator. The bounce is stateful: each frame clamps the
' poster inside the screen bounds, flips velocity at edges, and continues from
' the corrected position. A manual loop keeps that boundary logic explicit and
' avoids coordinating separate animation legs and timers.

' Vector2DFieldInterpolator is nice when you want SceneGraph to animate from A to B
' over a known duration. But the bounce behavior is stateful: each frame needs to
' check bounds, clamp position, flip velocity, and continue. A timer-driven manual 
' position update is a reasonable fit, and it’s also easier to debug.

' Tradeoff: the interpolator can be a bit smoother/cheaper for simple one-shot
' animations, but this cover is a single poster moving at ~30 FPS, so manually
' setting poster.translation is not a problem. For this screensaver, I’d actually
'  prefer the manual loop because it removes the awkward "calculate next wall hit, 
' animate there, wait for timer, restart" coordination that likely caused the 
' corner-stuck behavior we saw that caused us to rewrite this away from using the
' Vector2DFieldInterpolator


' This implementation is based on:
' https://prgreen.github.io/blog/2013/09/30/the-bouncing-dvd-logo-explained/

'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.log = CreateLogger("Bounce", false)
    m.poster = m.top.findNode("poster")
    m.bounceTimer = m.top.findNode("bounceTimer")

    initValues()
    initHandlers()
    updatePoster()
    startBounceFromCenter()
end sub

'-------------------------------------------------------------------------------
' initValues
'-------------------------------------------------------------------------------
sub initValues()
    m.screenWidth = 1920
    m.screenHeight = 1080
    m.posterSize = 500
    m.bounceSpeedPixelsPerSecond = 130
    m.frameSeconds = 0.033
    m.pi = 3.14159265
    m.positionX = 0.0
    m.positionY = 0.0
    m.velocityX = 1.0
    m.velocityY = 1.0
end sub

'-------------------------------------------------------------------------------
' initHandlers
'-------------------------------------------------------------------------------
sub initHandlers()
    if m.bounceTimer <> invalid then m.bounceTimer.observeField("fire", "onBounceTimerFired")
end sub

' updatePoster
'-------------------------------------------------------------------------------
sub updatePoster()
    if m.poster = invalid then return

    server = SafeString(m.top.server, "")
    token = SafeString(m.top.token, "")
    itemId = SafeString(m.top.itemId, "")

    if server = "" or token = "" or itemId = "" then
        m.poster.uri = "pkg:/images/placeholder-cover.png"
        return
    end if

    m.poster.uri = Cover_BuildUrl(server, token, itemId, 500)
end sub

'-------------------------------------------------------------------------------
' startBounceFromCenter
'-------------------------------------------------------------------------------
sub startBounceFromCenter()
    m.positionX = (m.screenWidth - m.posterSize) / 2
    m.positionY = (m.screenHeight - m.posterSize) / 2
    updatePosterPosition()

    angle = getRandomDiagonalAngle()
    m.velocityX = Cos(angle)
    m.velocityY = Sin(angle)
    startBounceTimer()
end sub

'-------------------------------------------------------------------------------
' startBounceTimer
'-------------------------------------------------------------------------------
sub startBounceTimer()
    if m.bounceTimer = invalid then return

    m.bounceTimer.control = "stop"
    m.bounceTimer.control = "start"
end sub

'-------------------------------------------------------------------------------
' onBounceTimerFired
'-------------------------------------------------------------------------------
sub onBounceTimerFired()
    stepPixels = m.bounceSpeedPixelsPerSecond * m.frameSeconds
    m.positionX = m.positionX + (m.velocityX * stepPixels)
    m.positionY = m.positionY + (m.velocityY * stepPixels)

    updateVelocityForBoundaryHit()
    updatePosterPosition()
end sub

'-------------------------------------------------------------------------------
' updatePosterPosition
'-------------------------------------------------------------------------------
sub updatePosterPosition()
    if m.poster = invalid then return

    m.poster.translation = [
        int(m.positionX)
        int(m.positionY)
    ]
end sub

'-------------------------------------------------------------------------------
' updateVelocityForBoundaryHit
'-------------------------------------------------------------------------------
sub updateVelocityForBoundaryHit()
    maxX = m.screenWidth - m.posterSize
    maxY = m.screenHeight - m.posterSize

    if m.positionX <= 0 then
        m.positionX = 0
        if m.velocityX < 0 then m.velocityX = -m.velocityX
    else if m.positionX >= maxX then
        m.positionX = maxX
        if m.velocityX > 0 then m.velocityX = -m.velocityX
    end if

    if m.positionY <= 0 then
        m.positionY = 0
        if m.velocityY < 0 then m.velocityY = -m.velocityY
    else if m.positionY >= maxY then
        m.positionY = maxY
        if m.velocityY > 0 then m.velocityY = -m.velocityY
    end if
end sub

'-------------------------------------------------------------------------------
' getRandomDiagonalAngle
'-------------------------------------------------------------------------------
function getRandomDiagonalAngle() as float
    quadrant = Rnd(4)
    angleOffset = (Rnd(0) * (m.pi / 6)) - (m.pi / 12)

    if quadrant = 1 then return (m.pi / 4) + angleOffset
    if quadrant = 2 then return (3 * m.pi / 4) + angleOffset
    if quadrant = 3 then return (5 * m.pi / 4) + angleOffset

    return (7 * m.pi / 4) + angleOffset
end function
