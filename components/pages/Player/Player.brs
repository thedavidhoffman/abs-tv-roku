'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    initReferences()
    initValues()
    initHandlers()
    initStyle()
    styleProgressBar()
    styleDescriptionModal()
    updateDescriptionFocus(false)
    updateChaptersButtonVisibility()
    updateTransportFocus(-1)
    updatePlayPauseButton()
end sub

'-------------------------------------------------------------------------------
' initReferences
'-------------------------------------------------------------------------------
sub initReferences()
    m.playerBg = m.top.findNode("playerBg")
    m.cover = m.top.findNode("cover")
    m.titleLabel = m.top.findNode("titleLabel")
    m.authorLabel = m.top.findNode("authorLabel")
    m.metadataLabel = m.top.findNode("metadataLabel")
    m.descriptionLabel = m.top.findNode("descriptionLabel")
    m.descriptionFocusRing = m.top.findNode("descriptionFocusRing")
    m.trackTitleLabel = m.top.findNode("trackTitleLabel")
    m.statusLabel = m.top.findNode("statusLabel")
    m.progressFill = m.top.findNode("progressFill")
    m.progressTrack = m.top.findNode("progressTrack")
    m.currentTimeLabel = m.top.findNode("currentTimeLabel")
    m.totalTimeLabel = m.top.findNode("totalTimeLabel")
    m.progressTimer = m.top.findNode("progressTimer")
    m.seekHoldTimer = m.top.findNode("seekHoldTimer")
    m.closeTimer = m.top.findNode("closeTimer")
    m.rewindButton = m.top.findNode("rewindButton")
    m.playPauseButton = m.top.findNode("playPauseButton")
    m.forwardButton = m.top.findNode("forwardButton")
    m.chaptersButton = m.top.findNode("chaptersButton")
    m.descriptionModal = m.top.findNode("descriptionModal")
    m.descriptionModalBackdrop = m.top.findNode("descriptionModalBackdrop")
    m.descriptionModalPanel = m.top.findNode("descriptionModalPanel")
    m.modalTitleLabel = m.top.findNode("modalTitleLabel")
    m.modalDescriptionLabel = m.top.findNode("modalDescriptionLabel")
    m.modalScrollbarTrack = m.top.findNode("modalScrollbarTrack")
    m.modalScrollbarThumb = m.top.findNode("modalScrollbarThumb")
    m.chapterList = m.top.findNode("chapterList")
    m.audioPlayer = m.top.findNode("audioPlayer")
end sub

'-------------------------------------------------------------------------------
' initValues
'-------------------------------------------------------------------------------
sub initValues()
    m.closeRequestedCounter = 0
    m.audiobookTitle = "Audiobook"
    m.tracks = []
    m.currentTrackIndex = 0
    m.currentTrackStartPosition = 0
    m.requestedStartPositionSeconds = 0
    m.pendingTrackSeekPosition = invalid
    m.isPaused = false
    m.totalDurationSeconds = 0
    m.progressBarWidth = 1040
    m.transportFocusIndex = -1
    m.seekHoldDirection = 0
    m.seekHoldTally = 0
    m.seekHoldSeconds = 0
    m.seekHoldStartPosition = 0
    m.ignoreNextFinished = false
    m.transportButtons = [
        m.rewindButton
        m.playPauseButton
        m.forwardButton
        m.chaptersButton
    ]
    m.fullDescription = ""
    m.descriptionIsExpandable = false
    m.descriptionHasFocus = false
    m.descriptionScrollY = 0
    m.descriptionScrollStep = 80
    m.descriptionViewportHeight = 600
    m.descriptionLineHeight = 34
    m.descriptionContentHeight = 600
    m.modalScrollbarTrackHeight = 600
    m.modalScrollbarBaseY = 285
    m.isClosing = false
end sub

'-------------------------------------------------------------------------------
' initHandlers
'-------------------------------------------------------------------------------
sub initHandlers()
    if m.progressTimer <> invalid then m.progressTimer.observeField("fire", "onProgressTimerFired")
    if m.seekHoldTimer <> invalid then m.seekHoldTimer.observeField("fire", "onSeekHoldTimerFired")
    if m.closeTimer <> invalid then m.closeTimer.observeField("fire", "onCloseTimerFired")
    if m.audioPlayer <> invalid then m.audioPlayer.observeField("state", "onAudioStateChanged")
    if m.chapterList <> invalid then
        m.chapterList.observeField("selectedChapter", "onChapterSelected")
        m.chapterList.observeField("closedCounter", "onChapterListClosed")
    end if
