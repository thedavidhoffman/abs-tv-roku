'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.cover = m.top.findNode("cover")
    m.titleLabel = m.top.findNode("titleLabel")
    m.authorLabel = m.top.findNode("authorLabel")
    m.narratorLabel = m.top.findNode("narratorLabel")
    m.descriptionLabel = m.top.findNode("descriptionLabel")
    m.descriptionFocusRing = m.top.findNode("descriptionFocusRing")
    m.publisherLabel = m.top.findNode("publisherLabel")
    m.publishDateLabel = m.top.findNode("publishDateLabel")
    m.durationLabel = m.top.findNode("durationLabel")
    m.statusLabel = m.top.findNode("statusLabel")
    m.progressFill = m.top.findNode("progressFill")
    m.progressTrack = m.top.findNode("progressTrack")
    m.currentTimeLabel = m.top.findNode("currentTimeLabel")
    m.totalTimeLabel = m.top.findNode("totalTimeLabel")
    m.progressTimer = m.top.findNode("progressTimer")
    m.rewindButton = m.top.findNode("rewindButton")
    m.playPauseButton = m.top.findNode("playPauseButton")
    m.forwardButton = m.top.findNode("forwardButton")
    m.descriptionModal = m.top.findNode("descriptionModal")
    m.descriptionModalBackdrop = m.top.findNode("descriptionModalBackdrop")
    m.descriptionModalPanel = m.top.findNode("descriptionModalPanel")
    m.modalDescriptionLabel = m.top.findNode("modalDescriptionLabel")
    m.modalScrollbarTrack = m.top.findNode("modalScrollbarTrack")
    m.modalScrollbarThumb = m.top.findNode("modalScrollbarThumb")
    m.modalCloseButton = m.top.findNode("modalCloseButton")
    m.audioPlayer = m.top.findNode("audioPlayer")
    m.playbackApiTask = m.top.findNode("playbackApiTask")
    m.closeRequestedCounter = 0
    m.tracks = []
    m.currentTrackIndex = 0
    m.isPaused = false
    m.totalDurationSeconds = 0
    m.progressBarWidth = 1040
    m.transportFocusIndex = -1
    m.transportButtons = [
        m.rewindButton
        m.playPauseButton
        m.forwardButton
    ]
    m.fullDescription = ""
    m.descriptionIsExpandable = false
    m.descriptionHasFocus = false
    m.descriptionScrollY = 0
    m.descriptionScrollStep = 80
    m.descriptionViewportHeight = 450
    m.descriptionLineHeight = 34
    m.descriptionContentHeight = 450
    m.modalScrollbarTrackHeight = 450
    m.modalScrollbarBaseY = 285

    m.playbackApiTask.observeField("response", "onPlaybackApiResponse")
    if m.progressTimer <> invalid then m.progressTimer.observeField("fire", "onProgressTimerFired")
    if m.audioPlayer <> invalid then m.audioPlayer.observeField("state", "onAudioStateChanged")
    styleProgressBar()
    styleDescriptionModal()
    updateDescriptionFocus(false)
    updateTransportFocus(-1)
    updatePlayPauseButton()
end sub

'-------------------------------------------------------------------------------
' onPlayRequestChanged
'-------------------------------------------------------------------------------
sub onPlayRequestChanged()
    request = m.top.playRequest
    if request = invalid then return

    if m.cover <> invalid then m.cover.uri = SafeString(request.coverUrl, "pkg:/images/placeholder_cover.png")
    if m.titleLabel <> invalid then m.titleLabel.text = SafeString(request.title, "Audiobook")
    updateDetails(request.details)
    resetProgress()
    setStatus("Starting playback...")

    m.playbackApiTask.request = {
        action: "startPlayback"
        server: request.server
        token: request.token
        itemId: request.itemId
        title: request.title
    }
    m.playbackApiTask.control = "run"
end sub

