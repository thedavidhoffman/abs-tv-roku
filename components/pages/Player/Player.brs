'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    initReferences()
    initValues()
    initHandlers()
    initStyle()
    styleProgressBar()
    updateChaptersButtonVisibility()
    updateTransportFocus(-1)
    updatePlayPauseButton()
end sub

'-------------------------------------------------------------------------------
' initReferences
'-------------------------------------------------------------------------------
sub initReferences()
    m.log = CreateLogger("Player", false)
    m.playerBg = m.top.findNode("playerBg")
    m.cover = m.top.findNode("cover")
    m.titleLabel = m.top.findNode("titleLabel")
    m.authorLabel = m.top.findNode("authorLabel")
    m.metadataLabel = m.top.findNode("metadataLabel")
    m.descriptionLabel = m.top.findNode("description")
    m.trackTitleLabel = m.top.findNode("trackTitleLabel")
    m.statusLabel = m.top.findNode("statusLabel")
    m.chapterStatusLabel = m.top.findNode("chapterStatusLabel")
    m.progressGroup = m.top.findNode("progressGroup")
    m.progressFill = m.top.findNode("progressFill")
    m.progressTrack = m.top.findNode("progressTrack")
    m.chapterMarkersGroup = m.top.findNode("chapterMarkersGroup")
    m.progressCrossbar = m.top.findNode("progressCrossbar")
    m.currentTimeLabel = m.top.findNode("currentTimeLabel")
    m.totalTimeLabel = m.top.findNode("totalTimeLabel")
    m.progressTimer = m.top.findNode("progressTimer")
    m.closeTimer = m.top.findNode("closeTimer")
    m.hlsRetryTimer = m.top.findNode("hlsRetryTimer")
    m.playPauseButton = m.top.findNode("playPauseButton")
    m.restartButton = m.top.findNode("restartButton")
    m.tintButton = m.top.findNode("tintButton")
    m.chaptersButton = m.top.findNode("chaptersButton")
    m.nightModeTint = m.top.findNode("nightModeTint")
    m.chapterList = m.top.findNode("chapterList")
    m.audioPlayer = m.top.findNode("audioPlayer")
    m.playbackApiTask = m.top.findNode("playbackApiTask")
end sub

'-------------------------------------------------------------------------------
' initValues
'-------------------------------------------------------------------------------
sub initValues()
    m.closeRequestedCounter = 0
    m.audiobookTitle = "Audiobook"
    m.tracks = []
    m.chapterItems = []
    m.currentTrackIndex = 0
    m.currentTrackStartPosition = 0
    m.currentTimeSeconds = 0
    m.requestedStartPositionSeconds = 0
    m.pendingSeekSeconds = invalid
    m.playbackServer = invalid
    m.playbackToken = invalid
    m.playbackSession = invalid
    m.playbackSessionId = invalid
    m.playbackRequestCounter = 0
    m.activeStartRequestCounter = 0
    m.isHlsTranscode = false
    m.hlsRetryCount = 0
    m.hlsRetryMax = 3
    m.hlsResumeRetryMax = 8
    m.hlsRetryPending = false
    m.hlsStartupSeekTargetSeconds = invalid
    m.playbackVisualTargetSeconds = invalid
    m.hlsSessionRefreshTried = false
    m.forceTranscodeFallbackTried = false
    m.hasStartedPlayback = false
    m.visiblePlaybackStatus = ""
    m.startTimeOverrideSeconds = invalid
    m.playbackStartedAtSeconds = 0
    m.lastPlaybackSyncAtSeconds = 0
    m.lastProgressTickAtSeconds = 0
    m.lastSyncedCurrentTimeSeconds = 0
    m.listeningTimeSinceSync = 0
    m.firstPlaybackSyncIntervalSeconds = 20
    m.playbackSyncIntervalSeconds = 10
    m.closeProgressSaveThresholdSeconds = 20
    m.isPaused = false
    m.totalDurationSeconds = 0
    m.progressBarWidth = 1040
    m.progressTimeLabelY = 26
    m.progressTotalTimeLabelX = 820
    m.playPauseButtonX = 0
    m.restartButtonX = 208
    m.tintButtonX = 416
    m.chaptersButtonX = 850
    m.transportButtonY = 0
    m.progressCrossbarWidth = 8
    m.progressCrossbarY = -10
    m.chapterMarkerWidth = 2
    m.chapterMarkerTop = 13
    m.chapterMarkerBottom = 22
    m.chapterMarkerColor = &hF3F7FB80
    m.isProgressScrubbing = false
    m.progressScrubTargetSeconds = 0
    m.progressScrubReturnFocusIndex = 0
    m.chapterMarkerHeight = m.chapterMarkerBottom - m.chapterMarkerTop
    m.hasChapterMarkers = false
    m.transportFocusIndex = -1
    m.deferChapterStatusUpdates = false
    m.pendingChapterStatusUpdate = false
    m.transportButtons = [
        m.playPauseButton
        m.restartButton
        m.tintButton
        m.chaptersButton
    ]
    m.isClosing = false
end sub

'-------------------------------------------------------------------------------
' initHandlers
'-------------------------------------------------------------------------------
sub initHandlers()
    if m.progressTimer <> invalid then m.progressTimer.observeField("fire", "onProgressTimerFired")
    if m.closeTimer <> invalid then m.closeTimer.observeField("fire", "onCloseTimerFired")
    if m.hlsRetryTimer <> invalid then m.hlsRetryTimer.observeField("fire", "onHlsRetryTimerFired")
    if m.audioPlayer <> invalid then m.audioPlayer.observeField("state", "onAudioStateChanged")
    if m.playbackApiTask <> invalid then m.playbackApiTask.observeField("response", "onPlaybackApiResponse")
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

    m.log.write("onPlayRequestChanged")

    request = m.top.playRequest

    if request = invalid then 
        m.log.write("invalid request")
        return
    end if

    m.log.write("title = " + SafeString(request.title))
    m.log.write("itemId = " + SafeString(request.itemId))
    m.log.write("startPosition = " + SafeString(request.startPositionSeconds))

    m.isClosing = false
    if m.closeTimer <> invalid then m.closeTimer.control = "stop"
    resetMediaNodeForNewPlayback()

    m.playbackServer = request.server
    m.playbackToken = request.token
    resetPlaybackSessionState()
    resetPlaybackRetryState(true)
    resetPlaybackSyncState()
    m.audiobookTitle = SafeString(request.title, "Audiobook")
    m.requestedStartPositionSeconds = getRequestStartPosition(request)
    m.currentTimeSeconds = m.requestedStartPositionSeconds

    if m.cover <> invalid then m.cover.itemContent = getCoverContent(request)
    if m.titleLabel <> invalid then m.titleLabel.text = m.audiobookTitle
    if m.descriptionLabel <> invalid then m.descriptionLabel.title = m.audiobookTitle
    if m.chapterList <> invalid then m.chapterList.audiobookTitle = m.audiobookTitle
    updateDetails(request.details)
    resetProgress()
    closeChapterList()
    hideNightModeTint()
    updateChaptersButtonVisibility()
    focusTransportButton(0)
    setStatus("Starting playback...")

    requestStartPlaybackSession(false)
end sub