end sub

'-------------------------------------------------------------------------------
' initStyle
'-------------------------------------------------------------------------------
sub initStyle()
    palette = Color()
    if m.playerBg <> invalid then m.playerBg.color = palette.background.secondary
end sub

'-------------------------------------------------------------------------------
' onPlayRequestChanged
'-------------------------------------------------------------------------------
sub onPlayRequestChanged()
    request = m.top.playRequest
    if request = invalid then return

    m.isClosing = false
    if m.closeTimer <> invalid then m.closeTimer.control = "stop"
    m.audiobookTitle = SafeString(request.title, "Audiobook")
    m.requestedStartPositionSeconds = getRequestStartPosition(request)
    m.pendingTrackSeekPosition = invalid

    if m.cover <> invalid then m.cover.itemContent = getCoverContent(request)
    if m.titleLabel <> invalid then m.titleLabel.text = m.audiobookTitle
    setLabelText(m.modalTitleLabel, m.audiobookTitle)
    if m.chapterList <> invalid then m.chapterList.audiobookTitle = m.audiobookTitle
    updateDetails(request.details)
    resetProgress()
    resetSeekHold()
    closeDescriptionModal()
    closeChapterList()
    m.tracks = []
    updateChaptersButtonVisibility()
    focusTransportButton(1)
    setStatus("Starting playback...")

    m.top.playbackStartRequested = {
        action: "startPlayback"
        server: request.server
        token: request.token
        itemId: request.itemId
        title: request.title
    }
end sub

'-------------------------------------------------------------------------------
' getCoverContent
'-------------------------------------------------------------------------------
function getCoverContent(request as dynamic) as dynamic
    if request = invalid then return invalid

    node = CreateObject("roSGNode", "ContentNode")
    node.title = SafeString(request.title, "")
    node.HDPosterUrl = SafeString(request.coverUrl, "pkg:/images/placeholder_cover.png")
    node.SDPosterUrl = node.HDPosterUrl
    node.AddFields({
        posterWidth: 500
        showText: false
        showProgressBar: false
        focused: false
    })
    return node
end function

'-------------------------------------------------------------------------------
' onPlaybackResponseChanged
'-------------------------------------------------------------------------------
sub onPlaybackResponseChanged()
    response = m.top.playbackResponse
    if response = invalid then return
    if m.isClosing = true then return

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

    setLabelText(m.authorLabel, "by " + FirstNonEmpty([details.authors], "Unknown"))
    setLabelText(m.metadataLabel, getMetadataText(details))
    setLabelText(m.descriptionLabel, m.fullDescription)
    setLabelText(m.trackTitleLabel, "")

    m.totalDurationSeconds = 0
    setLabelText(m.totalTimeLabel, "0:00")
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
' getMetadataText
'-------------------------------------------------------------------------------
function getMetadataText(details as dynamic) as string
    year = getPublishedYear(details.publishDate)
    category = FirstNonEmpty([details.category], "")

    if year <> "" and category <> "" then return year + "  " + category
    if year <> "" then return year
    return category
end function

'-------------------------------------------------------------------------------
' getPublishedYear
'-------------------------------------------------------------------------------
function getPublishedYear(publishDate as dynamic) as string
    text = SafeString(publishDate, "")
    if Len(text) < 4 then return ""
    for i = 1 to Len(text) - 3
        value = Mid(text, i, 4)
        if isYearText(value) then return value
    end for

    return ""
end function

'-------------------------------------------------------------------------------
' isYearText
'-------------------------------------------------------------------------------
function isYearText(value as string) as boolean
    if Len(value) <> 4 then return false
    year = int(val(value))
    if year < 1000 or year > 9999 then return false
    return value = year.ToStr()
end function

'-------------------------------------------------------------------------------
' setLabelText
'-------------------------------------------------------------------------------
sub setLabelText(label as dynamic, text as string)
    if label <> invalid then label.text = text
end sub

'-------------------------------------------------------------------------------
' getDisplayTrackTitle
'-------------------------------------------------------------------------------
function getDisplayTrackTitle(track as dynamic, index as integer) as string
    title = SafeString(track.title, "Track " + (index + 1).ToStr())
    if LCase(TrimString(title)) = LCase(TrimString(m.audiobookTitle)) then return ""
    return title