'-------------------------------------------------------------------------------
' onPlaybackApiResponse
'-------------------------------------------------------------------------------
sub onPlaybackApiResponse()
    response = m.playbackApiTask.response
    if response = invalid then return

    if response.ok <> true then
        m.top.errorResponse = response
        setStatus(SafeString(response.errorMessage, "Unable to start playback."))
        return
    end if

    playTracks(response.tracks)
end sub

'-------------------------------------------------------------------------------
' updateDetails
'-------------------------------------------------------------------------------
sub updateDetails(details as dynamic)
    if details = invalid then details = {}

    m.fullDescription = FirstNonEmpty([details.description], "No description available.")
    m.descriptionIsExpandable = descriptionNeedsModal(m.fullDescription)
    m.descriptionScrollY = 0
    updateDescriptionFocus(false)

    setLabelText(m.authorLabel, getSingularPluralText("Author", details.authorCount) + ": " + FirstNonEmpty([details.authors], "Unknown"))
    setLabelText(m.narratorLabel, getSingularPluralText("Narrator", details.narratorCount) + ": " + FirstNonEmpty([details.narrators], "Unknown"))
    setLabelText(m.descriptionLabel, m.fullDescription)
    setLabelText(m.publisherLabel, "Publisher: " + FirstNonEmpty([details.publisher], "Unknown"))
    setLabelText(m.publishDateLabel, "Published: " + FirstNonEmpty([details.publishDate], "Unknown"))
    setLabelText(m.durationLabel, "Duration: " + FirstNonEmpty([details.duration], "Unknown"))

    m.totalDurationSeconds = 0
    if details.durationSeconds <> invalid then m.totalDurationSeconds = int(val(details.durationSeconds.ToStr()))
    if m.totalDurationSeconds > 0 then
        setLabelText(m.totalTimeLabel, formatPlaybackTime(m.totalDurationSeconds))
    else
        setLabelText(m.totalTimeLabel, "0:00")
    end if
end sub

'-------------------------------------------------------------------------------
' descriptionNeedsModal
'-------------------------------------------------------------------------------
function descriptionNeedsModal(description as string) as boolean
    if Len(description) > 420 then return true
    if Instr(1, description, Chr(10)) > 0 then return true
    return false
end function

'-------------------------------------------------------------------------------
' getSingularPluralText
'-------------------------------------------------------------------------------
function getSingularPluralText(singularLabel as string, count as dynamic) as string
    if count <> invalid and int(val(count.ToStr())) > 1 then return singularLabel + "s"
    return singularLabel
end function

'-------------------------------------------------------------------------------
' setLabelText
'-------------------------------------------------------------------------------
sub setLabelText(label as dynamic, text as string)
    if label <> invalid then label.text = text
end sub

'-------------------------------------------------------------------------------
' playTracks
'-------------------------------------------------------------------------------
sub playTracks(tracks as dynamic)
    if m.audioPlayer = invalid then return
    if tracks = invalid or tracks.Count() = 0 then
        setStatus("No playable audio tracks were returned.")
        return
    end if

    m.tracks = tracks
    m.currentTrackIndex = 0
    playCurrentTrack()
end sub

'-------------------------------------------------------------------------------
' playCurrentTrack
'-------------------------------------------------------------------------------
sub playCurrentTrack()
    if m.audioPlayer = invalid then return
    if m.tracks = invalid or m.currentTrackIndex < 0 or m.currentTrackIndex >= m.tracks.Count() then return

    track = m.tracks[m.currentTrackIndex]
    node = CreateObject("roSGNode", "ContentNode")
    node.url = track.url
    node.title = SafeString(track.title, "Audiobook")
    node.streamFormat = getStreamFormat(track.mimeType, track.url)
    node.contentType = "audio"

    ? "player track"; " index="; m.currentTrackIndex; " format="; node.streamFormat; " url="; node.url

    m.audioPlayer.content = node
    m.isPaused = false
    m.audioPlayer.control = "play"
    setStatus("Playing")
    updatePlayPauseButton()
end sub