'-------------------------------------------------------------------------------
' requestStartPlaybackSession
'-------------------------------------------------------------------------------
sub requestStartPlaybackSession(forceTranscode = false as boolean, startTimeOverride = invalid as dynamic)
    request = m.top.playRequest
    if request = invalid then return

    m.startTimeOverrideSeconds = startTimeOverride
    m.playbackRequestCounter = m.playbackRequestCounter + 1
    m.activeStartRequestCounter = m.playbackRequestCounter
    runPlaybackApiRequest({
        action: "startPlayback"
        server: request.server
        token: request.token
        itemId: request.itemId
        title: request.title
        forceDirectPlay: false
        forceTranscode: forceTranscode
        requestCounter: m.activeStartRequestCounter
    })
end sub

'-------------------------------------------------------------------------------
' resetMediaNodeForNewPlayback
'-------------------------------------------------------------------------------
sub resetMediaNodeForNewPlayback()
    stopProgressTimer()
    cancelProgressScrub()
    if m.hlsRetryTimer <> invalid then m.hlsRetryTimer.control = "stop"
    if m.audioPlayer <> invalid then
        m.audioPlayer.control = "stop"
        m.audioPlayer.content = invalid
    end if
end sub

'-------------------------------------------------------------------------------
' resetPlaybackSessionState
'-------------------------------------------------------------------------------
sub resetPlaybackSessionState()
    m.tracks = []
    m.chapterItems = []
    m.currentTrackIndex = 0
    m.currentTrackStartPosition = 0
    m.pendingSeekSeconds = invalid
    m.playbackSession = invalid
    m.playbackSessionId = invalid
    m.isHlsTranscode = false
    m.hlsStartupSeekTargetSeconds = invalid
    m.playbackVisualTargetSeconds = invalid
    m.hasStartedPlayback = false
    updateChapterMarkers()
    updateCurrentChapterStatus()
end sub

'-------------------------------------------------------------------------------
' resetPlaybackRetryState
'-------------------------------------------------------------------------------
sub resetPlaybackRetryState(resetFallbackAttempts = false as boolean)
    m.hlsRetryCount = 0
    m.hlsRetryPending = false
    m.hasStartedPlayback = false
    m.visiblePlaybackStatus = ""
    m.startTimeOverrideSeconds = invalid
    m.isPaused = false

    if resetFallbackAttempts = true then
        m.hlsSessionRefreshTried = false
        m.forceTranscodeFallbackTried = false
    end if
end sub

'-------------------------------------------------------------------------------
' resetPlaybackSyncState
'-------------------------------------------------------------------------------
sub resetPlaybackSyncState()
    m.playbackStartedAtSeconds = 0
    m.lastPlaybackSyncAtSeconds = 0
    m.lastProgressTickAtSeconds = 0
    m.lastSyncedCurrentTimeSeconds = 0
    m.listeningTimeSinceSync = 0
end sub

'-------------------------------------------------------------------------------
' startPlaybackSyncState
'-------------------------------------------------------------------------------
sub startPlaybackSyncState()
    m.playbackStartedAtSeconds = getNowSeconds()
    m.lastPlaybackSyncAtSeconds = m.playbackStartedAtSeconds
    m.lastProgressTickAtSeconds = 0
    m.lastSyncedCurrentTimeSeconds = 0
    m.listeningTimeSinceSync = 0
end sub

'-------------------------------------------------------------------------------
' runPlaybackApiRequest
'-------------------------------------------------------------------------------
sub runPlaybackApiRequest(request as object)
    if m.playbackApiTask = invalid then return

    m.playbackApiTask.request = request
    m.playbackApiTask.control = "run"
end sub

'-------------------------------------------------------------------------------
' onPlaybackApiResponse
'-------------------------------------------------------------------------------
sub onPlaybackApiResponse()
    response = m.playbackApiTask.response
    if response = invalid then return

    action = getTaskResponseAction(response)
    if action = "startPlayback" then
        if response.requestCounter <> invalid and response.requestCounter <> m.activeStartRequestCounter then return
        handleStartPlaybackResponse(response)
    else if action = "closePlaybackSession" then
        handleClosePlaybackSessionResponse(response)
    else if response.ok <> true then
        m.top.errorResponse = response
    end if
end sub

'-------------------------------------------------------------------------------
' handleClosePlaybackSessionResponse
'-------------------------------------------------------------------------------
sub handleClosePlaybackSessionResponse(response as dynamic)
    if response <> invalid and response.ok <> true then m.top.errorResponse = response
end sub

'-------------------------------------------------------------------------------
' getTaskResponseAction
'-------------------------------------------------------------------------------
function getTaskResponseAction(response as dynamic) as string
    if response <> invalid and response.action <> invalid then return response.action
    if m.playbackApiTask <> invalid and m.playbackApiTask.request <> invalid and m.playbackApiTask.request.action <> invalid then
        return m.playbackApiTask.request.action
    end if

    return ""
end function

'-------------------------------------------------------------------------------
' getCoverContent
'-------------------------------------------------------------------------------
function getCoverContent(request as dynamic) as dynamic

    ' ItemPlayer accepts a ContentNode (aka property bag)
    ' for the cover information (url, title, etc.)

    if request = invalid then return invalid

    node = CreateObject("roSGNode", "ContentNode")
    node.title = SafeString(request.title, "")
    node.HDPosterUrl = SafeString(request.coverUrl, "pkg:/images/placeholder-cover.png")
    node.SDPosterUrl = node.HDPosterUrl
    node.AddFields({
        focused: false
    })
    return node

end function

'-------------------------------------------------------------------------------
' handleStartPlaybackResponse
'-------------------------------------------------------------------------------
sub handleStartPlaybackResponse(response as dynamic)

    m.log.write("handleStartPlaybackResponse")

    if response = invalid then return
    if m.isClosing = true then return

    if response.ok <> true then
        m.top.errorResponse = response
        setStatus(SafeString(response.errorMessage, "Unable to start playback."))
        return
    end if

    m.playbackSession = response.playbackSession
    m.playbackSessionId = getPlaybackSessionId(response.playbackSession)
    if response.playbackSessionId <> invalid then m.playbackSessionId = response.playbackSessionId
    m.isHlsTranscode = response.isHlsTranscode = true
    m.currentTimeSeconds = getStartPlaybackCurrentTime(response)
    if m.isHlsTranscode = true then m.log.write("HLS stream global start offset=0")
    m.totalDurationSeconds = getStartPlaybackDuration(response)
    startPlaybackSyncState()
    playTracks(response.tracks, response.chapters)
end sub

'-------------------------------------------------------------------------------
' getStartPlaybackCurrentTime
'-------------------------------------------------------------------------------
function getStartPlaybackCurrentTime(response as dynamic) as integer
    if m.startTimeOverrideSeconds <> invalid then
        return clampStartPlaybackTime(m.startTimeOverrideSeconds)
    end if

    return m.requestedStartPositionSeconds
end function

'-------------------------------------------------------------------------------
' clampStartPlaybackTime
'-------------------------------------------------------------------------------
function clampStartPlaybackTime(timeSeconds as dynamic) as integer
    startTime = int(val(timeSeconds.ToStr()))
    if startTime < 0 then return 0
    return startTime
end function

