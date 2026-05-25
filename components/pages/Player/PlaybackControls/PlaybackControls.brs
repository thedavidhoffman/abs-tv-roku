'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    initReferences()
    initValues()
    updateText()
    updateProgress()
    updateChapterMarkers()
    updateChaptersVisibility()
    updatePlayPauseButton()
    updateFocusVisuals()
end sub

'-------------------------------------------------------------------------------
' initReferences
'-------------------------------------------------------------------------------
sub initReferences()
    m.trackTitleLabel = m.top.findNode("trackTitleLabel")
    m.statusLabel = m.top.findNode("statusLabel")
    m.chapterStatusLabel = m.top.findNode("chapterStatusLabel")
    m.progressGroup = m.top.findNode("progressGroup")
    m.progressFill = m.top.findNode("progressFill")
    m.chapterMarkersGroup = m.top.findNode("chapterMarkersGroup")
    m.progressCrossbar = m.top.findNode("progressCrossbar")
    m.currentTimeLabel = m.top.findNode("currentTimeLabel")
    m.totalTimeLabel = m.top.findNode("totalTimeLabel")
    m.buttonGroup = m.top.findNode("buttonGroup")
    m.buttons = [
        m.top.findNode("playPauseButton")
        m.top.findNode("restartButton")
        m.top.findNode("tintButton")
        m.top.findNode("chaptersButton")
    ]
end sub

'-------------------------------------------------------------------------------
' initValues
'-------------------------------------------------------------------------------
sub initValues()
    m.scrub = {
        isActive: false
        targetSeconds: 0
        returnFocusIndex: 0
    }
    m.progressLayout = {
        barWidth: 1040
        timeLabelY: 26
        totalTimeLabelX: 820
        crossbarWidth: 8
        crossbarY: -10
        chapterMarkerWidth: 2
        chapterMarkerTop: 13
        chapterMarkerBottom: 22
        chapterMarkerHeight: 9
        chapterMarkerColor: &hF3F7FB80
    }
    if m.top.focusedIndex = invalid then m.top.focusedIndex = -1
    if m.top.positionSeconds = invalid then m.top.positionSeconds = 0
    if m.top.totalDurationSeconds = invalid then m.top.totalDurationSeconds = 0
end sub

'-------------------------------------------------------------------------------
' onKeyEvent
'-------------------------------------------------------------------------------
function onKeyEvent(key as string, press as boolean) as boolean
    if press = false then return false

    return handleKey(key)
end function

'-------------------------------------------------------------------------------
' handleKey
'-------------------------------------------------------------------------------
function handleKey(key as string) as boolean
    if m.scrub.isActive = true then
        if key = "left" then
            updateScrubTarget(-30)
            return true
        else if key = "right" then
            updateScrubTarget(30)
            return true
        else if key = "OK" or key = "select" or key = "play" or key = "down" then
            emitScrubEvent("commit", "controls")
            return true
        else if key = "up" then
            emitScrubEvent("commit", "description")
            return true
        else if key = "back" then
            emitScrubEvent("cancelClose")
            return true
        end if
    end if

    focusedIndex = m.top.focusedIndex
    if focusedIndex < 0 then return false

    if key = "left" then
        focusButton(focusedIndex - 1)
        return true
    else if key = "right" then
        focusButton(focusedIndex + 1)
        return true
    else if key = "up" then
        requestFocusUp()
        return true
    else if key = "down" then
        return true
    else if key = "OK" or key = "select" then
        selectFocusedButton()
        return true
    end if

    return false
end function

'-------------------------------------------------------------------------------
' focusProgressBar
'-------------------------------------------------------------------------------
sub focusProgressBar(positionSeconds as integer, returnFocusIndex as integer)
    if returnFocusIndex < 0 then returnFocusIndex = 0
    returnFocusIndex = clampButtonIndex(returnFocusIndex)

    m.scrub.isActive = true
    m.scrub.targetSeconds = clampPositionSeconds(positionSeconds)
    m.scrub.returnFocusIndex = returnFocusIndex

    m.top.focusedIndex = -1
    updateFocusVisuals()
    focusProgress()
    showScrubPreview(m.scrub.targetSeconds)
end sub

'-------------------------------------------------------------------------------
' cancelScrub
'-------------------------------------------------------------------------------
sub cancelScrub()
    if m.scrub.isActive <> true then return

    m.scrub.isActive = false
    hideScrubPreview()
end sub

'-------------------------------------------------------------------------------
' isScrubbing
'-------------------------------------------------------------------------------
function isScrubbing() as boolean
    return m.scrub <> invalid and m.scrub.isActive = true
end function

'-------------------------------------------------------------------------------
' setScrubPosition
'-------------------------------------------------------------------------------
sub setScrubPosition(positionSeconds as integer)
    if m.scrub.isActive <> true then return

    m.scrub.targetSeconds = clampPositionSeconds(positionSeconds)
    showScrubPreview(m.scrub.targetSeconds)