'-------------------------------------------------------------------------------
' getStreamFormat
'-------------------------------------------------------------------------------
function getStreamFormat(mimeType as dynamic, url as dynamic) as string
    streamUrl = LCase(SafeString(url, ""))
    if Instr(1, streamUrl, ".m3u8") > 0 or Instr(1, streamUrl, "/hls/") > 0 then return "hls"

    mime = LCase(SafeString(mimeType, "audio/mpeg"))
    if Instr(1, mime, "mp4") > 0 or Instr(1, mime, "m4a") > 0 or Instr(1, mime, "m4b") > 0 then return "mp4"
    if Instr(1, mime, "aac") > 0 then return "aac"
    return "mp3"
end function

'-------------------------------------------------------------------------------
' onAudioStateChanged
'-------------------------------------------------------------------------------
sub onAudioStateChanged()
    if m.audioPlayer = invalid then return

    state = SafeString(m.audioPlayer.state, "")
    if state = "playing" then
        m.isPaused = false
        setStatus("Playing")
        startProgressTimer()
        updatePlayPauseButton()
    else if state = "buffering" then
        setStatus("Buffering...")
        startProgressTimer()
    else if state = "finished" then
        if playNextTrack() then
            return
        end if
        stopProgressTimer()
        updateProgress(m.totalDurationSeconds)
        setStatus("Finished")
        m.isPaused = false
        updatePlayPauseButton()
    else if state = "error" then
        stopProgressTimer()
        setStatus("Playback error.")
        m.isPaused = false
        updatePlayPauseButton()
    end if
end sub

'-------------------------------------------------------------------------------
' playNextTrack
'-------------------------------------------------------------------------------
function playNextTrack() as boolean
    if m.tracks = invalid then return false
    nextIndex = m.currentTrackIndex + 1
    if nextIndex >= m.tracks.Count() then return false

    m.currentTrackIndex = nextIndex
    playCurrentTrack()
    return true
end function

'-------------------------------------------------------------------------------
' setStatus
'-------------------------------------------------------------------------------
sub setStatus(message as string)
    if m.statusLabel <> invalid then m.statusLabel.text = message
end sub

'-------------------------------------------------------------------------------
' closePlayer
'-------------------------------------------------------------------------------
sub closePlayer()
    if m.audioPlayer <> invalid then m.audioPlayer.control = "stop"
    stopProgressTimer()
    m.closeRequestedCounter = m.closeRequestedCounter + 1
    m.top.closeRequested = m.closeRequestedCounter
end sub

'-------------------------------------------------------------------------------
' onKeyEvent
'-------------------------------------------------------------------------------
function onKeyEvent(key as string, press as boolean) as boolean
    if press = false then return false

    if m.descriptionModal <> invalid and m.descriptionModal.visible then
        if key = "back" or key = "OK" or key = "select" then
            closeDescriptionModal()
            return true
        else if key = "down" or key = "right" then
            scrollDescriptionModal(1)
            return true
        else if key = "up" or key = "left" then
            scrollDescriptionModal(-1)
            return true
        end if
    end if

    if key = "back" then
        closePlayer()
        return true
    end if

    if m.transportFocusIndex >= 0 then
        if key = "left" then
            focusTransportButton(m.transportFocusIndex - 1)
            return true
        else if key = "right" then
            focusTransportButton(m.transportFocusIndex + 1)
            return true
        else if key = "up" then
            updateTransportFocus(-1)
            return true
        else if key = "OK" or key = "select" then
            activateTransportButton()
            return true
        end if
    end if

    if m.descriptionHasFocus then
        if key = "OK" or key = "select" then
            openDescriptionModal()
            return true
        else if key = "up" then
            updateDescriptionFocus(false)
            return true
        else if key = "down" then
            updateDescriptionFocus(false)
            focusTransportButton(1)
            return true
        end if
    end if

    if m.descriptionIsExpandable and key = "down" then
        updateDescriptionFocus(true)
        return true
    end if

    if key = "down" then
        focusTransportButton(1)
        return true
    end if

    if key = "play" or key = "OK" or key = "select" then
        togglePlayPause()
        return true
    end if

    return false