end function

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
    applyRequestedStartPosition()
    updateChaptersButtonVisibility()
    updateChapterList()
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

    m.totalDurationSeconds = getTrackDurationSeconds(track)
    m.currentTrackStartPosition = getTrackStartPosition(track)
    setLabelText(m.trackTitleLabel, getDisplayTrackTitle(track, m.currentTrackIndex))
    if m.totalDurationSeconds > 0 then
        setLabelText(m.totalTimeLabel, formatPlaybackTime(m.totalDurationSeconds))
    else
        setLabelText(m.totalTimeLabel, "0:00")
    end if
    resetProgress()
    updateChapterList()

    m.audioPlayer.content = node
    m.isPaused = false
    disableScreenSaver()
    m.audioPlayer.control = "play"
    seekPosition = getInitialTrackSeekPosition()
    if seekPosition > 0 then m.audioPlayer.seek = seekPosition
    m.pendingTrackSeekPosition = invalid
    setStatus("Playing")
    updatePlayPauseButton()
end sub

'-------------------------------------------------------------------------------
' getRequestStartPosition
'-------------------------------------------------------------------------------
function getRequestStartPosition(request as dynamic) as integer
    if request = invalid or request.startPositionSeconds = invalid then return 0
    startPosition = int(val(request.startPositionSeconds.ToStr()))
    if startPosition < 0 then return 0
    return startPosition
end function

'-------------------------------------------------------------------------------
' applyRequestedStartPosition
'-------------------------------------------------------------------------------
sub applyRequestedStartPosition()
    m.currentTrackIndex = 0
    m.pendingTrackSeekPosition = invalid
    if m.requestedStartPositionSeconds <= 0 then return
    if m.tracks = invalid or m.tracks.Count() = 0 then return

    if tracksHaveStartPositions() then
        applySharedStreamStartPosition()
    else
        applyFileTrackStartPosition()
    end if
end sub

'-------------------------------------------------------------------------------
' tracksHaveStartPositions
'-------------------------------------------------------------------------------
function tracksHaveStartPositions() as boolean
    if m.tracks = invalid then return false

    for each track in m.tracks
        if track <> invalid and track.startPositionSeconds <> invalid then return true
    end for

    return false
end function

'-------------------------------------------------------------------------------
' applySharedStreamStartPosition
'-------------------------------------------------------------------------------
sub applySharedStreamStartPosition()
    lastMatchingIndex = 0

    for i = 0 to m.tracks.Count() - 1
        track = m.tracks[i]
        trackStart = getTrackStartPosition(track)
        trackDuration = getTrackDurationSeconds(track)
        trackEnd = trackStart + trackDuration

        if m.requestedStartPositionSeconds >= trackStart then
            lastMatchingIndex = i
            if trackDuration <= 0 or m.requestedStartPositionSeconds < trackEnd then
                m.currentTrackIndex = i
                m.pendingTrackSeekPosition = m.requestedStartPositionSeconds
                return
            end if
        end if
    end for

    m.currentTrackIndex = lastMatchingIndex
    m.pendingTrackSeekPosition = m.requestedStartPositionSeconds
end sub

'-------------------------------------------------------------------------------
' applyFileTrackStartPosition
'-------------------------------------------------------------------------------
sub applyFileTrackStartPosition()
    elapsedSeconds = 0

    for i = 0 to m.tracks.Count() - 1
        track = m.tracks[i]
        trackDuration = getTrackDurationSeconds(track)

        if trackDuration <= 0 or m.requestedStartPositionSeconds < elapsedSeconds + trackDuration then
            m.currentTrackIndex = i
            m.pendingTrackSeekPosition = m.requestedStartPositionSeconds - elapsedSeconds
            if m.pendingTrackSeekPosition < 0 then m.pendingTrackSeekPosition = 0
            return
        end if

        elapsedSeconds = elapsedSeconds + trackDuration
    end for

    m.currentTrackIndex = m.tracks.Count() - 1
    m.pendingTrackSeekPosition = getTrackDurationSeconds(m.tracks[m.currentTrackIndex])
end sub

'-------------------------------------------------------------------------------
' getInitialTrackSeekPosition
'-------------------------------------------------------------------------------
function getInitialTrackSeekPosition() as integer
    if m.pendingTrackSeekPosition <> invalid then return int(val(m.pendingTrackSeekPosition.ToStr()))
    return m.currentTrackStartPosition