end sub

'-------------------------------------------------------------------------------
' focusProgress
'-------------------------------------------------------------------------------
sub focusProgress()
    if m.progressGroup <> invalid then m.progressGroup.setFocus(true)
end sub

'-------------------------------------------------------------------------------
' focusButton
'-------------------------------------------------------------------------------
sub focusButton(index as integer)
    index = clampButtonIndex(index)
    m.top.focusedIndex = index
    button = getButtonAtIndex(index)
    if button <> invalid then button.setFocus(true)
    updateFocusVisuals()
end sub

'-------------------------------------------------------------------------------
' clearFocus
'-------------------------------------------------------------------------------
sub clearFocus()
    m.top.focusedIndex = -1
    updateFocusVisuals()
end sub

'-------------------------------------------------------------------------------
' getButtonCount
'-------------------------------------------------------------------------------
function getButtonCount() as integer
    if m.top.showChapters = true then return 4
    return 3
end function

'-------------------------------------------------------------------------------
' showScrubPreview
'-------------------------------------------------------------------------------
sub showScrubPreview(positionSeconds as integer)
    targetPosition = clampPositionSeconds(positionSeconds)
    updatePosition(targetPosition)
    crossbarX = getProgressX(targetPosition)

    crossbarWidth = m.progressLayout.crossbarWidth
    if m.progressCrossbar <> invalid and m.progressCrossbar.width <> invalid then crossbarWidth = int(m.progressCrossbar.width)
    halfCrossbarWidth = int(crossbarWidth / 2)
    if halfCrossbarWidth < 1 then halfCrossbarWidth = 1

    if crossbarX < halfCrossbarWidth then crossbarX = halfCrossbarWidth
    if crossbarX > m.progressLayout.barWidth - halfCrossbarWidth then crossbarX = m.progressLayout.barWidth - halfCrossbarWidth
    if m.progressCrossbar <> invalid then
        m.progressCrossbar.translation = [crossbarX - halfCrossbarWidth, m.progressLayout.crossbarY]
        m.progressCrossbar.visible = true
    end if
end sub

'-------------------------------------------------------------------------------
' hideScrubPreview
'-------------------------------------------------------------------------------
sub hideScrubPreview()
    if m.progressCrossbar <> invalid then m.progressCrossbar.visible = false
end sub

'-------------------------------------------------------------------------------
' onTrackTitleChanged
'-------------------------------------------------------------------------------
sub onTrackTitleChanged()
    setLabelText(m.trackTitleLabel, m.top.trackTitle)
end sub

'-------------------------------------------------------------------------------
' onStatusTextChanged
'-------------------------------------------------------------------------------
sub onStatusTextChanged()
    setLabelText(m.statusLabel, m.top.statusText)
end sub

'-------------------------------------------------------------------------------
' onProgressChanged
'-------------------------------------------------------------------------------
sub onProgressChanged()
    updateProgress()
end sub

'-------------------------------------------------------------------------------
' onChapterMarkerPositionsChanged
'-------------------------------------------------------------------------------
sub onChapterMarkerPositionsChanged()
    updateChapterMarkers()
end sub

'-------------------------------------------------------------------------------
' onIsPlayingChanged
'-------------------------------------------------------------------------------
sub onIsPlayingChanged()
    updatePlayPauseButton()
end sub

'-------------------------------------------------------------------------------
' onShowChaptersChanged
'-------------------------------------------------------------------------------
sub onShowChaptersChanged()
    updateChaptersVisibility()
end sub

'-------------------------------------------------------------------------------
' onFocusedIndexChanged
'-------------------------------------------------------------------------------
sub onFocusedIndexChanged()
    index = m.top.focusedIndex
    if index >= getButtonCount() then m.top.focusedIndex = getButtonCount() - 1
    updateFocusVisuals()
end sub

'-------------------------------------------------------------------------------
' selectFocusedButton
'-------------------------------------------------------------------------------
sub selectFocusedButton()
    action = getActionForIndex(m.top.focusedIndex)
    if action = "" then return

    m.top.selectedAction = {
        action: action
    }
end sub

'-------------------------------------------------------------------------------
' requestFocusUp
'-------------------------------------------------------------------------------
sub requestFocusUp()
    m.top.focusUpRequested = {
        focusedIndex: m.top.focusedIndex
    }
end sub

'-------------------------------------------------------------------------------
' updateScrubTarget
'-------------------------------------------------------------------------------
sub updateScrubTarget(offsetSeconds as integer)
    if m.scrub.isActive <> true then return

    m.scrub.targetSeconds = clampPositionSeconds(m.scrub.targetSeconds + offsetSeconds)
    showScrubPreview(m.scrub.targetSeconds)
    emitScrubEvent("preview")