end function

'-------------------------------------------------------------------------------
' focusTransportButton
'-------------------------------------------------------------------------------
sub focusTransportButton(index as integer)
    if index < 0 then index = 0
    if index >= m.transportButtons.Count() then index = m.transportButtons.Count() - 1
    updateDescriptionFocus(false)
    updateTransportFocus(index)

    button = m.transportButtons[index]
    if button <> invalid then button.setFocus(true)
end sub

'-------------------------------------------------------------------------------
' updateTransportFocus
'-------------------------------------------------------------------------------
sub updateTransportFocus(index as integer)
    m.transportFocusIndex = index
    for i = 0 to m.transportButtons.Count() - 1
        button = m.transportButtons[i]
        if button <> invalid then button.hasFocusVisual = (i = index)
    end for
end sub

'-------------------------------------------------------------------------------
' activateTransportButton
'-------------------------------------------------------------------------------
sub activateTransportButton()
    if m.transportFocusIndex = 0 then
        seekRelative(-30)
    else if m.transportFocusIndex = 1 then
        togglePlayPause()
    else if m.transportFocusIndex = 2 then
        seekRelative(30)
    end if
end sub

'-------------------------------------------------------------------------------
' togglePlayPause
'-------------------------------------------------------------------------------
sub togglePlayPause()
    if m.audioPlayer = invalid then return

    if m.isPaused <> true and m.audioPlayer.state = "playing" then
        m.audioPlayer.control = "pause"
        m.isPaused = true
        stopProgressTimer()
        updateProgress(getCurrentPlaybackPosition())
        setStatus("Paused")
    else
        m.isPaused = false
        if m.audioPlayer.state = "paused" then
            m.audioPlayer.control = "resume"
        else
            m.audioPlayer.control = "play"
        end if
        startProgressTimer()
        setStatus("Playing")
    end if

    updatePlayPauseButton()
end sub

'-------------------------------------------------------------------------------
' updatePlayPauseButton
'-------------------------------------------------------------------------------
sub updatePlayPauseButton()
    if m.playPauseButton = invalid then return

    if m.isPaused = true or (m.audioPlayer <> invalid and m.audioPlayer.state <> "playing") then
        m.playPauseButton.text = "Play"
    else
        m.playPauseButton.text = "Pause"
    end if
end sub

'-------------------------------------------------------------------------------
' seekRelative
'-------------------------------------------------------------------------------
sub seekRelative(offsetSeconds as integer)
    if m.audioPlayer = invalid then return

    nextPosition = getCurrentPlaybackPosition() + offsetSeconds
    if nextPosition < 0 then nextPosition = 0
    if m.totalDurationSeconds > 0 and nextPosition > m.totalDurationSeconds then nextPosition = m.totalDurationSeconds

    m.audioPlayer.seek = nextPosition
    m.audioPlayer.control = "seek"
    updateProgress(nextPosition)
end sub

'-------------------------------------------------------------------------------
' updateDescriptionFocus
'-------------------------------------------------------------------------------
sub updateDescriptionFocus(hasFocus as boolean)
    m.descriptionHasFocus = hasFocus and m.descriptionIsExpandable
    if m.descriptionFocusRing = invalid then return

    if m.descriptionHasFocus then
        m.descriptionFocusRing.color = &hE09B4233
    else
        m.descriptionFocusRing.color = &hE09B4200
    end if
end sub

'-------------------------------------------------------------------------------
' openDescriptionModal
'-------------------------------------------------------------------------------
sub openDescriptionModal()
    if m.descriptionIsExpandable <> true then return
    if m.descriptionModal = invalid then return

    styleDescriptionModal()
    m.descriptionScrollY = 0
    updateModalDescriptionText()
    m.descriptionModal.visible = true
    if m.modalCloseButton <> invalid then
        m.modalCloseButton.hasFocusVisual = true
        m.modalCloseButton.setFocus(true)
    end if
