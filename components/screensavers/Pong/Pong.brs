'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.log = CreateLogger("Pong", false)
    m.poster = m.top.findNode("poster")
    m.leftPaddle = m.top.findNode("leftPaddle")
    m.rightPaddle = m.top.findNode("rightPaddle")
    m.leftScoreLabel = m.top.findNode("leftScore")
    m.rightScoreLabel = m.top.findNode("rightScore")
    m.centerLineLayer = m.top.findNode("centerLineLayer")
    m.gameTimer = m.top.findNode("gameTimer")
    m.serveTimer = m.top.findNode("serveTimer")

    initValues()
    initHandlers()
    buildCenterLine()
    updatePoster()
    resetMatch()
    startGame()
end sub

'-------------------------------------------------------------------------------
' initValues
'-------------------------------------------------------------------------------
sub initValues()
    m.screenWidth = 1920
    m.screenHeight = 1080
    m.ballSize = 250
    m.paddleWidth = 21
    m.paddleHeight = 220
    m.paddleInset = 60
    m.paddleMargin = 60
    m.ballSpeed = 520.0
    m.paddleSpeed = 780.0
    m.paddleEase = 0.16
    m.paddleAimJitter = 70.0
    m.minimumBounceAngle = 0.18
    m.frameSeconds = 0.033
    m.maxBounceAngle = 0.959931
    m.scoreToWin = 15
    m.missChance = 0.15
    m.pi = 3.14159265
    m.leftScore = 0
    m.rightScore = 0
    m.ballX = 0.0
    m.ballY = 0.0
    m.ballVelocityX = 0.0
    m.ballVelocityY = 0.0
    m.leftPaddleY = 0.0
    m.rightPaddleY = 0.0
    m.leftWillMiss = false
    m.rightWillMiss = false
    m.leftAimOffset = 0.0
    m.rightAimOffset = 0.0
    m.serving = false
    m.nextServeDirection = 1
end sub

'-------------------------------------------------------------------------------
' initHandlers
'-------------------------------------------------------------------------------
sub initHandlers()
    if m.gameTimer <> invalid then m.gameTimer.observeField("fire", "onGameTimerFired")
    if m.serveTimer <> invalid then m.serveTimer.observeField("fire", "onServeTimerFired")
end sub

'-------------------------------------------------------------------------------
' buildCenterLine
'-------------------------------------------------------------------------------
sub buildCenterLine()
    if m.centerLineLayer = invalid then return

    childCount = m.centerLineLayer.getChildCount()
    if childCount > 0 then m.centerLineLayer.removeChildrenIndex(childCount, 0)

    dotWidth = 10
    dotHeight = 28
    gapHeight = 24
    x = int((m.screenWidth - dotWidth) / 2)

    for y = 24 to m.screenHeight - dotHeight step dotHeight + gapHeight
        dot = CreateObject("roSGNode", "Rectangle")
        dot.width = dotWidth
        dot.height = dotHeight
        dot.color = &hFFFFFFFF
        dot.translation = [x, y]
        m.centerLineLayer.appendChild(dot)
    end for
end sub

'-------------------------------------------------------------------------------
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

    m.poster.uri = Cover_BuildUrl(server, token, itemId, m.ballSize)
end sub

'-------------------------------------------------------------------------------
' resetMatch
'-------------------------------------------------------------------------------
sub resetMatch()
    m.leftScore = 0
    m.rightScore = 0
    updateScoreLabels()
    resetPositions()
end sub

'-------------------------------------------------------------------------------
' resetPositions
'-------------------------------------------------------------------------------
sub resetPositions()
    m.leftPaddleY = (m.screenHeight - m.paddleHeight) / 2
    m.rightPaddleY = (m.screenHeight - m.paddleHeight) / 2
    m.ballX = (m.screenWidth - m.ballSize) / 2
    m.ballY = (m.screenHeight - m.ballSize) / 2
    updatePaddleNodes()
    updateBallNode()
end sub

'-------------------------------------------------------------------------------
' startGame
'-------------------------------------------------------------------------------
sub startGame()
    serveBall(1)
    if m.gameTimer <> invalid then
        m.gameTimer.control = "stop"
        m.gameTimer.control = "start"
    end if
end sub

'-------------------------------------------------------------------------------
' onGameTimerFired
'-------------------------------------------------------------------------------
sub onGameTimerFired()
    if m.serving then return

    updatePaddles()
    updateBall()
    updatePaddleNodes()
    updateBallNode()
end sub

'-------------------------------------------------------------------------------
' onServeTimerFired
'-------------------------------------------------------------------------------
sub onServeTimerFired()
    serveBall(m.nextServeDirection)
end sub