end sub

'-------------------------------------------------------------------------------
' emitScrubEvent
'-------------------------------------------------------------------------------
sub emitScrubEvent(eventType as string, nextFocus = "" as string)
    event = {
        type: eventType
        targetSeconds: m.scrub.targetSeconds
        returnFocusIndex: m.scrub.returnFocusIndex
    }
    if nextFocus <> "" then event.nextFocus = nextFocus
    m.top.scrubEvent = event
end sub

'-------------------------------------------------------------------------------
' updateText
'-------------------------------------------------------------------------------
sub updateText()
    setLabelText(m.trackTitleLabel, m.top.trackTitle)
    setLabelText(m.statusLabel, m.top.statusText)
end sub

'-------------------------------------------------------------------------------
' updatePosition
'-------------------------------------------------------------------------------
sub updatePosition(positionSeconds as integer)
    positionSeconds = clampPositionSeconds(positionSeconds)

    setLabelText(m.currentTimeLabel, formatPlaybackTime(positionSeconds))
    setLabelText(m.chapterStatusLabel, "-" + formatPlaybackTime(getRemainingSeconds(positionSeconds)))

    fillWidth = getProgressX(positionSeconds)
    if fillWidth < 0 then fillWidth = 0
    if fillWidth > m.progressLayout.barWidth then fillWidth = m.progressLayout.barWidth
    if m.progressFill <> invalid then
        m.progressFill.visible = (fillWidth > 0)
        if fillWidth <= 0 then fillWidth = 1
        m.progressFill.width = fillWidth
    end if
end sub

'-------------------------------------------------------------------------------
' updateProgress
'-------------------------------------------------------------------------------
sub updateProgress()
    setLabelText(m.totalTimeLabel, formatPlaybackTime(getTotalDurationSeconds()))
    updatePosition(getPositionSeconds())
end sub

'-------------------------------------------------------------------------------
' updateChapterMarkers
'-------------------------------------------------------------------------------
sub updateChapterMarkers()
    if m.chapterMarkersGroup = invalid then return

    while m.chapterMarkersGroup.getChildCount() > 0
        child = m.chapterMarkersGroup.getChild(0)
        if child = invalid then exit while
        m.chapterMarkersGroup.removeChild(child)
    end while

    positions = m.top.chapterMarkerPositions
    hasChapterMarkers = (positions <> invalid and positions.Count() > 1 and getTotalDurationSeconds() > 0)
    if hasChapterMarkers = true then
        markerWidth = m.progressLayout.chapterMarkerWidth
        markerTop = m.progressLayout.chapterMarkerTop
        markerBottom = m.progressLayout.chapterMarkerBottom
        markerHeight = markerBottom - markerTop
        m.progressLayout.chapterMarkerHeight = markerHeight
        halfMarkerWidth = int(markerWidth / 2)
        if halfMarkerWidth < 1 then halfMarkerWidth = 1

        for each position in positions
            markerX = getProgressX(position)
            if markerX < halfMarkerWidth then markerX = halfMarkerWidth
            if markerX > m.progressLayout.barWidth - halfMarkerWidth then markerX = m.progressLayout.barWidth - halfMarkerWidth

            marker = CreateObject("roSGNode", "Rectangle")
            if marker <> invalid then
                marker.width = markerWidth
                marker.height = markerHeight
                marker.translation = [markerX - halfMarkerWidth, markerTop]
                marker.color = m.progressLayout.chapterMarkerColor
                m.chapterMarkersGroup.appendChild(marker)
            end if
        end for
    end if

    updateChapterMarkerLayout(hasChapterMarkers)
end sub

'-------------------------------------------------------------------------------
' updateChapterMarkerLayout
'-------------------------------------------------------------------------------
sub updateChapterMarkerLayout(hasChapterMarkers as boolean)
    offsetY = 0
    if hasChapterMarkers = true then offsetY = m.progressLayout.chapterMarkerHeight

    if m.currentTimeLabel <> invalid then m.currentTimeLabel.translation = [0, m.progressLayout.timeLabelY + offsetY]
    if m.totalTimeLabel <> invalid then m.totalTimeLabel.translation = [m.progressLayout.totalTimeLabelX, m.progressLayout.timeLabelY + offsetY]
    if m.buttonGroup <> invalid then m.buttonGroup.translation = [0, 185 + offsetY]
end sub

'-------------------------------------------------------------------------------
' updateChaptersVisibility
'-------------------------------------------------------------------------------
sub updateChaptersVisibility()
    chaptersButton = getButtonAtIndex(3)
    if chaptersButton <> invalid then
        chaptersButton.visible = (m.top.showChapters = true)
        if m.top.showChapters <> true then chaptersButton.hasFocusVisual = false
    end if

    if m.top.showChapters <> true and m.top.focusedIndex > 2 then m.top.focusedIndex = 2
    updateFocusVisuals()