end sub

'-------------------------------------------------------------------------------
' styleDescriptionModal
'-------------------------------------------------------------------------------
sub styleDescriptionModal()
    if m.descriptionModalBackdrop <> invalid then m.descriptionModalBackdrop.color = &h000000FF
    if m.descriptionModalPanel <> invalid then m.descriptionModalPanel.color = &h101B2BFF
    if m.modalScrollbarTrack <> invalid then m.modalScrollbarTrack.color = &h555555FF
    if m.modalScrollbarThumb <> invalid then m.modalScrollbarThumb.color = &hE09B42FF
end sub

'-------------------------------------------------------------------------------
' closeDescriptionModal
'-------------------------------------------------------------------------------
sub closeDescriptionModal()
    if m.descriptionModal <> invalid then m.descriptionModal.visible = false
    if m.modalCloseButton <> invalid then m.modalCloseButton.hasFocusVisual = false
    if m.descriptionLabel <> invalid then m.descriptionLabel.setFocus(true)
end sub

'-------------------------------------------------------------------------------
' scrollDescriptionModal
'-------------------------------------------------------------------------------
sub scrollDescriptionModal(offset as integer)
    if m.modalDescriptionLabel = invalid then return

    maxScrollY = getDescriptionMaxScrollY()

    nextScrollY = m.descriptionScrollY
    if offset > 0 then nextScrollY = m.descriptionScrollY + m.descriptionScrollStep
    if offset < 0 then nextScrollY = m.descriptionScrollY - m.descriptionScrollStep

    if nextScrollY < 0 then nextScrollY = 0
    if nextScrollY > maxScrollY then nextScrollY = maxScrollY

    m.descriptionScrollY = nextScrollY
    updateModalDescriptionText()
end sub

'-------------------------------------------------------------------------------
' updateModalDescriptionText
'-------------------------------------------------------------------------------
sub updateModalDescriptionText()
    if m.modalDescriptionLabel = invalid then return

    m.modalDescriptionLabel.text = m.fullDescription
    updateDescriptionContentHeight()
    maxScrollY = getDescriptionMaxScrollY()
    if m.descriptionScrollY > maxScrollY then m.descriptionScrollY = maxScrollY
    m.modalDescriptionLabel.translation = [0, -m.descriptionScrollY]
    updateModalScrollbar()
end sub

'-------------------------------------------------------------------------------
' getDescriptionMaxScrollY
'-------------------------------------------------------------------------------
function getDescriptionMaxScrollY() as integer
    contentHeight = getDescriptionContentHeight()
    maxScrollY = contentHeight - m.descriptionViewportHeight - (m.descriptionLineHeight * 4)
    if maxScrollY < 0 then maxScrollY = 0
    return maxScrollY
end function

'-------------------------------------------------------------------------------
' updateDescriptionContentHeight
'-------------------------------------------------------------------------------
sub updateDescriptionContentHeight()
    m.descriptionContentHeight = getEstimatedDescriptionContentHeight()

    if m.modalDescriptionLabel <> invalid then
        bounds = m.modalDescriptionLabel.boundingRect()
        if bounds <> invalid and bounds.height <> invalid and bounds.height > m.descriptionContentHeight then
            m.descriptionContentHeight = int(bounds.height)
        end if
    end if
end sub

'-------------------------------------------------------------------------------
' getDescriptionContentHeight
'-------------------------------------------------------------------------------
function getDescriptionContentHeight() as integer
    if m.descriptionContentHeight = invalid or m.descriptionContentHeight <= 0 then
        return getEstimatedDescriptionContentHeight()
    end if

    return m.descriptionContentHeight
end function