'-------------------------------------------------------------------------------
' updatePaddles
'-------------------------------------------------------------------------------
sub updatePaddles()
    ballCenterY = m.ballY + (m.ballSize / 2)
    leftTargetY = getPaddleTargetY(ballCenterY, m.leftWillMiss, m.leftAimOffset)
    rightTargetY = getPaddleTargetY(ballCenterY, m.rightWillMiss, m.rightAimOffset)

    m.leftPaddleY = moveHumanPaddle(m.leftPaddleY, leftTargetY)
    m.rightPaddleY = moveHumanPaddle(m.rightPaddleY, rightTargetY)
    m.leftPaddleY = clampFloat(m.leftPaddleY, m.paddleMargin, getMaxPaddleY())
    m.rightPaddleY = clampFloat(m.rightPaddleY, m.paddleMargin, getMaxPaddleY())
end sub

'-------------------------------------------------------------------------------
' getPaddleTargetY
'-------------------------------------------------------------------------------
function getPaddleTargetY(ballCenterY as float, willMiss as boolean, aimOffset as float) as float
    targetCenterY = ballCenterY + aimOffset

    if willMiss then
        if ballCenterY < (m.screenHeight / 2) then
            targetCenterY = ballCenterY + m.paddleHeight
        else
            targetCenterY = ballCenterY - m.paddleHeight
        end if
    end if

    return targetCenterY - (m.paddleHeight / 2)
end function

'-------------------------------------------------------------------------------
' moveHumanPaddle
'-------------------------------------------------------------------------------
function moveHumanPaddle(currentY as float, targetY as float) as float
    easedTarget = currentY + ((targetY - currentY) * m.paddleEase)
    return moveToward(currentY, easedTarget, m.paddleSpeed * m.frameSeconds)
end function

'-------------------------------------------------------------------------------
' updateBall
'-------------------------------------------------------------------------------
sub updateBall()
    m.ballX = m.ballX + (m.ballVelocityX * m.frameSeconds)
    m.ballY = m.ballY + (m.ballVelocityY * m.frameSeconds)

    if m.ballY <= 0 then
        m.ballY = 0
        m.ballVelocityY = Abs(m.ballVelocityY)
    else if m.ballY + m.ballSize >= m.screenHeight then
        m.ballY = m.screenHeight - m.ballSize
        m.ballVelocityY = -Abs(m.ballVelocityY)
    end if

    if collidesWithLeftPaddle() then
        m.ballX = getLeftPaddleX() + m.paddleWidth
        bounceFromPaddle(m.leftPaddleY, 1)
        assignMissForDirection(1)
    else if collidesWithRightPaddle() then
        m.ballX = getRightPaddleX() - m.ballSize
        bounceFromPaddle(m.rightPaddleY, -1)
        assignMissForDirection(-1)
    else if m.ballX + m.ballSize < 0 then
        scorePoint(2)
    else if m.ballX > m.screenWidth then
        scorePoint(1)
    end if
end sub

'-------------------------------------------------------------------------------
' bounceFromPaddle
'-------------------------------------------------------------------------------
sub bounceFromPaddle(paddleY as float, direction as integer)
    ballCenterY = m.ballY + (m.ballSize / 2)
    paddleCenterY = paddleY + (m.paddleHeight / 2)
    relativeIntersectY = (ballCenterY - paddleCenterY) / (m.paddleHeight / 2)
    relativeIntersectY = clampFloat(relativeIntersectY, -1.0, 1.0)
    if Abs(relativeIntersectY) < m.minimumBounceAngle then
        if Rnd(0) < 0.5 then
            relativeIntersectY = -m.minimumBounceAngle
        else
            relativeIntersectY = m.minimumBounceAngle
        end if
    end if

    bounceAngle = relativeIntersectY * m.maxBounceAngle
    m.ballVelocityX = direction * m.ballSpeed * Cos(bounceAngle)
    m.ballVelocityY = m.ballSpeed * Sin(bounceAngle)
end sub

'-------------------------------------------------------------------------------
' scorePoint
'-------------------------------------------------------------------------------
sub scorePoint(player as integer)
    if player = 1 then
        m.leftScore = m.leftScore + 1
        m.nextServeDirection = 1
    else
        m.rightScore = m.rightScore + 1
        m.nextServeDirection = -1
    end if

    if m.leftScore >= m.scoreToWin or m.rightScore >= m.scoreToWin then
        m.leftScore = 0
        m.rightScore = 0
    end if

    updateScoreLabels()
    pauseForServe()
end sub

'-------------------------------------------------------------------------------
' pauseForServe
'-------------------------------------------------------------------------------
sub pauseForServe()
    m.serving = true
    resetPositions()
    m.ballVelocityX = 0
    m.ballVelocityY = 0

    if m.serveTimer <> invalid then
        m.serveTimer.control = "stop"
        m.serveTimer.control = "start"
    end if
end sub