end function

'-------------------------------------------------------------------------------
' getTrackDurationSeconds
'-------------------------------------------------------------------------------
function getTrackDurationSeconds(track as dynamic) as integer
    if track = invalid then return 0
    if track.durationSeconds = invalid then return 0
    return int(val(track.durationSeconds.ToStr()))
end function

'-------------------------------------------------------------------------------
' getTrackStartPosition
'-------------------------------------------------------------------------------
function getTrackStartPosition(track as dynamic) as integer
    if track = invalid then return 0
    if track.startPositionSeconds = invalid then return 0
    return int(val(track.startPositionSeconds.ToStr()))
end function

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
        m.ignoreNextFinished = false
        m.isPaused = false
        disableScreenSaver()
        setStatus("Playing")
        startProgressTimer()
        updatePlayPauseButton()
    else if state = "buffering" then
        disableScreenSaver()
        setStatus("Buffering...")
        startProgressTimer()
    else if state = "finished" then
        if m.ignoreNextFinished = true then
            m.ignoreNextFinished = false
            stopProgressTimer()
            return
        end if

        if playNextTrack() then
            return
        end if
        stopProgressTimer()
        enableScreenSaver()
        updateProgress(m.totalDurationSeconds)
        setStatus("Finished")
        m.isPaused = false
        updatePlayPauseButton()
    else if state = "error" then
        stopProgressTimer()
        enableScreenSaver()
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
' disableScreenSaver
'-------------------------------------------------------------------------------
sub disableScreenSaver()
    if m.audioPlayer <> invalid then m.audioPlayer.disableScreenSaver = true
end sub

'-------------------------------------------------------------------------------
' enableScreenSaver
'-------------------------------------------------------------------------------
sub enableScreenSaver()
    if m.audioPlayer <> invalid then m.audioPlayer.disableScreenSaver = false
end sub

'-------------------------------------------------------------------------------
' closePlayer
'-------------------------------------------------------------------------------
sub closePlayer()
    if m.isClosing = true then return
    m.isClosing = true

    resetSeekHold()
    stopProgressTimer()
    enableScreenSaver()
    closeDescriptionModal()
    closeChapterList()
    setStatus("Stopping...")

    if m.audioPlayer <> invalid then m.audioPlayer.control = "stop"

    if m.closeTimer <> invalid then
        m.closeTimer.control = "start"
    else
        finalizeClosePlayer()
    end if
end sub

'-------------------------------------------------------------------------------
' onCloseTimerFired
'-------------------------------------------------------------------------------
sub onCloseTimerFired()
    finalizeClosePlayer()
end sub

'-------------------------------------------------------------------------------
' finalizeClosePlayer
'-------------------------------------------------------------------------------
sub finalizeClosePlayer()
    if m.audioPlayer <> invalid then
        m.audioPlayer.control = "stop"
        m.audioPlayer.content = invalid
    end if

    m.tracks = []
    m.currentTrackIndex = 0
    m.currentTrackStartPosition = 0
    m.pendingTrackSeekPosition = invalid
    m.isPaused = false
    resetProgress()
    updateChaptersButtonVisibility()
    m.closeRequestedCounter = m.closeRequestedCounter + 1
    m.top.closeRequested = m.closeRequestedCounter
end sub

'-------------------------------------------------------------------------------
' onKeyEvent
'-------------------------------------------------------------------------------
function onKeyEvent(key as string, press as boolean) as boolean
    if press = false then
        if key = "OK" or key = "select" then
            if m.seekHoldDirection <> 0 then
                finishTransportSeekHold()
                return true
            end if
        end if

        return false
    end if

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
            if m.descriptionIsExpandable then
                updateTransportFocus(-1)
                updateDescriptionFocus(true)
            else
                updateTransportFocus(-1)
            end if
            return true
        else if key = "down" then
            return true
        else if key = "OK" or key = "select" then
            if m.seekHoldDirection <> 0 then return true

            if m.transportFocusIndex = 0 then
                beginTransportSeekHold(-1)
            else if m.transportFocusIndex = 2 then
                beginTransportSeekHold(1)
            else if m.transportFocusIndex = 3 then
                openChapterList()
            else
                activateTransportButton()
            end if
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
    transportButtonCount = getTransportButtonCount()
    if index >= transportButtonCount then index = transportButtonCount - 1
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
    transportButtonCount = getTransportButtonCount()
    if index >= transportButtonCount then m.transportFocusIndex = transportButtonCount - 1

    for i = 0 to m.transportButtons.Count() - 1
        button = m.transportButtons[i]
        if button <> invalid then button.hasFocusVisual = (i = m.transportFocusIndex and i < transportButtonCount)
    end for