'-------------------------------------------------------------------------------
' getEstimatedDescriptionContentHeight
'-------------------------------------------------------------------------------
function getEstimatedDescriptionContentHeight() as integer
    estimatedLineCount = int(Len(m.fullDescription) / 42) + 1
    for i = 1 to Len(m.fullDescription)
        if Mid(m.fullDescription, i, 1) = Chr(10) then estimatedLineCount = estimatedLineCount + 1
    end for

    estimatedHeight = estimatedLineCount * m.descriptionLineHeight
    if estimatedHeight < m.descriptionViewportHeight then estimatedHeight = m.descriptionViewportHeight
    return estimatedHeight
end function

'-------------------------------------------------------------------------------
' updateModalScrollbar
'-------------------------------------------------------------------------------
sub updateModalScrollbar()
    if m.modalScrollbarThumb = invalid then return

    maxScrollY = getDescriptionMaxScrollY()
    if maxScrollY <= 0 then
        m.modalScrollbarThumb.visible = false
        return
    end if

    m.modalScrollbarThumb.visible = true
    thumbHeight = int((m.descriptionViewportHeight / getDescriptionContentHeight()) * m.modalScrollbarTrackHeight)
    if thumbHeight < 56 then thumbHeight = 56
    if thumbHeight > m.modalScrollbarTrackHeight then thumbHeight = m.modalScrollbarTrackHeight

    maxThumbY = m.modalScrollbarTrackHeight - thumbHeight
    thumbY = m.modalScrollbarBaseY + int((m.descriptionScrollY / maxScrollY) * maxThumbY)

    m.modalScrollbarThumb.height = thumbHeight
    m.modalScrollbarThumb.translation = [m.modalScrollbarThumb.translation[0], thumbY]
end sub

'-------------------------------------------------------------------------------
' onProgressTimerFired
'-------------------------------------------------------------------------------
sub onProgressTimerFired()
    updateProgress(getCurrentPlaybackPosition())
end sub

'-------------------------------------------------------------------------------
' getCurrentPlaybackPosition
'-------------------------------------------------------------------------------
function getCurrentPlaybackPosition() as integer
    if m.audioPlayer = invalid or m.audioPlayer.position = invalid then return 0
    return int(val(m.audioPlayer.position.ToStr()))
end function

'-------------------------------------------------------------------------------
' updateProgress
'-------------------------------------------------------------------------------
sub updateProgress(positionSeconds as integer)
    if positionSeconds < 0 then positionSeconds = 0
    if m.totalDurationSeconds > 0 and positionSeconds > m.totalDurationSeconds then positionSeconds = m.totalDurationSeconds

    setLabelText(m.currentTimeLabel, formatPlaybackTime(positionSeconds))

    fillWidth = 0
    if m.totalDurationSeconds > 0 then
        fillWidth = int((positionSeconds / m.totalDurationSeconds) * m.progressBarWidth)
    end if

    if fillWidth < 0 then fillWidth = 0
    if fillWidth > m.progressBarWidth then fillWidth = m.progressBarWidth
    if m.progressFill <> invalid then
        m.progressFill.visible = (fillWidth > 0)
        if fillWidth <= 0 then fillWidth = 1
        m.progressFill.width = fillWidth
    end if
end sub

'-------------------------------------------------------------------------------
' styleProgressBar
'-------------------------------------------------------------------------------
sub styleProgressBar()
    if m.progressTrack <> invalid then m.progressTrack.color = &h555555FF
    if m.progressFill <> invalid then m.progressFill.color = &hE09B42FF
end sub

'-------------------------------------------------------------------------------
' resetProgress
'-------------------------------------------------------------------------------
sub resetProgress()
    updateProgress(0)
end sub

'-------------------------------------------------------------------------------
' startProgressTimer
'-------------------------------------------------------------------------------
sub startProgressTimer()
    if m.progressTimer <> invalid then m.progressTimer.control = "start"
    updateProgress(getCurrentPlaybackPosition())
end sub

'-------------------------------------------------------------------------------
' stopProgressTimer
'-------------------------------------------------------------------------------
sub stopProgressTimer()
    if m.progressTimer <> invalid then m.progressTimer.control = "stop"
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