'-------------------------------------------------------------------------------
' serveBall
'-------------------------------------------------------------------------------
sub serveBall(direction as integer)
    if direction <> -1 then direction = 1

    resetPositions()
    angle = getRandomServeAngle()
    m.ballVelocityX = direction * m.ballSpeed * Cos(angle)
    m.ballVelocityY = m.ballSpeed * Sin(angle)
    assignMissForDirection(direction)
    m.serving = false
end sub

'-------------------------------------------------------------------------------
' assignMissForDirection
'-------------------------------------------------------------------------------
sub assignMissForDirection(direction as integer)
    if direction < 0 then
        m.leftWillMiss = Rnd(0) < m.missChance
        m.leftAimOffset = getRandomAimOffset()
        m.rightWillMiss = false
        m.rightAimOffset = 0.0
    else
        m.rightWillMiss = Rnd(0) < m.missChance
        m.rightAimOffset = getRandomAimOffset()
        m.leftWillMiss = false
        m.leftAimOffset = 0.0
    end if
end sub

'-------------------------------------------------------------------------------
' getRandomAimOffset
'-------------------------------------------------------------------------------
function getRandomAimOffset() as float
    return (Rnd(0) * (m.paddleAimJitter * 2)) - m.paddleAimJitter
end function

'-------------------------------------------------------------------------------
' getRandomServeAngle
'-------------------------------------------------------------------------------
function getRandomServeAngle() as float
    angle = (Rnd(0) * (m.pi / 3)) - (m.pi / 6)
    if Abs(angle) < 0.15 then
        if angle < 0 then return -0.15
        return 0.15
    end if

    return angle
end function

'-------------------------------------------------------------------------------
' collidesWithLeftPaddle
'-------------------------------------------------------------------------------
function collidesWithLeftPaddle() as boolean
    if m.ballVelocityX >= 0 then return false
    return collides(m.ballX, m.ballY, m.ballSize, m.ballSize, getLeftPaddleX(), m.leftPaddleY, m.paddleWidth, m.paddleHeight)
end function

'-------------------------------------------------------------------------------
' collidesWithRightPaddle
'-------------------------------------------------------------------------------
function collidesWithRightPaddle() as boolean
    if m.ballVelocityX <= 0 then return false
    return collides(m.ballX, m.ballY, m.ballSize, m.ballSize, getRightPaddleX(), m.rightPaddleY, m.paddleWidth, m.paddleHeight)
end function

'-------------------------------------------------------------------------------
' collides
'-------------------------------------------------------------------------------
function collides(x1 as float, y1 as float, width1 as float, height1 as float, x2 as float, y2 as float, width2 as float, height2 as float) as boolean
    return x1 < x2 + width2 and x1 + width1 > x2 and y1 < y2 + height2 and y1 + height1 > y2
end function

'-------------------------------------------------------------------------------
' updatePaddleNodes
'-------------------------------------------------------------------------------
sub updatePaddleNodes()
    if m.leftPaddle <> invalid then m.leftPaddle.translation = [getLeftPaddleX(), int(m.leftPaddleY)]
    if m.rightPaddle <> invalid then m.rightPaddle.translation = [getRightPaddleX(), int(m.rightPaddleY)]
end sub

'-------------------------------------------------------------------------------
' updateBallNode
'-------------------------------------------------------------------------------
sub updateBallNode()
    if m.poster <> invalid then m.poster.translation = [int(m.ballX), int(m.ballY)]
end sub

'-------------------------------------------------------------------------------
' updateScoreLabels
'-------------------------------------------------------------------------------
sub updateScoreLabels()
    if m.leftScoreLabel <> invalid then m.leftScoreLabel.text = m.leftScore.ToStr()
    if m.rightScoreLabel <> invalid then m.rightScoreLabel.text = m.rightScore.ToStr()
end sub

'-------------------------------------------------------------------------------
' getLeftPaddleX
'-------------------------------------------------------------------------------
function getLeftPaddleX() as integer
    return m.paddleInset
end function

'-------------------------------------------------------------------------------
' getRightPaddleX
'-------------------------------------------------------------------------------
function getRightPaddleX() as integer
    return m.screenWidth - m.paddleInset - m.paddleWidth
end function

'-------------------------------------------------------------------------------
' getMaxPaddleY
'-------------------------------------------------------------------------------
function getMaxPaddleY() as float
    return m.screenHeight - m.paddleMargin - m.paddleHeight
end function

'-------------------------------------------------------------------------------
' moveToward
'-------------------------------------------------------------------------------
function moveToward(currentValue as float, targetValue as float, maxDelta as float) as float
    delta = targetValue - currentValue
    if Abs(delta) <= maxDelta then return targetValue
    if delta > 0 then return currentValue + maxDelta
    return currentValue - maxDelta
end function

'-------------------------------------------------------------------------------
' clampFloat
'-------------------------------------------------------------------------------
function clampFloat(value as float, minValue as float, maxValue as float) as float
    if value < minValue then return minValue
    if value > maxValue then return maxValue
    return value
end function