'-------------------------------------------------------------------------------
' getStartPlaybackDuration
'-------------------------------------------------------------------------------
function getStartPlaybackDuration(response as dynamic) as integer
    if response <> invalid and response.duration <> invalid then return int(val(response.duration.ToStr()))
    if response <> invalid and response.playbackSession <> invalid and response.playbackSession.duration <> invalid then return int(val(response.playbackSession.duration.ToStr()))
    return 0
end function

'-------------------------------------------------------------------------------
' getPlaybackSessionId
'-------------------------------------------------------------------------------
function getPlaybackSessionId(playbackSession as dynamic) as dynamic
    if playbackSession = invalid then return invalid
    return playbackSession.id
end function

'-------------------------------------------------------------------------------
' updateDetails
'-------------------------------------------------------------------------------
sub updateDetails(details as dynamic)
    if details = invalid then details = {}

    description = FirstNonEmpty([details.description], "No description available.")

    setLabelText(m.authorLabel, "by " + FirstNonEmpty([details.authors], "Unknown"))
    setLabelText(m.metadataLabel, getMetadataText(details))
    setLabelText(m.descriptionLabel, description)
    setLabelText(m.trackTitleLabel, "")

    m.totalDurationSeconds = 0
    setLabelText(m.totalTimeLabel, "0:00")
    updateChapterMarkers()
end sub

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
' playTracks
'-------------------------------------------------------------------------------
sub playTracks(tracks as dynamic, chapters as dynamic)

    m.log.write("playTracks")

    if m.audioPlayer = invalid then return
    if tracks = invalid or tracks.Count() = 0 then
        setStatus("No playable audio tracks were returned.")
        return
    end if

    m.tracks = tracks
    m.chapterItems = getChapterItems(chapters, tracks)
    m.currentTimeSeconds = clampGlobalTime(m.currentTimeSeconds)
    m.currentTrackIndex = getTrackIndexForGlobalTime(m.currentTimeSeconds)
    m.pendingSeekSeconds = getTrackSeekPosition(m.currentTrackIndex, m.currentTimeSeconds)
    updateChaptersButtonVisibility()
    updateChapterMarkers()
    updateChapterList()
    updateCurrentChapterStatus()
    playCurrentTrack()
end sub

'-------------------------------------------------------------------------------
' playCurrentTrack
'-------------------------------------------------------------------------------
sub playCurrentTrack(playWhenReady = true as boolean)

    m.log.write("playCurrentTrack")

    if m.audioPlayer = invalid then return
    if m.tracks = invalid or m.currentTrackIndex < 0 or m.currentTrackIndex >= m.tracks.Count() then return

    track = m.tracks[m.currentTrackIndex]
    node = CreateObject("roSGNode", "ContentNode")
    node.url = getTrackPlaybackUrl(track)
    node.title = SafeString(track.title, "Audiobook")
    node.streamFormat = getStreamFormat(track.mimeType, track.url)
    node.contentType = "audio"
    seekPosition = getInitialTrackSeekPosition()
    if seekPosition > 0 then
        if m.isHlsTranscode = true then
            node.PlayStart = seekPosition
            m.pendingSeekSeconds = invalid
            m.hlsStartupSeekTargetSeconds = seekPosition
            m.log.write("HLS initial PlayStart=" + seekPosition.ToStr())
        else
            node.PlayStart = seekPosition
            m.pendingSeekSeconds = invalid
        end if
    else
        m.pendingSeekSeconds = invalid
        if m.isHlsTranscode = true then m.hlsStartupSeekTargetSeconds = invalid
    end if

    m.log.write("track index=" + m.currentTrackIndex.ToStr() + " format=" + SafeString(node.streamFormat) + " url=" + SafeString(node.url))

    m.currentTrackStartPosition = getTrackStartPosition(track)
    if m.currentTimeSeconds > 0 then
        setPlaybackVisualTarget(m.currentTimeSeconds)
    else
        m.playbackVisualTargetSeconds = invalid
    end if

    if m.totalDurationSeconds > 0 then
        setLabelText(m.totalTimeLabel, formatPlaybackTime(m.totalDurationSeconds))
    else
        setLabelText(m.totalTimeLabel, "0:00")
    end if
    updateProgress(m.currentTimeSeconds, true)
    updateChapterList()
    updateCurrentChapterStatus()

    m.audioPlayer.control = "stop"
    m.audioPlayer.content = node
    m.isPaused = (playWhenReady <> true)
    disableScreenSaver()
    if playWhenReady then
        m.audioPlayer.control = "play"
        if m.hasStartedPlayback = true then setStatus("Playing")
    else
        m.audioPlayer.control = "pause"
        setStatus("Paused")
    end if
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
' getChapterItems
'-------------------------------------------------------------------------------
function getChapterItems(chapters as dynamic, tracks as dynamic) as object
    if chapters <> invalid and chapters.Count() > 0 then return chapters
    if tracks <> invalid then return tracks
    return []
end function

'-------------------------------------------------------------------------------
' clampGlobalTime
'-------------------------------------------------------------------------------
function clampGlobalTime(timeSeconds as dynamic) as integer
    if timeSeconds = invalid then timeSeconds = 0
    result = int(val(timeSeconds.ToStr()))
    if result < 0 then result = 0
    duration = getPlaybackDurationSeconds()
    if duration > 0 and result > duration then result = duration
    return result
end function

'-------------------------------------------------------------------------------
' getTrackIndexForGlobalTime
'-------------------------------------------------------------------------------
function getTrackIndexForGlobalTime(timeSeconds as dynamic) as integer
    if m.tracks = invalid or m.tracks.Count() = 0 then return 0
    if m.isHlsTranscode = true then return 0

    targetTime = clampGlobalTime(timeSeconds)
    lastIndex = m.tracks.Count() - 1
    for i = 0 to lastIndex
        track = m.tracks[i]
        trackStart = getTrackStartPosition(track)
        trackDuration = getTrackDurationSeconds(track)
        trackEnd = trackStart + trackDuration

        if targetTime >= trackStart and (trackDuration <= 0 or targetTime < trackEnd or i = lastIndex) then return i
    end for

    return 0
end function

'-------------------------------------------------------------------------------
' getTrackSeekPosition
'-------------------------------------------------------------------------------
function getTrackSeekPosition(trackIndex as integer, globalTime as dynamic) as integer
    seekTime = clampGlobalTime(globalTime)
    if m.isHlsTranscode = true then return seekTime
    if m.tracks = invalid or trackIndex < 0 or trackIndex >= m.tracks.Count() then return seekTime

    seekTime = seekTime - getTrackStartPosition(m.tracks[trackIndex])
    if seekTime < 0 then seekTime = 0

    trackDuration = getTrackDurationSeconds(m.tracks[trackIndex])
    if trackDuration > 0 and seekTime > trackDuration then seekTime = trackDuration

    return seekTime
end function

