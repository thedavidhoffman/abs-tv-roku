' this implementation is based on...
' https://prgreen.github.io/blog/2013/09/30/the-bouncing-dvd-logo-explained/

'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.log = CreateLogger("Bounce")
    m.poster = m.top.findNode("poster")
    m.bounceAnimation = m.top.findNode("bounceAnimation")
    m.bounceInterpolator = m.top.findNode("bounceInterpolator")
    m.bounceLegTimer = m.top.findNode("bounceLegTimer")

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
    m.boundaryEpsilon = 1
    m.escapeStepPixels = 2
    m.pi = 3.14159265
    m.currentBounceEndPosition = invalid
    m.velocityX = 1.0
    m.velocityY = 1.0
end sub

'-------------------------------------------------------------------------------
' initHandlers
'-------------------------------------------------------------------------------
sub initHandlers()
    if m.bounceLegTimer <> invalid then m.bounceLegTimer.observeField("fire", "onBounceLegTimerFired")
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
    startPosition = [
        int((m.screenWidth - m.posterSize) / 2)
        int((m.screenHeight - m.posterSize) / 2)
    ]
    if m.poster <> invalid then m.poster.translation = startPosition

    angle = getRandomDiagonalAngle()
    m.velocityX = Cos(angle)
    m.velocityY = Sin(angle)
    startBounceLeg(startPosition)
end sub

'-------------------------------------------------------------------------------
' onBounceLegTimerFired
'-------------------------------------------------------------------------------
sub onBounceLegTimerFired()
    if m.poster = invalid then return

    currentPosition = m.currentBounceEndPosition
    if currentPosition = invalid then return
    currentPosition = snapPositionToBounds(currentPosition)
    m.poster.translation = currentPosition

    updateVelocityForBoundaryHit(currentPosition)
    startBounceLeg(currentPosition)
end sub

'-------------------------------------------------------------------------------
' startBounceLeg
'-------------------------------------------------------------------------------
sub startBounceLeg(startPosition as object)
    if m.bounceAnimation = invalid or m.bounceInterpolator = invalid then return

    startPosition = snapPositionToBounds(startPosition)
    updateVelocityForBoundaryHit(startPosition)
    endPosition = getBoundaryPosition(startPosition)
    if positionsMatch(startPosition, endPosition) then
        startPosition = getEscapedBoundaryPosition(startPosition)
        if m.poster <> invalid then m.poster.translation = startPosition
        endPosition = getBoundaryPosition(startPosition)
    end if
    duration = getLegDuration(startPosition, endPosition)
    if duration < 0.1 then duration = 0.1
    m.currentBounceEndPosition = endPosition

    m.bounceAnimation.control = "stop"
    m.bounceAnimation.duration = duration
    m.bounceInterpolator.key = [0.0, 1.0]
    m.bounceInterpolator.keyValue = [
        [startPosition[0], startPosition[1]]
        [endPosition[0], endPosition[1]]
    ]
    m.bounceAnimation.control = "start"

    if m.bounceLegTimer <> invalid then
        m.bounceLegTimer.control = "stop"
        m.bounceLegTimer.duration = duration
        m.bounceLegTimer.control = "start"
    end if
end sub

'-------------------------------------------------------------------------------
' getBoundaryPosition
'-------------------------------------------------------------------------------
function getBoundaryPosition(startPosition as object) as object
    maxX = m.screenWidth - m.posterSize
    maxY = m.screenHeight - m.posterSize
    startX = startPosition[0]
    startY = startPosition[1]
    timeToHitX = 100000.0
    timeToHitY = 100000.0

    if m.velocityX > 0 then
        timeToHitX = (maxX - startX) / m.velocityX
    else if m.velocityX < 0 then
        timeToHitX = (0 - startX) / m.velocityX
    end if

    if m.velocityY > 0 then
        timeToHitY = (maxY - startY) / m.velocityY
    else if m.velocityY < 0 then
        timeToHitY = (0 - startY) / m.velocityY
    end if

    travelTime = timeToHitX
    if timeToHitY < travelTime then travelTime = timeToHitY
    if travelTime < 0 then travelTime = 0

    endX = startX + (m.velocityX * travelTime)
    endY = startY + (m.velocityY * travelTime)

    return [
        clampInt(endX, 0, maxX)
        clampInt(endY, 0, maxY)
    ]
end function

'-------------------------------------------------------------------------------
' getLegDuration
'-------------------------------------------------------------------------------
function getLegDuration(startPosition as object, endPosition as object) as float
    deltaX = endPosition[0] - startPosition[0]
    deltaY = endPosition[1] - startPosition[1]
    distance = Sqr((deltaX * deltaX) + (deltaY * deltaY))

    if m.bounceSpeedPixelsPerSecond < 1 then return 1.0
    return distance / m.bounceSpeedPixelsPerSecond
end function

'-------------------------------------------------------------------------------
' updateVelocityForBoundaryHit
'-------------------------------------------------------------------------------
sub updateVelocityForBoundaryHit(position as object)
    maxX = m.screenWidth - m.posterSize
    maxY = m.screenHeight - m.posterSize

    if position[0] <= m.boundaryEpsilon then
        if m.velocityX < 0 then m.velocityX = -m.velocityX
    else if position[0] >= maxX - m.boundaryEpsilon then
        if m.velocityX > 0 then m.velocityX = -m.velocityX
    end if

    if position[1] <= m.boundaryEpsilon then
        if m.velocityY < 0 then m.velocityY = -m.velocityY
    else if position[1] >= maxY - m.boundaryEpsilon then
        if m.velocityY > 0 then m.velocityY = -m.velocityY
    end if
end sub

'-------------------------------------------------------------------------------
' snapPositionToBounds
'-------------------------------------------------------------------------------
function snapPositionToBounds(position as object) as object
    maxX = m.screenWidth - m.posterSize
    maxY = m.screenHeight - m.posterSize
    x = position[0]
    y = position[1]

    if x <= m.boundaryEpsilon then x = 0
    if x >= maxX - m.boundaryEpsilon then x = maxX
    if y <= m.boundaryEpsilon then y = 0
    if y >= maxY - m.boundaryEpsilon then y = maxY

    return [
        clampInt(x, 0, maxX)
        clampInt(y, 0, maxY)
    ]
end function

'-------------------------------------------------------------------------------
' positionsMatch
'-------------------------------------------------------------------------------
function positionsMatch(left as object, right as object) as boolean
    if left = invalid or right = invalid then return false

    return left[0] = right[0] and left[1] = right[1]
end function

'-------------------------------------------------------------------------------
' getEscapedBoundaryPosition
'-------------------------------------------------------------------------------
function getEscapedBoundaryPosition(position as object) as object
    maxX = m.screenWidth - m.posterSize
    maxY = m.screenHeight - m.posterSize

    return [
        clampInt(position[0] + (m.velocityX * m.escapeStepPixels), 0, maxX)
        clampInt(position[1] + (m.velocityY * m.escapeStepPixels), 0, maxY)
    ]
end function

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

'-------------------------------------------------------------------------------
' clampInt
'-------------------------------------------------------------------------------
function clampInt(value as dynamic, minValue as integer, maxValue as integer) as integer
    clampedValue = int(value)
    if clampedValue < minValue then return minValue
    if clampedValue > maxValue then return maxValue

    return clampedValue
end function