end sub

'-------------------------------------------------------------------------------
' updatePlayPauseButton
'-------------------------------------------------------------------------------
sub updatePlayPauseButton()
    playPauseButton = getButtonAtIndex(0)
    if playPauseButton = invalid then return

    if m.top.isPlaying = true then
        playPauseButton.text = "Pause"
        playPauseButton.iconUri = "pkg:/images/icons/pause.png"
    else
        playPauseButton.text = "Play"
        playPauseButton.iconUri = "pkg:/images/icons/play.png"
    end if
end sub

'-------------------------------------------------------------------------------
' updateFocusVisuals
'-------------------------------------------------------------------------------
sub updateFocusVisuals()
    buttonCount = getButtonCount()
    focusedIndex = m.top.focusedIndex
    if focusedIndex >= buttonCount then focusedIndex = buttonCount - 1

    for i = 0 to m.buttons.Count() - 1
        button = m.buttons[i]
        if button <> invalid then button.hasFocusVisual = (i = focusedIndex and i < buttonCount)
    end for
end sub

'-------------------------------------------------------------------------------
' getProgressX
'-------------------------------------------------------------------------------
function getProgressX(positionSeconds as integer) as integer
    totalDurationSeconds = getTotalDurationSeconds()
    if totalDurationSeconds <= 0 then return 0

    return int((positionSeconds / totalDurationSeconds) * m.progressLayout.barWidth)
end function

'-------------------------------------------------------------------------------
' clampPositionSeconds
'-------------------------------------------------------------------------------
function clampPositionSeconds(positionSeconds as integer) as integer
    if positionSeconds < 0 then positionSeconds = 0
    totalDurationSeconds = getTotalDurationSeconds()
    if totalDurationSeconds > 0 and positionSeconds > totalDurationSeconds then positionSeconds = totalDurationSeconds

    return positionSeconds
end function

'-------------------------------------------------------------------------------
' getRemainingSeconds
'-------------------------------------------------------------------------------
function getRemainingSeconds(positionSeconds as integer) as integer
    totalDurationSeconds = getTotalDurationSeconds()
    if totalDurationSeconds <= 0 then return 0

    remainingSeconds = totalDurationSeconds - positionSeconds
    if remainingSeconds < 0 then return 0
    return remainingSeconds
end function

'-------------------------------------------------------------------------------
' getPositionSeconds
'-------------------------------------------------------------------------------
function getPositionSeconds() as integer
    if m.top.positionSeconds = invalid then return 0
    return m.top.positionSeconds
end function

'-------------------------------------------------------------------------------
' getTotalDurationSeconds
'-------------------------------------------------------------------------------
function getTotalDurationSeconds() as integer
    if m.top.totalDurationSeconds = invalid then return 0
    return m.top.totalDurationSeconds
end function

'-------------------------------------------------------------------------------
' clampButtonIndex
'-------------------------------------------------------------------------------
function clampButtonIndex(index as integer) as integer
    if index < 0 then index = 0

    buttonCount = getButtonCount()
    if index >= buttonCount then index = buttonCount - 1
    if index < 0 then index = 0

    return index
end function

'-------------------------------------------------------------------------------
' getButtonAtIndex
'-------------------------------------------------------------------------------
function getButtonAtIndex(index as integer) as dynamic
    if m.buttons = invalid then return invalid
    if index < 0 or index >= m.buttons.Count() then return invalid

    return m.buttons[index]
end function

'-------------------------------------------------------------------------------
' getActionForIndex
'-------------------------------------------------------------------------------
function getActionForIndex(index as integer) as string
    if index = 0 then return "playPause"
    if index = 1 then return "restart"
    if index = 2 then return "tint"
    if index = 3 and m.top.showChapters = true then return "chapters"
    return ""
end function

'-------------------------------------------------------------------------------
' setLabelText
'-------------------------------------------------------------------------------
sub setLabelText(label as dynamic, text as dynamic)
    if label <> invalid then label.text = SafeString(text, "")
end sub

'-------------------------------------------------------------------------------
' formatPlaybackTime
'-------------------------------------------------------------------------------
function formatPlaybackTime(totalSeconds as integer) as string
    if totalSeconds < 0 then totalSeconds = 0

    hours = int(totalSeconds / 3600)
    minutes = int((totalSeconds mod 3600) / 60)
    seconds = totalSeconds mod 60
    secondsText = seconds.ToStr()
    if seconds < 10 then secondsText = "0" + secondsText

    if hours > 0 then
        minutesText = minutes.ToStr()
        if minutes < 10 then minutesText = "0" + minutesText
        return hours.ToStr() + ":" + minutesText + ":" + secondsText
    end if

    return minutes.ToStr() + ":" + secondsText
end function