'-------------------------------------------------------------------------------
' seekToGlobalTime
'-------------------------------------------------------------------------------
sub seekToGlobalTime(globalTime as dynamic, playWhenReady = true as boolean, shouldSync = true as boolean)
    if m.audioPlayer = invalid then return
    if m.tracks = invalid or m.tracks.Count() = 0 then return

    targetTime = clampGlobalTime(globalTime)
    setPlaybackVisualTarget(targetTime)
    targetTrackIndex = getTrackIndexForGlobalTime(targetTime)
    m.currentTimeSeconds = targetTime

    if targetTrackIndex <> m.currentTrackIndex then
        m.currentTrackIndex = targetTrackIndex
        m.pendingSeekSeconds = getTrackSeekPosition(m.currentTrackIndex, targetTime)
        playCurrentTrack(playWhenReady)
    else
        seekPosition = getTrackSeekPosition(m.currentTrackIndex, targetTime)
        m.audioPlayer.seek = seekPosition
        if playWhenReady = true and m.audioPlayer.state = "paused" then m.audioPlayer.control = "resume"
        if playWhenReady = false and m.audioPlayer.state = "playing" then m.audioPlayer.control = "pause"
    end if

    updatePlaybackPosition(targetTime)
    updateChapterList()
    updateCurrentChapterStatus()
    if shouldSync then requestSyncPlaybackSession("seek", targetTime)
end sub

'-------------------------------------------------------------------------------
' updatePlaybackPosition
'-------------------------------------------------------------------------------
sub updatePlaybackPosition(globalTime as dynamic)
    m.currentTimeSeconds = clampGlobalTime(globalTime)
    if m.tracks = invalid or m.tracks.Count() = 0 then
        updateProgress(m.currentTimeSeconds)
        return
    end if
    m.currentTrackIndex = getTrackIndexForGlobalTime(m.currentTimeSeconds)
    updateProgress(m.currentTimeSeconds)
    updateCurrentChapterStatus()
end sub

'-------------------------------------------------------------------------------
' getInitialTrackSeekPosition
'-------------------------------------------------------------------------------
function getInitialTrackSeekPosition() as integer
    if m.pendingSeekSeconds <> invalid then return int(val(m.pendingSeekSeconds.ToStr()))
    return getTrackSeekPosition(m.currentTrackIndex, m.currentTimeSeconds)
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
    if track.startOffset <> invalid then return int(val(track.startOffset.ToStr()))
    return 0
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

    '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    ' playing
    '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    if state = "playing" then
        hasUnsettledHlsStartupSeek = (m.isHlsTranscode = true and (m.pendingSeekSeconds <> invalid or m.hlsStartupSeekTargetSeconds <> invalid))
        if hasUnsettledHlsStartupSeek <> true then m.hlsRetryCount = 0
        m.hlsRetryPending = false
        m.hasStartedPlayback = true
        m.isPaused = false
        disableScreenSaver()
        applyPendingInitialSeek()
        setStatus("Playing")
        startProgressTimer()
        updatePlayPauseButton()
    '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    ' buffering
    '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    else if state = "buffering" then
        disableScreenSaver()
        m.log.write("buffering state observed")
    '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    ' finished
    '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    else if state = "finished" then
        if m.pendingSeekSeconds <> invalid and m.isHlsTranscode <> true then
            applyPendingInitialSeek()
            m.audioPlayer.control = "play"
            return
        end if

        if playNextTrack() then
            return
        end if

        if isPlaybackNearEnd() <> true then
            if restartWithTranscodeFallback("finished-before-duration") then return
            if scheduleHlsStartupRetry("finished-before-duration") then return
            if refreshHlsPlaybackSession("finished-before-duration") then return

            stopProgressTimer()
            enableScreenSaver()
            logPlaybackError("Unexpected playback end before media duration.")
            setStatus("Playback stopped before completion.")
            m.isPaused = false
            updatePlayPauseButton()
            return
        end if

        stopProgressTimer()
        enableScreenSaver()
        updateProgress(m.totalDurationSeconds, true)
        setStatus("Finished")
        m.isPaused = false
        updatePlayPauseButton()
    else if state = "error" then
        logPlaybackError("Roku media node entered error state.")
        if restartWithTranscodeFallback("media-error") then return
        if scheduleHlsStartupRetry("media-error") then return
        if refreshHlsPlaybackSession("media-error") then return

        stopProgressTimer()
        enableScreenSaver()
        setStatus("Playback error.")
        m.isPaused = false
        updatePlayPauseButton()
    end if
end sub

'-------------------------------------------------------------------------------
' restartWithTranscodeFallback
'-------------------------------------------------------------------------------
function restartWithTranscodeFallback(reason as string) as boolean
    if m.isClosing = true then return false
    if m.isHlsTranscode = true then return false
    if m.forceTranscodeFallbackTried = true then return false

    m.forceTranscodeFallbackTried = true
    restartPlaybackSession(true, "direct-play-fallback-" + reason)
    return true
end function

'-------------------------------------------------------------------------------
' refreshHlsPlaybackSession
'-------------------------------------------------------------------------------
function refreshHlsPlaybackSession(reason as string) as boolean
    if m.isClosing = true then return false
    if m.isHlsTranscode <> true then return false
    if m.hlsSessionRefreshTried = true then return false

    m.hlsSessionRefreshTried = true
    restartPlaybackSession(true, "hls-session-refresh-" + reason)
    return true
end function

'-------------------------------------------------------------------------------
' restartPlaybackSession
'-------------------------------------------------------------------------------
sub restartPlaybackSession(forceTranscode as boolean, reason as string)
    currentTime = getPlaybackCurrentTimeSeconds()
    m.log.write("Restarting playback session reason=" + reason + " currentTime=" + currentTime.ToStr() + " forceTranscode=" + forceTranscode.ToStr())

    resetMediaNodeForNewPlayback()
    resetPlaybackSessionState()
    resetPlaybackRetryState(false)
    m.currentTimeSeconds = currentTime
    m.requestedStartPositionSeconds = currentTime
    setStatus("Starting playback...")
    requestStartPlaybackSession(forceTranscode, currentTime)
end sub

'-------------------------------------------------------------------------------
' scheduleHlsStartupRetry
'-------------------------------------------------------------------------------
function scheduleHlsStartupRetry(reason as string) as boolean
    if m.isClosing = true then return false
    if m.isHlsTranscode <> true then return false
    if m.hlsRetryPending = true then return true
    retryMax = getHlsRetryMax()
    if m.hlsRetryCount >= retryMax then return false

    m.hlsRetryCount = m.hlsRetryCount + 1
    m.hlsRetryPending = true
    stopProgressTimer()
    m.log.write("HLS startup retry " + m.hlsRetryCount.ToStr() + "/" + retryMax.ToStr() + " reason=" + reason + " currentTime=" + m.currentTimeSeconds.ToStr())

    if m.audioPlayer <> invalid then m.audioPlayer.control = "stop"
    if m.hlsRetryTimer <> invalid then
        m.hlsRetryTimer.control = "stop"
        m.hlsRetryTimer.control = "start"
    else
        retryHlsPlayback()
    end if

    return true
end function

'-------------------------------------------------------------------------------
' getHlsRetryMax
'-------------------------------------------------------------------------------
function getHlsRetryMax() as integer
    if m.hlsStartupSeekTargetSeconds <> invalid then return m.hlsResumeRetryMax
    return m.hlsRetryMax
end function

'-------------------------------------------------------------------------------
' onHlsRetryTimerFired
'-------------------------------------------------------------------------------
sub onHlsRetryTimerFired()
    retryHlsPlayback()