end sub

'-------------------------------------------------------------------------------
' getTransportButtonCount
'-------------------------------------------------------------------------------
function getTransportButtonCount() as integer
    if m.chaptersButton <> invalid and m.chaptersButton.visible = true then return 4
    return 3
end function

'-------------------------------------------------------------------------------
' activateTransportButton
'-------------------------------------------------------------------------------
sub activateTransportButton()
    if m.transportFocusIndex = 0 then
        beginTransportSeekHold(-1)
    else if m.transportFocusIndex = 1 then
        togglePlayPause()
    else if m.transportFocusIndex = 2 then
        beginTransportSeekHold(1)
    else if m.transportFocusIndex = 3 then
        openChapterList()
    end if
end sub

'-------------------------------------------------------------------------------
' updateChaptersButtonVisibility
'-------------------------------------------------------------------------------
sub updateChaptersButtonVisibility()
    hasMultipleTracks = (m.tracks <> invalid and m.tracks.Count() > 1)
    if m.chaptersButton <> invalid then
        m.chaptersButton.visible = hasMultipleTracks
        if hasMultipleTracks = false then m.chaptersButton.hasFocusVisual = false
    end if

    if hasMultipleTracks = false and m.transportFocusIndex > 2 then updateTransportFocus(2)
end sub

'-------------------------------------------------------------------------------
' openChapterList
'-------------------------------------------------------------------------------
sub openChapterList()
    if m.chapterList = invalid then return
    if m.tracks = invalid or m.tracks.Count() <= 1 then return

    updateChapterList()
    m.chapterList.callFunc("open")
end sub

'-------------------------------------------------------------------------------
' closeChapterList
'-------------------------------------------------------------------------------
sub closeChapterList()
    if m.chapterList <> invalid then m.chapterList.callFunc("close")
end sub

'-------------------------------------------------------------------------------
' updateChapterList
'-------------------------------------------------------------------------------
sub updateChapterList()
    if m.chapterList = invalid then return

    m.chapterList.tracks = m.tracks
    m.chapterList.currentTrackIndex = m.currentTrackIndex
    m.chapterList.audiobookTitle = m.audiobookTitle
end sub

'-------------------------------------------------------------------------------
' onChapterListClosed
'-------------------------------------------------------------------------------
sub onChapterListClosed()
    focusChaptersButton()
end sub

'-------------------------------------------------------------------------------
' focusChaptersButton
'-------------------------------------------------------------------------------
sub focusChaptersButton()
    if m.chaptersButton <> invalid and m.chaptersButton.visible = true then
        m.chaptersButton.setFocus(true)
        updateTransportFocus(3)
    end if
end sub

'-------------------------------------------------------------------------------
' onChapterSelected
'-------------------------------------------------------------------------------
sub onChapterSelected()
    if m.chapterList = invalid then return

    selection = m.chapterList.selectedChapter
    if selection = invalid or selection.index = invalid then return

    index = selection.index
    if m.tracks = invalid then return
    if index < 0 or index >= m.tracks.Count() then return

    focusChaptersButton()
    if index = m.currentTrackIndex then return

    resetSeekHold()
    stopProgressTimer()
    if selectedChapterUsesCurrentStream(index) then
        playChapterInCurrentStream(index)
    else
        m.ignoreNextFinished = true
        m.currentTrackIndex = index
        playCurrentTrack()
    end if
end sub

'-------------------------------------------------------------------------------
' selectedChapterUsesCurrentStream
'-------------------------------------------------------------------------------
function selectedChapterUsesCurrentStream(index as integer) as boolean
    if m.tracks = invalid then return false
    if m.currentTrackIndex < 0 or m.currentTrackIndex >= m.tracks.Count() then return false
    if index < 0 or index >= m.tracks.Count() then return false

    currentTrack = m.tracks[m.currentTrackIndex]
    selectedTrack = m.tracks[index]
    if currentTrack = invalid or selectedTrack = invalid then return false

    return SafeString(currentTrack.url, "") = SafeString(selectedTrack.url, "")
end function