end sub

'-------------------------------------------------------------------------------
' retryHlsPlayback
'-------------------------------------------------------------------------------
sub retryHlsPlayback()
    if m.isClosing = true then return
    if m.tracks = invalid or m.tracks.Count() = 0 then return

    m.hlsRetryPending = false
    m.pendingSeekSeconds = getTrackSeekPosition(m.currentTrackIndex, m.currentTimeSeconds)
    playCurrentTrack(true)
end sub

'-------------------------------------------------------------------------------
' getTrackPlaybackUrl
'-------------------------------------------------------------------------------
function getTrackPlaybackUrl(track as dynamic) as string
    url = SafeString(track.url, "")
    if m.isHlsTranscode <> true then return url
    if m.hlsRetryCount <= 0 then return url

    separator = "?"
    if Instr(1, url, "?") > 0 then separator = "&"
    return url + separator + "abstvRetry=" + m.hlsRetryCount.ToStr()
end function

'-------------------------------------------------------------------------------
' applyPendingInitialSeek
'-------------------------------------------------------------------------------
sub applyPendingInitialSeek()
    if m.audioPlayer = invalid then return
    if m.pendingSeekSeconds = invalid then return

    seekPosition = int(val(m.pendingSeekSeconds.ToStr()))
    m.pendingSeekSeconds = invalid
    m.audioPlayer.seek = seekPosition
    m.log.write("applied pending seek=" + seekPosition.ToStr() + " state=" + SafeString(m.audioPlayer.state, ""))
end sub

'-------------------------------------------------------------------------------
' playNextTrack
'-------------------------------------------------------------------------------
function playNextTrack() as boolean
    if m.tracks = invalid then return false
    if m.isHlsTranscode = true then return false
    nextIndex = m.currentTrackIndex + 1
    if nextIndex >= m.tracks.Count() then return false

    m.currentTrackIndex = nextIndex
    m.currentTimeSeconds = getTrackStartPosition(m.tracks[m.currentTrackIndex])
    requestSyncPlaybackSession("trackChange", m.currentTimeSeconds)
    m.pendingSeekSeconds = 0
    playCurrentTrack()
    return true
end function

'-------------------------------------------------------------------------------
' isPlaybackNearEnd
'-------------------------------------------------------------------------------
function isPlaybackNearEnd() as boolean
    duration = getPlaybackDurationSeconds()
    if duration <= 0 then return true

    currentTime = getPlaybackCurrentTimeSeconds()
    m.log.write("finished check currentTime=" + currentTime.ToStr() + " duration=" + duration.ToStr())
    return currentTime >= duration - 3
end function

'-------------------------------------------------------------------------------
' logPlaybackError
'-------------------------------------------------------------------------------
sub logPlaybackError(message as string)
    if m.log = invalid then return

    errorText = message
    if m.audioPlayer <> invalid then
        errorText = errorText + " state=" + SafeString(m.audioPlayer.state, "")
        errorText = errorText + " errorCode=" + SafeString(m.audioPlayer.errorCode, "invalid")
        errorText = errorText + " errorMsg=" + SafeString(m.audioPlayer.errorMsg, "invalid")
        errorText = errorText + " errorStr=" + SafeString(m.audioPlayer.errorStr, "invalid")
    end if

    m.log.error(errorText)
end sub

'-------------------------------------------------------------------------------
' setStatus
'-------------------------------------------------------------------------------
sub setStatus(status as string)
    m.visiblePlaybackStatus = status
    if m.statusLabel <> invalid then m.statusLabel.text = status
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

    accumulatePlaybackListeningTime()
    requestClosePlaybackSession()
    cancelProgressScrub()
    stopProgressTimer()
    enableScreenSaver()
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

    resetPlaybackSessionState()
    resetPlaybackRetryState(true)
    resetPlaybackSyncState()
    m.currentTimeSeconds = 0
    resetProgress()
    updateChaptersButtonVisibility()
    m.closeRequestedCounter = m.closeRequestedCounter + 1
    m.top.closeRequested = m.closeRequestedCounter
end sub

'-------------------------------------------------------------------------------
' requestClosePlaybackSession
'-------------------------------------------------------------------------------
sub requestClosePlaybackSession()
    request = buildPlaybackSessionRequest("closePlaybackSession")
    if request <> invalid then runPlaybackApiRequest(request)
end sub

'-------------------------------------------------------------------------------
' requestSyncPlaybackSession
'-------------------------------------------------------------------------------
sub requestSyncPlaybackSession(reason = "" as string, currentTimeOverride = invalid as dynamic)
    request = buildPlaybackSessionRequest("syncPlaybackSession", currentTimeOverride)
    if request = invalid then return

    if reason <> "" then request.reason = reason
    if request.currentTime <> invalid then m.lastSyncedCurrentTimeSeconds = int(val(request.currentTime.ToStr()))
    m.listeningTimeSinceSync = 0
    m.lastPlaybackSyncAtSeconds = getNowSeconds()
    runPlaybackApiRequest(request)
end sub

'-------------------------------------------------------------------------------
' buildPlaybackSessionRequest
'-------------------------------------------------------------------------------
function buildPlaybackSessionRequest(action as string, currentTimeOverride = invalid as dynamic) as dynamic
    if m.playbackSessionId = invalid or m.playbackSessionId = "" then return invalid
    if m.playbackServer = invalid or m.playbackServer = "" then return invalid
    if m.playbackToken = invalid or m.playbackToken = "" then return invalid

    currentTime = getPlaybackCurrentTimeSeconds()
    if currentTimeOverride <> invalid then currentTime = int(val(currentTimeOverride.ToStr()))
    timeListened = getPlaybackTimeListenedSeconds()

    request = {
        action: action
        server: m.playbackServer
        token: m.playbackToken
        sessionId: m.playbackSessionId
    }

    if shouldSendPlaybackProgressData(action, timeListened) then
        request.currentTime = currentTime
        request.timeListened = timeListened
        request.duration = getPlaybackDurationSeconds()
    else
        m.log.write("Closing playback session without progress data because listening time was " + timeListened.ToStr() + " seconds.")
    end if

    return request
end function

'-------------------------------------------------------------------------------
' shouldSendPlaybackProgressData
'-------------------------------------------------------------------------------
function shouldSendPlaybackProgressData(action as string, timeListened as integer) as boolean
    if action <> "closePlaybackSession" then return true
    if m.lastSyncedCurrentTimeSeconds > 0 then return timeListened >= m.playbackSyncIntervalSeconds
    return timeListened >= m.closeProgressSaveThresholdSeconds
end function

'-------------------------------------------------------------------------------
' onKeyEvent
'-------------------------------------------------------------------------------
function onKeyEvent(key as string, press as boolean) as boolean
    if press = false then return false

    if m.nightModeTint <> invalid and m.nightModeTint.visible = true then
        m.nightModeTint.visible = false
        return true
    end if

    if m.isProgressScrubbing = true then
        if key = "back" then
            cancelProgressScrub()
            closePlayer()
            return true
        else if key = "left" then
            jogProgressScrub(-30)
            return true
        else if key = "right" then
            jogProgressScrub(30)
            return true
        else if key = "OK" or key = "select" or key = "play" then
            commitProgressScrub("transport")
            return true
        else if key = "down" then
            commitProgressScrub("transport")
            return true
        else if key = "up" then
            commitProgressScrub("description")
            return true
        end if
    end if

    if key = "back" then
        closePlayer()
        return true
    end if

    if m.descriptionLabel <> invalid and m.descriptionLabel.isInFocusChain() then
        if key = "down" then
            focusProgressBar(0)
            return true
        end if
    end if

    if m.transportFocusIndex >= 0 then
        if key = "left" then
            focusTransportButton(m.transportFocusIndex - 1)
            return true
        else if key = "right" then
            focusTransportButton(m.transportFocusIndex + 1)
            return true
        else if key = "up" then
            focusProgressBar(m.transportFocusIndex)
            return true
        else if key = "down" then
            return true
        else if key = "OK" or key = "select" then
            if m.transportFocusIndex = 3 then
                openChapterList()
            else
                activateTransportButton()
            end if
            return true
        end if
    end if

    if key = "down" then
        focusTransportButton(0)
        return true
    end if

    if key = "play" or key = "OK" or key = "select" then
        togglePlayPause()
        return true
    end if

    return false
end function

'-------------------------------------------------------------------------------
' focusDescriptionFromTransport
'-------------------------------------------------------------------------------
function focusDescriptionFromTransport() as boolean
    if m.descriptionLabel = invalid then return false
    if m.descriptionLabel.canAcceptFocus <> true then return false

    updateTransportFocus(-1)
    m.descriptionLabel.setFocus(true)
    return true
end function

'-------------------------------------------------------------------------------
' focusProgressBar
'-------------------------------------------------------------------------------
sub focusProgressBar(returnFocusIndex as integer)
    if m.progressGroup = invalid then return

    if returnFocusIndex < 0 then returnFocusIndex = 0
    transportButtonCount = getTransportButtonCount()
    if returnFocusIndex >= transportButtonCount then returnFocusIndex = transportButtonCount - 1
    if returnFocusIndex < 0 then returnFocusIndex = 0

    m.isProgressScrubbing = true
    m.progressScrubReturnFocusIndex = returnFocusIndex
    m.progressScrubTargetSeconds = getPlaybackCurrentTimeSeconds()

    updatePlayPauseButton()
    updateTransportFocus(-1)
    updateProgressScrubPreview()
    m.progressGroup.setFocus(true)
end sub

'-------------------------------------------------------------------------------
' jogProgressScrub
'-------------------------------------------------------------------------------
sub jogProgressScrub(offsetSeconds as integer)
    if m.isProgressScrubbing <> true then return

    m.progressScrubTargetSeconds = m.progressScrubTargetSeconds + offsetSeconds
    updateProgressScrubPreview()
    seekToGlobalTime(m.progressScrubTargetSeconds, true, true)
    m.isPaused = false
    disableScreenSaver()
    startProgressTimer()
    setStatus("Playing")
    updatePlayPauseButton()
end sub

'-------------------------------------------------------------------------------
' updateProgressScrubPreview
'-------------------------------------------------------------------------------
sub updateProgressScrubPreview()
    targetPosition = clampGlobalTime(m.progressScrubTargetSeconds)
    m.progressScrubTargetSeconds = targetPosition

    updateProgress(targetPosition, true)

    crossbarX = 0
    if m.totalDurationSeconds > 0 then
        crossbarX = int((targetPosition / m.totalDurationSeconds) * m.progressBarWidth)
    end if

    crossbarWidth = m.progressCrossbarWidth
    if m.progressCrossbar <> invalid and m.progressCrossbar.width <> invalid then crossbarWidth = int(m.progressCrossbar.width)
    halfCrossbarWidth = int(crossbarWidth / 2)
    if halfCrossbarWidth < 1 then halfCrossbarWidth = 1

    if crossbarX < halfCrossbarWidth then crossbarX = halfCrossbarWidth
    if crossbarX > m.progressBarWidth - halfCrossbarWidth then crossbarX = m.progressBarWidth - halfCrossbarWidth
    if m.progressCrossbar <> invalid then
        m.progressCrossbar.translation = [crossbarX - halfCrossbarWidth, m.progressCrossbarY]
        m.progressCrossbar.visible = true
    end if
end sub

'-------------------------------------------------------------------------------
' commitProgressScrub
'-------------------------------------------------------------------------------
sub commitProgressScrub(nextFocus as string)
    if m.isProgressScrubbing <> true then return

    exitProgressScrub(nextFocus)
end sub

'-------------------------------------------------------------------------------
' exitProgressScrub
'-------------------------------------------------------------------------------
sub exitProgressScrub(nextFocus as string)
    m.isProgressScrubbing = false
    if m.progressCrossbar <> invalid then m.progressCrossbar.visible = false
    updateProgress(getPlaybackCurrentTimeSeconds(), true)
    updatePlayPauseButton()

    if nextFocus = "description" and focusDescriptionFromTransport() then return
    focusTransportButton(m.progressScrubReturnFocusIndex)
end sub

'-------------------------------------------------------------------------------
' cancelProgressScrub
'-------------------------------------------------------------------------------
sub cancelProgressScrub()
    if m.isProgressScrubbing <> true then return

    m.isProgressScrubbing = false
    if m.progressCrossbar <> invalid then m.progressCrossbar.visible = false
    updateProgress(getPlaybackCurrentTimeSeconds(), true)
    updatePlayPauseButton()
end sub

' focusTransportButton
'-------------------------------------------------------------------------------
sub focusTransportButton(index as integer)
    if index < 0 then index = 0
    transportButtonCount = getTransportButtonCount()
    if index >= transportButtonCount then index = transportButtonCount - 1
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
        togglePlayPause()
    else if m.transportFocusIndex = 1 then
        restartPlayback()
    else if m.transportFocusIndex = 2 then
        toggleNightModeTint()
    else if m.transportFocusIndex = 3 then
        openChapterList()
    end if
end sub

'-------------------------------------------------------------------------------
' toggleNightModeTint
'-------------------------------------------------------------------------------
sub toggleNightModeTint()
    if m.nightModeTint = invalid then return

    m.nightModeTint.visible = not m.nightModeTint.visible
end sub

'-------------------------------------------------------------------------------
' hideNightModeTint
'-------------------------------------------------------------------------------
sub hideNightModeTint()
    if m.nightModeTint <> invalid then m.nightModeTint.visible = false
end sub

'-------------------------------------------------------------------------------
' restartPlayback
'-------------------------------------------------------------------------------
sub restartPlayback()
    if m.audioPlayer = invalid then return
    if m.tracks = invalid or m.tracks.Count() = 0 then return

    seekToGlobalTime(0, true, true)
    m.isPaused = false
    disableScreenSaver()
    startProgressTimer()
    setStatus("Playing")
    updatePlayPauseButton()
end sub

'-------------------------------------------------------------------------------
' updateChaptersButtonVisibility
'-------------------------------------------------------------------------------
sub updateChaptersButtonVisibility()
    hasMultipleTracks = (m.chapterItems <> invalid and m.chapterItems.Count() > 1)
    if m.chaptersButton <> invalid then
        m.chaptersButton.visible = hasMultipleTracks
        if hasMultipleTracks = false then m.chaptersButton.hasFocusVisual = false
    end if

    if hasMultipleTracks = false and m.transportFocusIndex > 2 then updateTransportFocus(2)