'-------------------------------------------------------------------------------
' playChapterInCurrentStream
'-------------------------------------------------------------------------------
sub playChapterInCurrentStream(index as integer)
    m.currentTrackIndex = index
    track = m.tracks[index]

    m.totalDurationSeconds = getTrackDurationSeconds(track)
    m.currentTrackStartPosition = getTrackStartPosition(track)
    setLabelText(m.trackTitleLabel, getDisplayTrackTitle(track, index))
    if m.totalDurationSeconds > 0 then
        setLabelText(m.totalTimeLabel, formatPlaybackTime(m.totalDurationSeconds))
    else
        setLabelText(m.totalTimeLabel, "0:00")
    end if
    resetProgress()
    updateChapterList()

    if m.audioPlayer <> invalid then
        ? "chapter seek"; " index="; index; " start="; m.currentTrackStartPosition; " state="; SafeString(m.audioPlayer.state, "")
        m.audioPlayer.seek = m.currentTrackStartPosition
        if m.audioPlayer.state = "paused" then
            m.audioPlayer.control = "resume"
        else if m.audioPlayer.state <> "playing" then
            m.audioPlayer.control = "play"
        end if
    end if

    m.isPaused = false
    startProgressTimer()
    setStatus("Playing")
    updatePlayPauseButton()
end sub

'-------------------------------------------------------------------------------
' beginTransportSeekHold
'-------------------------------------------------------------------------------
sub beginTransportSeekHold(direction as integer)
    if m.audioPlayer = invalid then return
    if direction = 0 then return

    m.seekHoldDirection = direction
    m.seekHoldTally = 1
    m.seekHoldSeconds = 0
    m.seekHoldStartPosition = getCurrentTrackPlaybackPosition()

    stopProgressTimer()
    if m.seekHoldTimer <> invalid then m.seekHoldTimer.control = "start"
    updateSeekHoldPreview()
end sub

'-------------------------------------------------------------------------------
' onSeekHoldTimerFired
'-------------------------------------------------------------------------------
sub onSeekHoldTimerFired()
    if m.seekHoldDirection = 0 then
        if m.seekHoldTimer <> invalid then m.seekHoldTimer.control = "stop"
        return
    end if

    m.seekHoldSeconds = m.seekHoldSeconds + 1
    if m.seekHoldSeconds > 5 then
        m.seekHoldTally = m.seekHoldTally + 2
    else
        m.seekHoldTally = m.seekHoldTally + 1
    end if
    updateSeekHoldPreview()
end sub

'-------------------------------------------------------------------------------
' updateSeekHoldPreview
'-------------------------------------------------------------------------------
sub updateSeekHoldPreview()
    targetPosition = getSeekHoldTargetPosition()
    updateProgress(targetPosition)

    offsetSeconds = m.seekHoldDirection * m.seekHoldTally * 30
    if offsetSeconds > 0 then
        setStatus("Seek +" + formatPlaybackTime(offsetSeconds))
    else
        setStatus("Seek -" + formatPlaybackTime(Abs(offsetSeconds)))
    end if
end sub

'-------------------------------------------------------------------------------
' finishTransportSeekHold
'-------------------------------------------------------------------------------
sub finishTransportSeekHold()
    if m.seekHoldDirection = 0 then return

    targetPosition = getSeekHoldTargetPosition()
    resetSeekHold()

    if m.audioPlayer <> invalid then
        m.audioPlayer.seek = m.currentTrackStartPosition + targetPosition
    end if

    updateProgress(targetPosition)
    if m.isPaused = true then
        setStatus("Paused")
    else
        setStatus("Playing")
        startProgressTimer()
    end if
end sub

'-------------------------------------------------------------------------------
' resetSeekHold
'-------------------------------------------------------------------------------
sub resetSeekHold()
    if m.seekHoldTimer <> invalid then m.seekHoldTimer.control = "stop"
    m.seekHoldDirection = 0
    m.seekHoldTally = 0
    m.seekHoldSeconds = 0
    m.seekHoldStartPosition = 0
end sub

'-------------------------------------------------------------------------------
' getSeekHoldTargetPosition
'-------------------------------------------------------------------------------
function getSeekHoldTargetPosition() as integer
    targetPosition = m.seekHoldStartPosition + (m.seekHoldDirection * m.seekHoldTally * 30)
    if targetPosition < 0 then targetPosition = 0
    if m.totalDurationSeconds > 0 and targetPosition > m.totalDurationSeconds then targetPosition = m.totalDurationSeconds
    return targetPosition