end sub

'-------------------------------------------------------------------------------
' updateChapterMarkers
'-------------------------------------------------------------------------------
sub updateChapterMarkers()
    if m.chapterMarkersGroup = invalid then return

    m.hasChapterMarkers = false
    while m.chapterMarkersGroup.getChildCount() > 0
        child = m.chapterMarkersGroup.getChild(0)
        if child = invalid then exit while
        m.chapterMarkersGroup.removeChild(child)
    end while

    if m.chapterItems = invalid or m.chapterItems.Count() <= 1 then
        updateChapterMarkerLayout()
        return
    end if
    if m.totalDurationSeconds <= 0 then
        updateChapterMarkerLayout()
        return
    end if

    markerWidth = m.chapterMarkerWidth
    markerTop = m.chapterMarkerTop
    markerBottom = m.chapterMarkerBottom
    markerHeight = markerBottom - markerTop
    m.chapterMarkerHeight = markerHeight
    halfMarkerWidth = int(markerWidth / 2)
    if halfMarkerWidth < 1 then halfMarkerWidth = 1
    m.hasChapterMarkers = true

    for each chapter in m.chapterItems
        chapterPosition = getChapterStartPosition(chapter)
        if chapterPosition < 0 then chapterPosition = 0
        if chapterPosition > m.totalDurationSeconds then chapterPosition = m.totalDurationSeconds

        markerX = int((chapterPosition / m.totalDurationSeconds) * m.progressBarWidth)
        if markerX < halfMarkerWidth then markerX = halfMarkerWidth
        if markerX > m.progressBarWidth - halfMarkerWidth then markerX = m.progressBarWidth - halfMarkerWidth

        marker = CreateObject("roSGNode", "Rectangle")
        if marker <> invalid then
            marker.width = markerWidth
            marker.height = markerHeight
            marker.translation = [markerX - halfMarkerWidth, markerTop]
            marker.color = m.chapterMarkerColor
            m.chapterMarkersGroup.appendChild(marker)
        end if
    end for

    updateChapterMarkerLayout()
end sub

'-------------------------------------------------------------------------------
' updateChapterMarkerLayout
'-------------------------------------------------------------------------------
sub updateChapterMarkerLayout()
    offsetY = 0
    if m.hasChapterMarkers = true then offsetY = m.chapterMarkerHeight

    if m.currentTimeLabel <> invalid then m.currentTimeLabel.translation = [0, m.progressTimeLabelY + offsetY]
    if m.totalTimeLabel <> invalid then m.totalTimeLabel.translation = [m.progressTotalTimeLabelX, m.progressTimeLabelY + offsetY]
    if m.playPauseButton <> invalid then m.playPauseButton.translation = [m.playPauseButtonX, m.transportButtonY + offsetY]
    if m.restartButton <> invalid then m.restartButton.translation = [m.restartButtonX, m.transportButtonY + offsetY]
    if m.tintButton <> invalid then m.tintButton.translation = [m.tintButtonX, m.transportButtonY + offsetY]
    if m.chaptersButton <> invalid then m.chaptersButton.translation = [m.chaptersButtonX, m.transportButtonY + offsetY]
end sub

'-------------------------------------------------------------------------------
' openChapterList
'-------------------------------------------------------------------------------
sub openChapterList()
    if m.chapterList = invalid then return
    if m.chapterItems = invalid or m.chapterItems.Count() <= 1 then return

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

    m.chapterList.tracks = m.chapterItems
    m.chapterList.currentTrackIndex = getCurrentChapterIndex()
    m.chapterList.audiobookTitle = m.audiobookTitle
    updateCurrentChapterStatus()
end sub

'-------------------------------------------------------------------------------
' updateCurrentChapterStatus
'-------------------------------------------------------------------------------
sub updateCurrentChapterStatus()
    if m.deferChapterStatusUpdates = true then
        m.pendingChapterStatusUpdate = true
        return
    end if

    title = ""
    if m.chapterItems <> invalid and m.chapterItems.Count() > 1 then
        index = getCurrentChapterIndex()
        if index >= 0 and index < m.chapterItems.Count() then
            chapter = m.chapterItems[index]
            if chapter <> invalid then title = SafeString(chapter.title, "")
        end if
    end if

    setLabelText(m.trackTitleLabel, title)
end sub

'-------------------------------------------------------------------------------
' beginChapterStatusUpdateBatch
'-------------------------------------------------------------------------------
sub beginChapterStatusUpdateBatch()
    m.deferChapterStatusUpdates = true
    m.pendingChapterStatusUpdate = false
end sub

'-------------------------------------------------------------------------------
' endChapterStatusUpdateBatch
'-------------------------------------------------------------------------------
sub endChapterStatusUpdateBatch()
    pendingUpdate = (m.pendingChapterStatusUpdate = true)
    m.deferChapterStatusUpdates = false
    m.pendingChapterStatusUpdate = false

    if pendingUpdate = true then updateCurrentChapterStatus()
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
    if m.chapterItems = invalid then return
    if index < 0 or index >= m.chapterItems.Count() then return

    focusChaptersButton()

    stopProgressTimer()
    chapter = m.chapterItems[index]
    beginChapterStatusUpdateBatch()
    seekToGlobalTime(getChapterStartPosition(chapter), m.isPaused <> true, true)
    endChapterStatusUpdateBatch()
end sub

'-------------------------------------------------------------------------------
' getCurrentChapterIndex
'-------------------------------------------------------------------------------
function getCurrentChapterIndex() as integer
    if m.chapterItems = invalid or m.chapterItems.Count() = 0 then return 0

    currentIndex = 0
    currentTime = getPlaybackCurrentTimeSeconds()
    for i = 0 to m.chapterItems.Count() - 1
        chapter = m.chapterItems[i]
        if chapter <> invalid and currentTime >= getChapterStartPosition(chapter) then currentIndex = i
    end for

    return currentIndex
end function

'-------------------------------------------------------------------------------
' getChapterStartPosition
'-------------------------------------------------------------------------------
function getChapterStartPosition(chapter as dynamic) as integer
    if chapter = invalid then return 0
    if chapter.startOffset <> invalid then return int(val(chapter.startOffset.ToStr()))
    return 0
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
        updateProgress(getPlaybackCurrentTimeSeconds())
        requestSyncPlaybackSession("pause")
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
        m.playPauseButton.iconUri = "pkg:/images/icons/play.png"
    else
        m.playPauseButton.text = "Pause"
        m.playPauseButton.iconUri = "pkg:/images/icons/pause.png"
    end if
end sub

' onProgressTimerFired
'-------------------------------------------------------------------------------
sub onProgressTimerFired()
    accumulatePlaybackListeningTime()
    position = getPlaybackCurrentTimeSeconds()

    if m.isProgressScrubbing = true then
        m.progressScrubTargetSeconds = position
        updatePlaybackPosition(position)
        updateProgressScrubPreview()
        requestPeriodicPlaybackSync()
        return
    end if

    updatePlaybackPosition(position)
    requestPeriodicPlaybackSync()