end function

'-------------------------------------------------------------------------------
' togglePlayPause
'-------------------------------------------------------------------------------
sub togglePlayPause()
    if m.audioPlayer = invalid then return

    if m.isPaused <> true and m.audioPlayer.state = "playing" then
        m.audioPlayer.control = "pause"
        m.isPaused = true
        stopProgressTimer()
        enableScreenSaver()
        updateProgress(getCurrentTrackPlaybackPosition())
        setStatus("Paused")
    else
        m.isPaused = false
        disableScreenSaver()
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
        m.playPauseButton.iconUri = "pkg:/images/icons/dark/play_dark.png"
    else
        m.playPauseButton.text = "Pause"
        m.playPauseButton.iconUri = "pkg:/images/icons/dark/pause_dark.png"
    end if
end sub

'-------------------------------------------------------------------------------
' seekRelative
'-------------------------------------------------------------------------------
sub seekRelative(offsetSeconds as integer)
    if m.audioPlayer = invalid then return

    nextPosition = getCurrentTrackPlaybackPosition() + offsetSeconds
    if nextPosition < 0 then nextPosition = 0
    if m.totalDurationSeconds > 0 and nextPosition > m.totalDurationSeconds then nextPosition = m.totalDurationSeconds

    m.audioPlayer.seek = m.currentTrackStartPosition + nextPosition
    updateProgress(nextPosition)
end sub

'-------------------------------------------------------------------------------
' updateDescriptionFocus
'-------------------------------------------------------------------------------
sub updateDescriptionFocus(hasFocus as boolean)
    m.descriptionHasFocus = hasFocus and m.descriptionIsExpandable
    if m.descriptionFocusRing = invalid then return

    if m.descriptionHasFocus then
        m.descriptionFocusRing.color = Color().background.primary
    else
        m.descriptionFocusRing.color = &h29283600
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
    if m.descriptionModal <> invalid then m.descriptionModal.setFocus(true)
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
    if m.seekHoldDirection <> 0 then return
    position = getCurrentPlaybackPosition() - m.currentTrackStartPosition
    updateProgress(position)
    if shouldAdvanceSharedStreamChapter(position) then
        playNextTrack()
    end if
end sub

'-------------------------------------------------------------------------------
' getCurrentPlaybackPosition
'-------------------------------------------------------------------------------
function getCurrentPlaybackPosition() as integer
    if m.audioPlayer = invalid or m.audioPlayer.position = invalid then return 0
    return int(val(m.audioPlayer.position.ToStr()))
end function

'-------------------------------------------------------------------------------
' getCurrentTrackPlaybackPosition
'-------------------------------------------------------------------------------
function getCurrentTrackPlaybackPosition() as integer
    position = getCurrentPlaybackPosition() - m.currentTrackStartPosition
    if position < 0 then position = 0
    return position
end function

'-------------------------------------------------------------------------------
' shouldAdvanceSharedStreamChapter
'-------------------------------------------------------------------------------
function shouldAdvanceSharedStreamChapter(positionSeconds as integer) as boolean
    if m.totalDurationSeconds <= 0 then return false
    if positionSeconds < m.totalDurationSeconds then return false
    if m.tracks = invalid then return false
    if m.currentTrackIndex < 0 or m.currentTrackIndex >= m.tracks.Count() then return false

    track = m.tracks[m.currentTrackIndex]
    return getTrackStartPosition(track) > 0 or hasSharedTrackUrl(m.currentTrackIndex)
end function

'-------------------------------------------------------------------------------
' hasSharedTrackUrl
'-------------------------------------------------------------------------------
function hasSharedTrackUrl(index as integer) as boolean
    if m.tracks = invalid then return false
    if index < 0 or index >= m.tracks.Count() then return false

    track = m.tracks[index]
    if track = invalid then return false

    trackUrl = SafeString(track.url, "")
    for i = 0 to m.tracks.Count() - 1
        if i <> index then
            otherTrack = m.tracks[i]
            if otherTrack <> invalid and SafeString(otherTrack.url, "") = trackUrl then return true
        end if
    end for

    return false
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
    if m.seekHoldDirection <> 0 then return
    if m.progressTimer <> invalid then m.progressTimer.control = "start"
    updateProgress(getCurrentTrackPlaybackPosition())
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