end sub

'-------------------------------------------------------------------------------
' accumulatePlaybackListeningTime
'-------------------------------------------------------------------------------
sub accumulatePlaybackListeningTime()
    if m.audioPlayer = invalid then return
    if SafeString(m.audioPlayer.state, "") <> "playing" then
        m.lastProgressTickAtSeconds = 0
        return
    end if

    nowSeconds = getNowSeconds()
    if m.lastProgressTickAtSeconds > 0 then
        elapsedSeconds = nowSeconds - m.lastProgressTickAtSeconds
        if elapsedSeconds > 0 and elapsedSeconds < 10 then
            m.listeningTimeSinceSync = m.listeningTimeSinceSync + elapsedSeconds
        end if
    end if

    m.lastProgressTickAtSeconds = nowSeconds
end sub

'-------------------------------------------------------------------------------
' requestPeriodicPlaybackSync
'-------------------------------------------------------------------------------
sub requestPeriodicPlaybackSync()
    if m.isPaused = true then return
    if m.isClosing = true then return
    if m.audioPlayer = invalid then return
    if SafeString(m.audioPlayer.state, "") <> "playing" then return

    syncIntervalSeconds = m.playbackSyncIntervalSeconds
    if m.lastSyncedCurrentTimeSeconds <= 0 then syncIntervalSeconds = m.firstPlaybackSyncIntervalSeconds

    if m.listeningTimeSinceSync >= syncIntervalSeconds then
        requestSyncPlaybackSession("periodic")
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
    position = getPlaybackCurrentTimeSeconds() - m.currentTrackStartPosition
    if position < 0 then position = 0
    return position
end function

'-------------------------------------------------------------------------------
' setPlaybackVisualTarget
'-------------------------------------------------------------------------------
sub setPlaybackVisualTarget(targetTime as dynamic)
    m.playbackVisualTargetSeconds = clampGlobalTime(targetTime)
    updateProgress(m.playbackVisualTargetSeconds, true)
    updateCurrentChapterStatus()
end sub

'-------------------------------------------------------------------------------
' getPlaybackCurrentTimeSeconds
'-------------------------------------------------------------------------------
function getPlaybackCurrentTimeSeconds() as integer
    if m.playbackVisualTargetSeconds <> invalid then
        actualTime = getActualPlaybackCurrentTimeSeconds()
        targetTime = clampGlobalTime(m.playbackVisualTargetSeconds)
        if m.hasStartedPlayback <> true then return targetTime
        if Abs(actualTime - targetTime) <= 2 then
            m.playbackVisualTargetSeconds = invalid
            return actualTime
        end if
        return targetTime
    end if

    return getActualPlaybackCurrentTimeSeconds()
end function

'-------------------------------------------------------------------------------
' getActualPlaybackCurrentTimeSeconds
'-------------------------------------------------------------------------------
function getActualPlaybackCurrentTimeSeconds() as integer
    if m.audioPlayer = invalid then return clampGlobalTime(m.currentTimeSeconds)
    if m.tracks = invalid or m.tracks.Count() = 0 then return clampGlobalTime(m.currentTimeSeconds)
    if m.hasStartedPlayback <> true then return clampGlobalTime(m.currentTimeSeconds)

    currentPosition = getCurrentPlaybackPosition()
    if m.isHlsTranscode = true then return getHlsPlaybackCurrentTime(currentPosition)

    if m.currentTrackIndex < 0 or m.currentTrackIndex >= m.tracks.Count() then return clampGlobalTime(m.currentTimeSeconds)
    return clampGlobalTime(getTrackStartPosition(m.tracks[m.currentTrackIndex]) + currentPosition)
end function

'-------------------------------------------------------------------------------
' getHlsPlaybackCurrentTime
'-------------------------------------------------------------------------------
function getHlsPlaybackCurrentTime(currentPosition as integer) as integer
    currentTime = currentPosition
    if m.hlsStartupSeekTargetSeconds = invalid then return clampGlobalTime(currentTime)

    targetTime = clampGlobalTime(m.hlsStartupSeekTargetSeconds)
    if currentTime >= targetTime + 3 then
        m.hlsStartupSeekTargetSeconds = invalid
        return clampGlobalTime(currentTime)
    end if

    return targetTime
end function

'-------------------------------------------------------------------------------
' getPlaybackDurationSeconds
'-------------------------------------------------------------------------------
function getPlaybackDurationSeconds() as integer
    if m.playbackSession <> invalid and m.playbackSession.duration <> invalid then
        return int(val(m.playbackSession.duration.ToStr()))
    end if

    durationSeconds = 0
    if m.tracks <> invalid then
        for each track in m.tracks
            durationSeconds = durationSeconds + getTrackDurationSeconds(track)
        end for
    end if

    return durationSeconds
end function

'-------------------------------------------------------------------------------
' getPlaybackTimeListenedSeconds
'-------------------------------------------------------------------------------
function getPlaybackTimeListenedSeconds() as integer
    timeListened = int(m.listeningTimeSinceSync)
    if timeListened < 0 then return 0
    return timeListened
end function

'-------------------------------------------------------------------------------
' getNowSeconds
'-------------------------------------------------------------------------------
function getNowSeconds() as integer
    dateTime = CreateObject("roDateTime")
    return dateTime.AsSeconds()
end function

'-------------------------------------------------------------------------------
' updateProgress
'-------------------------------------------------------------------------------
sub updateProgress(positionSeconds as integer, forceUpdate = false as boolean)
    if forceUpdate <> true and m.hasStartedPlayback <> true then return

    if positionSeconds < 0 then positionSeconds = 0
    if m.totalDurationSeconds > 0 and positionSeconds > m.totalDurationSeconds then positionSeconds = m.totalDurationSeconds

    setLabelText(m.currentTimeLabel, formatPlaybackTime(positionSeconds))
    setLabelText(m.chapterStatusLabel, "-" + formatPlaybackTime(getRemainingPlaybackSeconds(positionSeconds)))

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
' getRemainingPlaybackSeconds
'-------------------------------------------------------------------------------
function getRemainingPlaybackSeconds(positionSeconds as integer) as integer
    if m.totalDurationSeconds <= 0 then return 0

    remainingSeconds = m.totalDurationSeconds - positionSeconds
    if remainingSeconds < 0 then return 0
    return remainingSeconds
end function

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
    updateProgress(m.currentTimeSeconds, true)
end sub

'-------------------------------------------------------------------------------
' startProgressTimer
'-------------------------------------------------------------------------------
sub startProgressTimer()
    if m.lastProgressTickAtSeconds <= 0 then m.lastProgressTickAtSeconds = getNowSeconds()
    if m.progressTimer <> invalid then m.progressTimer.control = "start"
    if m.isProgressScrubbing = true then
        m.progressScrubTargetSeconds = getPlaybackCurrentTimeSeconds()
        updateProgressScrubPreview()
    else
        updateProgress(getPlaybackCurrentTimeSeconds())
    end if
end sub

'-------------------------------------------------------------------------------
' stopProgressTimer
'-------------------------------------------------------------------------------
sub stopProgressTimer()
    if m.progressTimer <> invalid then m.progressTimer.control = "stop"
    m.lastProgressTickAtSeconds = 0
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
