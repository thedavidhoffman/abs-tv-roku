'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    
    m.log = CreateLogger("Player", false)
    m.log.write("init")

    initReferences()
    initValues()
    initHandlers()
    updateChaptersButtonVisibility()
    updatePlaybackControlsFocus(-1)
    updatePlayPauseButton()
end sub

'-------------------------------------------------------------------------------
' initReferences
'-------------------------------------------------------------------------------
sub initReferences()
    m.cover = m.top.findNode("cover")
    m.audioBadges = m.top.findNode("audioBadges")
    m.metadata = m.top.findNode("metadata")
    m.playbackControls = m.top.findNode("playbackControls")
    m.timerRefs = {
        progressTimer: m.top.findNode("progressTimer")
        closeTimer: m.top.findNode("closeTimer")
        hlsRetryTimer: m.top.findNode("hlsRetryTimer")
    }
    m.dialogRefs = {
        chapterList: m.top.findNode("chapterList")
    }
    m.playbackRefs = {
        audioPlayer: m.top.findNode("audioPlayer")
        playbackApiTask: m.top.findNode("playbackApiTask")
    }
    m.overlayRefs = {
        screensaverOverlay: m.top.findNode("screensaverOverlay")
        nightModeTint: m.top.findNode("nightModeTint")
    }
end sub

'-------------------------------------------------------------------------------
' initValues
'-------------------------------------------------------------------------------
sub initValues()
    initPlaybackValues()
    initPlaybackRetryValues()
    initPlaybackSyncValues()
    initProgressScrubValues()
    initChapterValues()
    initLifecycleValues()
end sub

'-------------------------------------------------------------------------------
' initPlaybackValues
'-------------------------------------------------------------------------------
sub initPlaybackValues()
    m.playbackContent = {
        audiobookTitle: "Audiobook"
        tracks: []
        chapterItems: []
    }
    m.timeline = {
        currentTrackIndex: 0
        currentTrackStartPosition: 0
        currentTimeSeconds: 0
        requestedStartPositionSeconds: 0
        pendingSeekSeconds: invalid
        totalDurationSeconds: 0
    }
    m.playbackContext = {
        server: invalid
        token: invalid
        session: invalid
        sessionId: invalid
        requestCounter: 0
        activeStartRequestCounter: 0
        startTimeOverrideSeconds: invalid
    }
    m.playbackState = {
        hasStarted: false
        visibleStatus: ""
        complete: false
        isPaused: false
    }
end sub

'-------------------------------------------------------------------------------
' initPlaybackRetryValues
'-------------------------------------------------------------------------------
sub initPlaybackRetryValues()
    m.hlsRetry = {
        isTranscode: false
        count: 0
        max: 3
        resumeMax: 8
        pending: false
        startupSeekTargetSeconds: invalid
        sessionRefreshTried: false
        forceTranscodeFallbackTried: false
    }
end sub

'-------------------------------------------------------------------------------
' initPlaybackSyncValues
'-------------------------------------------------------------------------------
sub initPlaybackSyncValues()
    m.playbackSync = {
        config: {
            firstSyncIntervalSeconds: 20
            syncIntervalSeconds: 10
            closeProgressSaveThresholdSeconds: 20
        }
        startedAtSeconds: 0
        lastSyncAtSeconds: 0
        lastProgressTickAtSeconds: 0
        lastSyncedCurrentTimeSeconds: 0
        listeningTimeSinceSync: 0
        visualTargetSeconds: invalid
    }
end sub

'-------------------------------------------------------------------------------
' initProgressScrubValues
'-------------------------------------------------------------------------------
sub initProgressScrubValues()
    m.progressScrub = {
        isActive: false
        targetSeconds: 0
        returnFocusIndex: 0
    }
end sub

'-------------------------------------------------------------------------------
' initChapterValues
'-------------------------------------------------------------------------------
sub initChapterValues()
    m.chapterStatus = {
        deferUpdates: false
        pendingUpdate: false
        startPositions: []
    }
end sub

'-------------------------------------------------------------------------------
' initLifecycleValues
'-------------------------------------------------------------------------------
sub initLifecycleValues()
    m.closeRequestedCounter = 0
    m.isClosing = false
end sub

'-------------------------------------------------------------------------------
' initHandlers
'-------------------------------------------------------------------------------
sub initHandlers()
    m.timerRefs.progressTimer.observeField("fire", "onProgressTimerFired")
    m.timerRefs.closeTimer.observeField("fire", "onCloseTimerFired")
    m.timerRefs.hlsRetryTimer.observeField("fire", "onHlsRetryTimerFired")
    m.playbackRefs.audioPlayer.observeField("state", "onAudioStateChanged")
    m.playbackRefs.playbackApiTask.observeField("response", "onPlaybackApiResponse")
    m.dialogRefs.chapterList.observeField("selectedChapter", "onChapterSelected")
    m.dialogRefs.chapterList.observeField("closedCounter", "onChapterListClosed")
    m.playbackControls.observeField("selectedAction", "onPlaybackActionSelected")
    m.playbackControls.observeField("focusUpRequested", "onPlaybackControlsFocusUpRequested")
end sub

'-------------------------------------------------------------------------------
' onPlayRequestChanged
'-------------------------------------------------------------------------------
sub onPlayRequestChanged()

    m.log.write("onPlayRequestChanged")

    request = m.top.playRequest

    if request = invalid then
        m.log.error("invalid request")
        return
    end if

    m.log.write("title = " + SafeString(request.title))
    m.log.write("itemId = " + SafeString(request.itemId))
    m.log.write("startPosition = " + SafeString(request.startPositionSeconds))

    m.isClosing = false
    m.playbackState.complete = false
    if m.timerRefs.closeTimer <> invalid then m.timerRefs.closeTimer.control = "stop"
    resetMediaNodeForNewPlayback()

    m.playbackContext.server = request.server
    m.playbackContext.token = request.token
    resetPlaybackSessionState()
    resetPlaybackRetryState(true)
    resetPlaybackSyncState()
    m.playbackContent.audiobookTitle = SafeString(request.title, "Audiobook")
    m.timeline.requestedStartPositionSeconds = getRequestStartPosition(request)
    m.timeline.currentTimeSeconds = m.timeline.requestedStartPositionSeconds

    if m.cover <> invalid then m.cover.itemContent = getCoverContent(request)
    startScreensaverOverlay(request)
    if m.metadata <> invalid then m.metadata.titleText = m.playbackContent.audiobookTitle
    if m.dialogRefs.chapterList <> invalid then m.dialogRefs.chapterList.audiobookTitle = m.playbackContent.audiobookTitle
    updateDetails(request.details)
    resetProgress()
    closeChapterList()
    hideNightModeTint()
    updateChaptersButtonVisibility()
    focusPlaybackButton(0)
    setStatus("Starting playback...")

    requestStartPlaybackSession(false)
end sub

'-------------------------------------------------------------------------------
' requestStartPlaybackSession
'-------------------------------------------------------------------------------
sub requestStartPlaybackSession(forceTranscode = false as boolean, startTimeOverride = invalid as dynamic)
        
    m.log.write("requestStartPlaybackSession")

    request = m.top.playRequest
    if request = invalid then return

    m.playbackContext.startTimeOverrideSeconds = startTimeOverride
    m.playbackContext.requestCounter = m.playbackContext.requestCounter + 1
    m.playbackContext.activeStartRequestCounter = m.playbackContext.requestCounter
    runPlaybackApiRequest({
        action: "startPlayback"
        server: request.server
        token: request.token
        itemId: request.itemId
        title: request.title
        forceDirectPlay: false
        forceTranscode: forceTranscode
        requestCounter: m.playbackContext.activeStartRequestCounter
    })
end sub

'-------------------------------------------------------------------------------
' resetMediaNodeForNewPlayback
'-------------------------------------------------------------------------------
sub resetMediaNodeForNewPlayback()

    m.log.write("resetMediaNodeForNewPlayback")

    stopScreensaverOverlay()
    stopProgressTimer()
    cancelProgressScrub()
    if m.timerRefs.hlsRetryTimer <> invalid then m.timerRefs.hlsRetryTimer.control = "stop"
    if m.playbackRefs.audioPlayer <> invalid then
        m.playbackRefs.audioPlayer.control = "stop"
        m.playbackRefs.audioPlayer.content = invalid
    end if
end sub

'-------------------------------------------------------------------------------
' startScreensaverOverlay
'-------------------------------------------------------------------------------
sub startScreensaverOverlay(request as object)

    m.log.write("startScreensaverOverlay")

    m.overlayRefs.screensaverOverlay.playbackRequest = {
        server: request.server
        token: request.token
        itemId: request.itemId
    }

    m.overlayRefs.screensaverOverlay.callFunc("startDelay")

end sub

'-------------------------------------------------------------------------------
' restartScreensaverOverlayDelay
'-------------------------------------------------------------------------------
sub restartScreensaverOverlayDelay()

    m.log.write("restartScreensaverOverlayDelay")

    m.playbackState.complete = false
    startScreensaverOverlay(m.top.playRequest)
end sub

'-------------------------------------------------------------------------------
' stopScreensaverOverlay
'-------------------------------------------------------------------------------
sub stopScreensaverOverlay()

    m.log.write("stopScreensaverOverlay")
    m.overlayRefs.screensaverOverlay.callFunc("stopOverlay")

end sub

'-------------------------------------------------------------------------------
' recordScreensaverOverlayActivity
'-------------------------------------------------------------------------------
function recordScreensaverOverlayActivity() as boolean

    m.log.write("recordScreensaverOverlayActivity")

    if m.playbackState.complete = true then
        wasVisible = m.overlayRefs.screensaverOverlay.callFunc("isVisible")
        stopScreensaverOverlay()
        return wasVisible = true
    end if

    wasVisible = m.overlayRefs.screensaverOverlay.callFunc("recordActivity")
    return wasVisible = true

end function

'-------------------------------------------------------------------------------
' resetPlaybackSessionState
'-------------------------------------------------------------------------------
sub resetPlaybackSessionState()

    m.log.write("resetPlaybackSessionState")

    m.playbackContent.tracks = []
    m.playbackContent.chapterItems = []
    rebuildChapterStartPositions()
    m.timeline.currentTrackIndex = 0
    m.timeline.currentTrackStartPosition = 0
    m.timeline.pendingSeekSeconds = invalid
    m.playbackContext.session = invalid
    m.playbackContext.sessionId = invalid
    m.hlsRetry.isTranscode = false
    m.playbackState.complete = false
    m.hlsRetry.startupSeekTargetSeconds = invalid
    m.playbackSync.visualTargetSeconds = invalid
    m.playbackState.hasStarted = false
    updateAudioBadges(invalid)
    updateChapterMarkers()
    updateCurrentChapterStatus()
end sub

'-------------------------------------------------------------------------------
' resetPlaybackRetryState
'-------------------------------------------------------------------------------
sub resetPlaybackRetryState(resetFallbackAttempts = false as boolean)

    m.log.write("resetPlaybackRetryState")

    m.hlsRetry.count = 0
    m.hlsRetry.pending = false
    m.playbackState.hasStarted = false
    m.playbackState.visibleStatus = ""
    m.playbackContext.startTimeOverrideSeconds = invalid
    m.playbackState.isPaused = false

    if resetFallbackAttempts = true then
        m.hlsRetry.sessionRefreshTried = false
        m.hlsRetry.forceTranscodeFallbackTried = false
    end if
end sub

'-------------------------------------------------------------------------------
' resetPlaybackSyncState
'-------------------------------------------------------------------------------
sub resetPlaybackSyncState()

    m.log.write("resetPlaybackSyncState")

    m.playbackSync.startedAtSeconds = 0
    m.playbackSync.lastSyncAtSeconds = 0
    m.playbackSync.lastProgressTickAtSeconds = 0
    m.playbackSync.lastSyncedCurrentTimeSeconds = 0
    m.playbackSync.listeningTimeSinceSync = 0

end sub

'-------------------------------------------------------------------------------
' startPlaybackSyncState
'-------------------------------------------------------------------------------
sub startPlaybackSyncState()

    m.log.write("startPlaybackSyncState")
    m.playbackSync.startedAtSeconds = getNowSeconds()
    m.playbackSync.lastSyncAtSeconds = m.playbackSync.startedAtSeconds
    m.playbackSync.lastProgressTickAtSeconds = 0
    m.playbackSync.lastSyncedCurrentTimeSeconds = 0
    m.playbackSync.listeningTimeSinceSync = 0

end sub

'-------------------------------------------------------------------------------
' runPlaybackApiRequest
'-------------------------------------------------------------------------------
sub runPlaybackApiRequest(request as object)

    m.log.write("runPlaybackApiRequest")
    m.playbackRefs.playbackApiTask.request = request
    m.playbackRefs.playbackApiTask.control = "run"

end sub

'-------------------------------------------------------------------------------
' onPlaybackApiResponse
'-------------------------------------------------------------------------------
sub onPlaybackApiResponse()

    m.log.write("onPlaybackApiResponse")

    response = m.playbackRefs.playbackApiTask.response
    if response = invalid then return

    action = getTaskResponseAction(response)
    if action = "startPlayback" then
        if response.requestCounter <> invalid and response.requestCounter <> m.playbackContext.activeStartRequestCounter then return
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

    m.log.write("handleClosePlaybackSessionResponse")

    if response <> invalid and response.ok <> true then m.top.errorResponse = response
end sub

'-------------------------------------------------------------------------------
' getTaskResponseAction
'-------------------------------------------------------------------------------
function getTaskResponseAction(response as dynamic) as string

    m.log.write("getTaskResponseAction")

    if response <> invalid and response.action <> invalid then return response.action
    if m.playbackRefs.playbackApiTask <> invalid and m.playbackRefs.playbackApiTask.request <> invalid and m.playbackRefs.playbackApiTask.request.action <> invalid then
        return m.playbackRefs.playbackApiTask.request.action
    end if

    return ""
end function

'-------------------------------------------------------------------------------
' getCoverContent
'-------------------------------------------------------------------------------
function getCoverContent(request as dynamic) as dynamic

    m.log.write("getCoverContent")

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

    m.playbackContext.session = response.playbackSession
    m.playbackContext.sessionId = getPlaybackSessionId(response.playbackSession)
    if response.playbackSessionId <> invalid then m.playbackContext.sessionId = response.playbackSessionId
    m.hlsRetry.isTranscode = response.isHlsTranscode = true
    m.timeline.currentTimeSeconds = getStartPlaybackCurrentTime(response)
    if m.hlsRetry.isTranscode = true then m.log.write("HLS stream global start offset=0")
    m.timeline.totalDurationSeconds = getStartPlaybackDuration(response)
    updateTotalDuration()
    startPlaybackSyncState()
    playTracks(response.tracks, response.chapters)
end sub

'-------------------------------------------------------------------------------
' getStartPlaybackCurrentTime
'-------------------------------------------------------------------------------
function getStartPlaybackCurrentTime(response as dynamic) as integer

    m.log.write("getStartPlaybackCurrentTime")

    if m.playbackContext.startTimeOverrideSeconds <> invalid then
        return clampStartPlaybackTime(m.playbackContext.startTimeOverrideSeconds)
    end if

    return m.timeline.requestedStartPositionSeconds
end function

'-------------------------------------------------------------------------------
' clampStartPlaybackTime
'-------------------------------------------------------------------------------
function clampStartPlaybackTime(timeSeconds as dynamic) as integer

    m.log.write("clampStartPlaybackTime")

    startTime = int(val(timeSeconds.ToStr()))
    if startTime < 0 then return 0
    return startTime
end function

'-------------------------------------------------------------------------------
' getStartPlaybackDuration
'-------------------------------------------------------------------------------
function getStartPlaybackDuration(response as dynamic) as integer

    m.log.write("getStartPlaybackDuration")

    if response <> invalid and response.duration <> invalid then return int(val(response.duration.ToStr()))
    if response <> invalid and response.playbackSession <> invalid and response.playbackSession.duration <> invalid then return int(val(response.playbackSession.duration.ToStr()))
    return 0
end function

'-------------------------------------------------------------------------------
' getPlaybackSessionId
'-------------------------------------------------------------------------------
function getPlaybackSessionId(playbackSession as dynamic) as dynamic

    m.log.write("getPlaybackSessionId")

    if playbackSession = invalid then return invalid
    return playbackSession.id
end function

'-------------------------------------------------------------------------------
' updateDetails
'-------------------------------------------------------------------------------
sub updateDetails(details as dynamic)

    m.log.write("updateDetails")

    if details = invalid then details = {}

    description = FirstNonEmpty([details.description], "No description available.")

    if m.metadata <> invalid then
        m.metadata.authorText = "by " + FirstNonEmpty([details.authors], "Unknown")
        m.metadata.metadataText = getMetadataText(details)
        m.metadata.descriptionText = description
    end if
    m.timeline.totalDurationSeconds = 0
    updateTotalDuration()
    updateChapterMarkers()
end sub

'-------------------------------------------------------------------------------
' getMetadataText
'-------------------------------------------------------------------------------
function getMetadataText(details as dynamic) as string

    m.log.write("getMetadataText")

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

    m.log.write("getPublishedYear")

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

    m.log.write("isYearText")

    if Len(value) <> 4 then return false
    year = int(val(value))
    if year < 1000 or year > 9999 then return false
    return value = year.ToStr()
end function

' updateAudioBadgesForCurrentTrack
'-------------------------------------------------------------------------------
sub updateAudioBadgesForCurrentTrack()

    m.log.write("updateAudioBadgesForCurrentTrack")

    if m.playbackContent.tracks = invalid or m.timeline.currentTrackIndex < 0 or m.timeline.currentTrackIndex >= m.playbackContent.tracks.Count() then
        updateAudioBadges(invalid)
        return
    end if

    updateAudioBadges(m.playbackContent.tracks[m.timeline.currentTrackIndex])
end sub

'-------------------------------------------------------------------------------
' updateAudioBadges
'-------------------------------------------------------------------------------
sub updateAudioBadges(track as dynamic)

    m.log.write("updateAudioBadges")

    if m.audioBadges <> invalid then m.audioBadges.track = track
end sub

'-------------------------------------------------------------------------------
' playTracks
'-------------------------------------------------------------------------------
sub playTracks(tracks as dynamic, chapters as dynamic)

    m.log.write("playTracks")

    if m.playbackRefs.audioPlayer = invalid then return
    if tracks = invalid or tracks.Count() = 0 then
        setStatus("No playable audio tracks were returned.")
        return
    end if

    m.playbackContent.tracks = tracks
    m.playbackContent.chapterItems = PlaybackTrackTime_GetChapterItems(chapters, tracks)
    rebuildChapterStartPositions()
    m.timeline.currentTimeSeconds = clampGlobalTime(m.timeline.currentTimeSeconds)
    m.timeline.currentTrackIndex = getTrackIndexForGlobalTime(m.timeline.currentTimeSeconds)
    m.timeline.pendingSeekSeconds = getTrackSeekPosition(m.timeline.currentTrackIndex, m.timeline.currentTimeSeconds)
    updateChaptersButtonVisibility()
    updateChapterMarkers()
    updateChapterList()
    updateCurrentChapterStatus(m.timeline.currentTimeSeconds)
    playCurrentTrack()
end sub

'-------------------------------------------------------------------------------
' playCurrentTrack
'-------------------------------------------------------------------------------
sub playCurrentTrack(playWhenReady = true as boolean)

    m.log.write("playCurrentTrack")

    if m.playbackRefs.audioPlayer = invalid then return
    if m.playbackContent.tracks = invalid or m.timeline.currentTrackIndex < 0 or m.timeline.currentTrackIndex >= m.playbackContent.tracks.Count() then return

    track = m.playbackContent.tracks[m.timeline.currentTrackIndex]
    updateAudioBadges(track)
    node = CreateObject("roSGNode", "ContentNode")
    node.url = getTrackPlaybackUrl(track)
    node.title = SafeString(track.title, "Audiobook")
    node.streamFormat = PlaybackTrackTime_GetStreamFormat(track.mimeType, track.url)
    node.contentType = "audio"
    seekPosition = getInitialTrackSeekPosition()
    if seekPosition > 0 then
        if m.hlsRetry.isTranscode = true then
            node.PlayStart = seekPosition
            m.timeline.pendingSeekSeconds = invalid
            m.hlsRetry.startupSeekTargetSeconds = seekPosition
            m.log.write("HLS initial PlayStart=" + seekPosition.ToStr())
        else
            node.PlayStart = seekPosition
            m.timeline.pendingSeekSeconds = invalid
        end if
    else
        m.timeline.pendingSeekSeconds = invalid
        if m.hlsRetry.isTranscode = true then m.hlsRetry.startupSeekTargetSeconds = invalid
    end if

    m.log.write("track index=" + m.timeline.currentTrackIndex.ToStr() + " format=" + SafeString(node.streamFormat) + " url=" + SafeString(node.url))

    m.timeline.currentTrackStartPosition = PlaybackTrackTime_GetTrackStartPosition(track)
    if m.timeline.currentTimeSeconds > 0 then
        setPlaybackVisualTarget(m.timeline.currentTimeSeconds)
    else
        m.playbackSync.visualTargetSeconds = invalid
    end if

    updateTotalDuration()
    updateProgress(m.timeline.currentTimeSeconds, true)
    updateChapterList()
    updateCurrentChapterStatus(m.timeline.currentTimeSeconds)

    m.playbackRefs.audioPlayer.control = "stop"
    m.playbackRefs.audioPlayer.content = node
    m.playbackState.isPaused = (playWhenReady <> true)
    disableScreenSaver()
    if playWhenReady then
        restartScreensaverOverlayDelay()
        m.playbackRefs.audioPlayer.control = "play"
        if m.playbackState.hasStarted = true then setStatus("Playing")
    else
        m.playbackRefs.audioPlayer.control = "pause"
        setStatus("Paused")
    end if
    updatePlayPauseButton()
end sub

'-------------------------------------------------------------------------------
' getRequestStartPosition
'-------------------------------------------------------------------------------
function getRequestStartPosition(request as dynamic) as integer

    m.log.write("getRequestStartPosition")

    if request = invalid or request.startPositionSeconds = invalid then return 0
    startPosition = int(val(request.startPositionSeconds.ToStr()))
    if startPosition < 0 then return 0
    return startPosition
end function

'-------------------------------------------------------------------------------
' clampGlobalTime
'-------------------------------------------------------------------------------
function clampGlobalTime(timeSeconds as dynamic) as integer

    m.log.write("clampGlobalTime")

    return PlaybackTrackTime_ClampGlobalTime(timeSeconds, getPlaybackDurationSeconds())
end function

'-------------------------------------------------------------------------------
' getTrackIndexForGlobalTime
'-------------------------------------------------------------------------------
function getTrackIndexForGlobalTime(timeSeconds as dynamic) as integer

    m.log.write("getTrackIndexForGlobalTime")

    return PlaybackTrackTime_GetTrackIndexForGlobalTime(m.playbackContent.tracks, timeSeconds, getPlaybackDurationSeconds(), m.hlsRetry.isTranscode)
end function

'-------------------------------------------------------------------------------
' getTrackSeekPosition
'-------------------------------------------------------------------------------
function getTrackSeekPosition(trackIndex as integer, globalTime as dynamic) as integer

    m.log.write("getTrackSeekPosition")

    return PlaybackTrackTime_GetTrackSeekPosition(m.playbackContent.tracks, trackIndex, globalTime, getPlaybackDurationSeconds(), m.hlsRetry.isTranscode)
end function

'-------------------------------------------------------------------------------
' seekToGlobalTime
'-------------------------------------------------------------------------------
sub seekToGlobalTime(globalTime as dynamic, playWhenReady = true as boolean, shouldSync = true as boolean)

    m.log.write("seekToGlobalTime")

    if m.playbackRefs.audioPlayer = invalid then return
    if m.playbackContent.tracks = invalid or m.playbackContent.tracks.Count() = 0 then return

    targetTime = clampGlobalTime(globalTime)
    setPlaybackVisualTarget(targetTime)
    targetTrackIndex = getTrackIndexForGlobalTime(targetTime)
    m.timeline.currentTimeSeconds = targetTime

    if targetTrackIndex <> m.timeline.currentTrackIndex then
        m.timeline.currentTrackIndex = targetTrackIndex
        m.timeline.pendingSeekSeconds = getTrackSeekPosition(m.timeline.currentTrackIndex, targetTime)
        playCurrentTrack(playWhenReady)
    else
        seekPosition = getTrackSeekPosition(m.timeline.currentTrackIndex, targetTime)
        m.playbackRefs.audioPlayer.seek = seekPosition
        if playWhenReady = true then
            restartScreensaverOverlayDelay()
            if m.playbackRefs.audioPlayer.state = "paused" then
                m.playbackRefs.audioPlayer.control = "resume"
            else if m.playbackRefs.audioPlayer.state = "finished" then
                m.playbackRefs.audioPlayer.control = "play"
            end if
        end if
        if playWhenReady = false and m.playbackRefs.audioPlayer.state = "playing" then m.playbackRefs.audioPlayer.control = "pause"
    end if

    updatePlaybackPosition(targetTime)
    updateChapterList()
    updateCurrentChapterStatus(targetTime)
    if shouldSync then requestSyncPlaybackSession("seek", targetTime)
end sub

'-------------------------------------------------------------------------------
' updatePlaybackPosition
'-------------------------------------------------------------------------------
sub updatePlaybackPosition(globalTime as dynamic)

    m.log.write("updatePlaybackPosition")

    m.timeline.currentTimeSeconds = clampGlobalTime(globalTime)
    if m.playbackContent.tracks = invalid or m.playbackContent.tracks.Count() = 0 then
        updateProgress(m.timeline.currentTimeSeconds)
        updateAudioBadges(invalid)
        return
    end if
    updateProgress(m.timeline.currentTimeSeconds)
    updateAudioBadgesForCurrentTrack()
    updateCurrentChapterStatus(m.timeline.currentTimeSeconds)
end sub

'-------------------------------------------------------------------------------
' getInitialTrackSeekPosition
'-------------------------------------------------------------------------------
function getInitialTrackSeekPosition() as integer

    m.log.write("getInitialTrackSeekPosition")

    if m.timeline.pendingSeekSeconds <> invalid then return int(val(m.timeline.pendingSeekSeconds.ToStr()))
    return getTrackSeekPosition(m.timeline.currentTrackIndex, m.timeline.currentTimeSeconds)
end function

' onAudioStateChanged
'-------------------------------------------------------------------------------
sub onAudioStateChanged()

    m.log.write("onAudioStateChanged")

    if m.playbackRefs.audioPlayer = invalid then return

    state = SafeString(m.playbackRefs.audioPlayer.state, "")

    '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    ' playing
    '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    if state = "playing" then
        restartScreensaverOverlayDelay()
        hasUnsettledHlsStartupSeek = (m.hlsRetry.isTranscode = true and (m.timeline.pendingSeekSeconds <> invalid or m.hlsRetry.startupSeekTargetSeconds <> invalid))
        if hasUnsettledHlsStartupSeek <> true then m.hlsRetry.count = 0
        m.hlsRetry.pending = false
        m.playbackState.hasStarted = true
        m.playbackState.isPaused = false
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
        if m.timeline.pendingSeekSeconds <> invalid and m.hlsRetry.isTranscode <> true then
            applyPendingInitialSeek()
            m.playbackRefs.audioPlayer.control = "play"
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
            m.playbackState.isPaused = false
            updatePlayPauseButton()
            return
        end if

        handlePlaybackComplete()
    else if state = "error" then
        logPlaybackError("Roku media node entered error state.")
        if restartWithTranscodeFallback("media-error") then return
        if scheduleHlsStartupRetry("media-error") then return
        if refreshHlsPlaybackSession("media-error") then return

        stopProgressTimer()
        enableScreenSaver()
        setStatus("Playback error.")
        m.playbackState.isPaused = false
        updatePlayPauseButton()
    end if
end sub

'-------------------------------------------------------------------------------
' handlePlaybackComplete
'-------------------------------------------------------------------------------
sub handlePlaybackComplete()

    m.log.write("handlePlaybackComplete")

    if m.playbackState.complete = true then return

    m.playbackState.complete = true
    stopProgressTimer()
    stopScreensaverOverlay()
    enableScreenSaver()
    updateProgress(m.timeline.totalDurationSeconds, true)
    setStatus("Finished")
    m.playbackState.isPaused = false
    updatePlayPauseButton()
end sub

'-------------------------------------------------------------------------------
' restartWithTranscodeFallback
'-------------------------------------------------------------------------------
function restartWithTranscodeFallback(reason as string) as boolean

    m.log.write("restartWithTranscodeFallback")

    if m.isClosing = true then return false
    if m.hlsRetry.isTranscode = true then return false
    if m.hlsRetry.forceTranscodeFallbackTried = true then return false

    m.hlsRetry.forceTranscodeFallbackTried = true
    restartPlaybackSession(true, "direct-play-fallback-" + reason)
    return true
end function

'-------------------------------------------------------------------------------
' refreshHlsPlaybackSession
'-------------------------------------------------------------------------------
function refreshHlsPlaybackSession(reason as string) as boolean

    m.log.write("refreshHlsPlaybackSession")

    if m.isClosing = true then return false
    if m.hlsRetry.isTranscode <> true then return false
    if m.hlsRetry.sessionRefreshTried = true then return false

    m.hlsRetry.sessionRefreshTried = true
    restartPlaybackSession(true, "hls-session-refresh-" + reason)
    return true
end function

'-------------------------------------------------------------------------------
' restartPlaybackSession
'-------------------------------------------------------------------------------
sub restartPlaybackSession(forceTranscode as boolean, reason as string)

    m.log.write("restartPlaybackSession")

    currentTime = getPlaybackCurrentTimeSeconds()
    m.log.write("Restarting playback session reason=" + reason + " currentTime=" + currentTime.ToStr() + " forceTranscode=" + forceTranscode.ToStr())

    resetMediaNodeForNewPlayback()
    resetPlaybackSessionState()
    resetPlaybackRetryState(false)
    m.timeline.currentTimeSeconds = currentTime
    m.timeline.requestedStartPositionSeconds = currentTime
    setStatus("Starting playback...")
    requestStartPlaybackSession(forceTranscode, currentTime)
end sub

'-------------------------------------------------------------------------------
' scheduleHlsStartupRetry
'-------------------------------------------------------------------------------
function scheduleHlsStartupRetry(reason as string) as boolean

    m.log.write("scheduleHlsStartupRetry")

    if m.isClosing = true then return false
    if m.hlsRetry.isTranscode <> true then return false
    if m.hlsRetry.pending = true then return true
    retryMax = getHlsRetryMax()
    if m.hlsRetry.count >= retryMax then return false

    m.hlsRetry.count = m.hlsRetry.count + 1
    m.hlsRetry.pending = true
    stopProgressTimer()
    m.log.write("HLS startup retry " + m.hlsRetry.count.ToStr() + "/" + retryMax.ToStr() + " reason=" + reason + " currentTime=" + m.timeline.currentTimeSeconds.ToStr())

    if m.playbackRefs.audioPlayer <> invalid then m.playbackRefs.audioPlayer.control = "stop"
    if m.timerRefs.hlsRetryTimer <> invalid then
        m.timerRefs.hlsRetryTimer.control = "stop"
        m.timerRefs.hlsRetryTimer.control = "start"
    else
        retryHlsPlayback()
    end if

    return true
end function

'-------------------------------------------------------------------------------
' getHlsRetryMax
'-------------------------------------------------------------------------------
function getHlsRetryMax() as integer

    m.log.write("getHlsRetryMax")

    if m.hlsRetry.startupSeekTargetSeconds <> invalid then return m.hlsRetry.resumeMax
    return m.hlsRetry.max
end function

'-------------------------------------------------------------------------------
' onHlsRetryTimerFired
'-------------------------------------------------------------------------------
sub onHlsRetryTimerFired()

    m.log.write("onHlsRetryTimerFired")

    retryHlsPlayback()
end sub

'-------------------------------------------------------------------------------
' retryHlsPlayback
'-------------------------------------------------------------------------------
sub retryHlsPlayback()

    m.log.write("retryHlsPlayback")

    if m.isClosing = true then return
    if m.playbackContent.tracks = invalid or m.playbackContent.tracks.Count() = 0 then return

    m.hlsRetry.pending = false
    m.timeline.pendingSeekSeconds = getTrackSeekPosition(m.timeline.currentTrackIndex, m.timeline.currentTimeSeconds)
    playCurrentTrack(true)
end sub

'-------------------------------------------------------------------------------
' getTrackPlaybackUrl
'-------------------------------------------------------------------------------
function getTrackPlaybackUrl(track as dynamic) as string

    m.log.write("getTrackPlaybackUrl")

    url = SafeString(track.url, "")
    if m.hlsRetry.isTranscode <> true then return url
    if m.hlsRetry.count <= 0 then return url

    separator = "?"
    if Instr(1, url, "?") > 0 then separator = "&"
    return url + separator + "abstvRetry=" + m.hlsRetry.count.ToStr()
end function

'-------------------------------------------------------------------------------
' applyPendingInitialSeek
'-------------------------------------------------------------------------------
sub applyPendingInitialSeek()

    m.log.write("applyPendingInitialSeek")

    if m.playbackRefs.audioPlayer = invalid then return
    if m.timeline.pendingSeekSeconds = invalid then return

    seekPosition = int(val(m.timeline.pendingSeekSeconds.ToStr()))
    m.timeline.pendingSeekSeconds = invalid
    m.playbackRefs.audioPlayer.seek = seekPosition
    m.log.write("applied pending seek=" + seekPosition.ToStr() + " state=" + SafeString(m.playbackRefs.audioPlayer.state, ""))
end sub

'-------------------------------------------------------------------------------
' playNextTrack
'-------------------------------------------------------------------------------
function playNextTrack() as boolean

    m.log.write("playNextTrack")

    if m.playbackContent.tracks = invalid then return false
    if m.hlsRetry.isTranscode = true then return false
    nextIndex = m.timeline.currentTrackIndex + 1
    if nextIndex >= m.playbackContent.tracks.Count() then return false

    m.timeline.currentTrackIndex = nextIndex
    m.timeline.currentTimeSeconds = PlaybackTrackTime_GetTrackStartPosition(m.playbackContent.tracks[m.timeline.currentTrackIndex])
    requestSyncPlaybackSession("trackChange", m.timeline.currentTimeSeconds)
    m.timeline.pendingSeekSeconds = 0
    playCurrentTrack()
    return true
end function

'-------------------------------------------------------------------------------
' isPlaybackNearEnd
'-------------------------------------------------------------------------------
function isPlaybackNearEnd() as boolean

    m.log.write("isPlaybackNearEnd")

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

    m.log.write("logPlaybackError")

    if m.log = invalid then return

    errorText = message
    if m.playbackRefs.audioPlayer <> invalid then
        errorText = errorText + " state=" + SafeString(m.playbackRefs.audioPlayer.state, "")
        errorText = errorText + " errorCode=" + SafeString(m.playbackRefs.audioPlayer.errorCode, "invalid")
        errorText = errorText + " errorMsg=" + SafeString(m.playbackRefs.audioPlayer.errorMsg, "invalid")
        errorText = errorText + " errorStr=" + SafeString(m.playbackRefs.audioPlayer.errorStr, "invalid")
    end if

    m.log.error(errorText)
end sub

'-------------------------------------------------------------------------------
' setStatus
'-------------------------------------------------------------------------------
sub setStatus(status as string)

    m.log.write("setStatus")

    m.playbackState.visibleStatus = status
    if m.playbackControls <> invalid then m.playbackControls.statusText = status
end sub

'-------------------------------------------------------------------------------
' disableScreenSaver
'-------------------------------------------------------------------------------
sub disableScreenSaver()

    m.log.write("disableScreenSaver")

    if m.playbackRefs.audioPlayer <> invalid then m.playbackRefs.audioPlayer.disableScreenSaver = true
end sub

'-------------------------------------------------------------------------------
' enableScreenSaver
'-------------------------------------------------------------------------------
sub enableScreenSaver()

    m.log.write("enableScreenSaver")

    if m.playbackRefs.audioPlayer <> invalid then m.playbackRefs.audioPlayer.disableScreenSaver = false
end sub

'-------------------------------------------------------------------------------
' closePlayer
'-------------------------------------------------------------------------------
sub closePlayer()

    m.log.write("closePlayer")

    if m.isClosing = true then return
    m.isClosing = true

    accumulatePlaybackListeningTime()
    stopScreensaverOverlay()
    requestClosePlaybackSession()
    cancelProgressScrub()
    stopProgressTimer()
    enableScreenSaver()
    closeChapterList()
    setStatus("Stopping...")

    if m.playbackRefs.audioPlayer <> invalid then m.playbackRefs.audioPlayer.control = "stop"

    if m.timerRefs.closeTimer <> invalid then
        m.timerRefs.closeTimer.control = "start"
    else
        finalizeClosePlayer()
    end if
end sub

'-------------------------------------------------------------------------------
' onCloseTimerFired
'-------------------------------------------------------------------------------
sub onCloseTimerFired()

    m.log.write("onCloseTimerFired")

    finalizeClosePlayer()
end sub

'-------------------------------------------------------------------------------
' finalizeClosePlayer
'-------------------------------------------------------------------------------
sub finalizeClosePlayer()

    m.log.write("finalizeClosePlayer")

    stopScreensaverOverlay()

    if m.playbackRefs.audioPlayer <> invalid then
        m.playbackRefs.audioPlayer.control = "stop"
        m.playbackRefs.audioPlayer.content = invalid
    end if

    resetPlaybackSessionState()
    resetPlaybackRetryState(true)
    resetPlaybackSyncState()
    m.timeline.currentTimeSeconds = 0
    resetProgress()
    updateChaptersButtonVisibility()
    m.closeRequestedCounter = m.closeRequestedCounter + 1
    m.top.closeRequested = m.closeRequestedCounter
end sub

'-------------------------------------------------------------------------------
' requestClosePlaybackSession
'-------------------------------------------------------------------------------
sub requestClosePlaybackSession()

    m.log.write("requestClosePlaybackSession")

    request = buildPlaybackSessionRequest("closePlaybackSession")
    if request <> invalid then runPlaybackApiRequest(request)
end sub

'-------------------------------------------------------------------------------
' requestSyncPlaybackSession
'-------------------------------------------------------------------------------
sub requestSyncPlaybackSession(reason = "" as string, currentTimeOverride = invalid as dynamic)

    m.log.write("requestSyncPlaybackSession")

    request = buildPlaybackSessionRequest("syncPlaybackSession", currentTimeOverride)
    if request = invalid then return

    if reason <> "" then request.reason = reason
    if request.currentTime <> invalid then m.playbackSync.lastSyncedCurrentTimeSeconds = int(val(request.currentTime.ToStr()))
    m.playbackSync.listeningTimeSinceSync = 0
    m.playbackSync.lastSyncAtSeconds = getNowSeconds()
    runPlaybackApiRequest(request)
end sub

'-------------------------------------------------------------------------------
' buildPlaybackSessionRequest
'-------------------------------------------------------------------------------
function buildPlaybackSessionRequest(action as string, currentTimeOverride = invalid as dynamic) as dynamic

    m.log.write("buildPlaybackSessionRequest")

    if m.playbackContext.sessionId = invalid or m.playbackContext.sessionId = "" then return invalid
    if m.playbackContext.server = invalid or m.playbackContext.server = "" then return invalid
    if m.playbackContext.token = invalid or m.playbackContext.token = "" then return invalid

    currentTime = getPlaybackCurrentTimeSeconds()
    if currentTimeOverride <> invalid then currentTime = int(val(currentTimeOverride.ToStr()))
    timeListened = getPlaybackTimeListenedSeconds()

    request = {
        action: action
        server: m.playbackContext.server
        token: m.playbackContext.token
        sessionId: m.playbackContext.sessionId
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

    m.log.write("shouldSendPlaybackProgressData")

    if action <> "closePlaybackSession" then return true
    if m.playbackSync.lastSyncedCurrentTimeSeconds > 0 then return timeListened >= m.playbackSync.config.syncIntervalSeconds
    return timeListened >= m.playbackSync.config.closeProgressSaveThresholdSeconds
end function

'-------------------------------------------------------------------------------
' onKeyEvent
'-------------------------------------------------------------------------------
function onKeyEvent(key as string, press as boolean) as boolean

    m.log.write("onKeyEvent")

    if press = false then return false

    if recordScreensaverOverlayActivity() then return true

    if m.overlayRefs.nightModeTint <> invalid and m.overlayRefs.nightModeTint.visible = true then
        m.overlayRefs.nightModeTint.visible = false
        return true
    end if

    if m.progressScrub.isActive = true then
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
            commitProgressScrub("controls")
            return true
        else if key = "down" then
            commitProgressScrub("controls")
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

    if m.metadata <> invalid and m.metadata.callFunc("descriptionHasFocus") then
        if key = "down" then
            focusProgressBar(0)
            return true
        end if
    end if

    if isPlaybackControlsFocused() then
        if key = "up" then
            focusProgressBar(getPlaybackControlFocusIndex())
            return true
        end if

        if m.playbackControls <> invalid then return m.playbackControls.callFunc("handleKey", key)
    end if

    if key = "down" then
        focusPlaybackButton(0)
        return true
    end if

    if key = "play" or key = "OK" or key = "select" then
        togglePlayPause()
        return true
    end if

    return false
end function

'-------------------------------------------------------------------------------
' focusDescriptionFromPlaybackControls
'-------------------------------------------------------------------------------
function focusDescriptionFromPlaybackControls() as boolean

    m.log.write("focusDescriptionFromPlaybackControls")

    if m.metadata = invalid then return false
    if m.metadata.callFunc("canFocusDescription") <> true then return false

    updatePlaybackControlsFocus(-1)
    return m.metadata.callFunc("focusDescription")
end function

'-------------------------------------------------------------------------------
' focusProgressBar
'-------------------------------------------------------------------------------
sub focusProgressBar(returnFocusIndex as integer)

    m.log.write("focusProgressBar")

    if m.playbackControls = invalid then return

    if returnFocusIndex < 0 then returnFocusIndex = 0
    playbackButtonCount = getPlaybackButtonCount()
    if returnFocusIndex >= playbackButtonCount then returnFocusIndex = playbackButtonCount - 1
    if returnFocusIndex < 0 then returnFocusIndex = 0

    m.progressScrub.isActive = true
    m.progressScrub.returnFocusIndex = returnFocusIndex
    m.progressScrub.targetSeconds = getPlaybackCurrentTimeSeconds()

    updatePlayPauseButton()
    updatePlaybackControlsFocus(-1)
    updateProgressScrubPreview()
    m.playbackControls.callFunc("focusProgress")
end sub

'-------------------------------------------------------------------------------
' jogProgressScrub
'-------------------------------------------------------------------------------
sub jogProgressScrub(offsetSeconds as integer)

    m.log.write("jogProgressScrub")

    if m.progressScrub.isActive <> true then return

    m.progressScrub.targetSeconds = m.progressScrub.targetSeconds + offsetSeconds
    updateProgressScrubPreview()
    seekToGlobalTime(m.progressScrub.targetSeconds, true, true)
    m.playbackState.isPaused = false
    disableScreenSaver()
    startProgressTimer()
    setStatus("Playing")
    updatePlayPauseButton()
end sub

'-------------------------------------------------------------------------------
' updateProgressScrubPreview
'-------------------------------------------------------------------------------
sub updateProgressScrubPreview()

    m.log.write("updateProgressScrubPreview")

    targetPosition = clampGlobalTime(m.progressScrub.targetSeconds)
    m.progressScrub.targetSeconds = targetPosition

    updateProgress(targetPosition, true)
    if m.playbackControls <> invalid then m.playbackControls.callFunc("showScrubPreview", targetPosition)
end sub

'-------------------------------------------------------------------------------
' commitProgressScrub
'-------------------------------------------------------------------------------
sub commitProgressScrub(nextFocus as string)

    m.log.write("commitProgressScrub")

    if m.progressScrub.isActive <> true then return

    exitProgressScrub(nextFocus)
end sub

'-------------------------------------------------------------------------------
' exitProgressScrub
'-------------------------------------------------------------------------------
sub exitProgressScrub(nextFocus as string)

    m.log.write("exitProgressScrub")

    m.progressScrub.isActive = false
    if m.playbackControls <> invalid then m.playbackControls.callFunc("hideScrubPreview")
    updateProgress(getPlaybackCurrentTimeSeconds(), true)
    updatePlayPauseButton()

    if nextFocus = "description" and focusDescriptionFromPlaybackControls() then return
    focusPlaybackButton(m.progressScrub.returnFocusIndex)
end sub

'-------------------------------------------------------------------------------
' cancelProgressScrub
'-------------------------------------------------------------------------------
sub cancelProgressScrub()

    m.log.write("cancelProgressScrub")

    if m.progressScrub.isActive <> true then return

    m.progressScrub.isActive = false
    if m.playbackControls <> invalid then m.playbackControls.callFunc("hideScrubPreview")
    updateProgress(getPlaybackCurrentTimeSeconds(), true)
    updatePlayPauseButton()
end sub

' focusPlaybackButton
'-------------------------------------------------------------------------------
sub focusPlaybackButton(index as integer)

    m.log.write("focusPlaybackButton")

    if index < 0 then index = 0
    playbackButtonCount = getPlaybackButtonCount()
    if index >= playbackButtonCount then index = playbackButtonCount - 1
    updatePlaybackControlsFocus(index)

    if m.playbackControls <> invalid then m.playbackControls.callFunc("focusButton", index)
end sub

'-------------------------------------------------------------------------------
' updatePlaybackControlsFocus
'-------------------------------------------------------------------------------
sub updatePlaybackControlsFocus(index as integer)

    m.log.write("updatePlaybackControlsFocus")

    if m.playbackControls = invalid then return

    if index < 0 then
        m.playbackControls.callFunc("clearFocus")
    else
        m.playbackControls.callFunc("focusButton", index)
    end if
end sub

'-------------------------------------------------------------------------------
' getPlaybackButtonCount
'-------------------------------------------------------------------------------
function getPlaybackButtonCount() as integer

    m.log.write("getPlaybackButtonCount")

    if m.playbackControls <> invalid then return m.playbackControls.callFunc("getButtonCount")
    return 3
end function

'-------------------------------------------------------------------------------
' isPlaybackControlsFocused
'-------------------------------------------------------------------------------
function isPlaybackControlsFocused() as boolean

    m.log.write("isPlaybackControlsFocused")

    return m.playbackControls <> invalid and m.playbackControls.isInFocusChain()
end function

'-------------------------------------------------------------------------------
' getPlaybackControlFocusIndex
'-------------------------------------------------------------------------------
function getPlaybackControlFocusIndex() as integer

    m.log.write("getPlaybackControlFocusIndex")

    if m.playbackControls = invalid then return -1
    if m.playbackControls.focusedIndex = invalid then return -1

    return m.playbackControls.focusedIndex
end function

'-------------------------------------------------------------------------------
' onPlaybackActionSelected
'-------------------------------------------------------------------------------
sub onPlaybackActionSelected()

    m.log.write("onPlaybackActionSelected")

    if m.playbackControls = invalid then return
    selection = m.playbackControls.selectedAction
    if selection = invalid or selection.action = invalid then return

    activatePlaybackControlAction(selection.action)
end sub

'-------------------------------------------------------------------------------
' onPlaybackControlsFocusUpRequested
'-------------------------------------------------------------------------------
sub onPlaybackControlsFocusUpRequested()

    m.log.write("onPlaybackControlsFocusUpRequested")

    focusProgressBar(getPlaybackControlFocusIndex())
end sub

'-------------------------------------------------------------------------------
' activatePlaybackControlAction
'-------------------------------------------------------------------------------
sub activatePlaybackControlAction(action as string)

    m.log.write("activatePlaybackControlAction")

    if action = "playPause" then
        togglePlayPause()
    else if action = "restart" then
        restartPlayback()
    else if action = "tint" then
        toggleNightModeTint()
    else if action = "chapters" then
        openChapterList()
    end if
end sub

' toggleNightModeTint
'-------------------------------------------------------------------------------
sub toggleNightModeTint()

    m.log.write("toggleNightModeTint")

    if m.overlayRefs.nightModeTint = invalid then return

    m.overlayRefs.nightModeTint.visible = not m.overlayRefs.nightModeTint.visible
end sub

'-------------------------------------------------------------------------------
' hideNightModeTint
'-------------------------------------------------------------------------------
sub hideNightModeTint()

    m.log.write("hideNightModeTint")

    if m.overlayRefs.nightModeTint <> invalid then m.overlayRefs.nightModeTint.visible = false
end sub

'-------------------------------------------------------------------------------
' restartPlayback
'-------------------------------------------------------------------------------
sub restartPlayback()

    m.log.write("restartPlayback")

    if m.playbackRefs.audioPlayer = invalid then return
    if m.playbackContent.tracks = invalid or m.playbackContent.tracks.Count() = 0 then return

    seekToGlobalTime(0, true, true)
    m.playbackState.isPaused = false
    disableScreenSaver()
    startProgressTimer()
    setStatus("Playing")
    updatePlayPauseButton()
end sub

'-------------------------------------------------------------------------------
' updateChaptersButtonVisibility
'-------------------------------------------------------------------------------
sub updateChaptersButtonVisibility()

    m.log.write("updateChaptersButtonVisibility")

    hasMultipleTracks = (m.playbackContent.chapterItems <> invalid and m.playbackContent.chapterItems.Count() > 1)
    if m.playbackControls <> invalid then m.playbackControls.showChapters = hasMultipleTracks

    if hasMultipleTracks = false and getPlaybackControlFocusIndex() > 2 then updatePlaybackControlsFocus(2)
end sub

'-------------------------------------------------------------------------------
' rebuildChapterStartPositions
'-------------------------------------------------------------------------------
sub rebuildChapterStartPositions()

    m.log.write("rebuildChapterStartPositions")

    positions = []
    if m.playbackContent.chapterItems <> invalid and m.playbackContent.chapterItems.Count() > 0 then
        for each chapter in m.playbackContent.chapterItems
            positions.Push(getChapterStartPosition(chapter))
        end for
    end if

    m.chapterStatus.startPositions = positions
end sub

' updateChapterMarkers
'-------------------------------------------------------------------------------
sub updateChapterMarkers()

    m.log.write("updateChapterMarkers")

    positions = []
    if m.playbackContent.chapterItems <> invalid and m.playbackContent.chapterItems.Count() > 1 then
        for i = 0 to m.playbackContent.chapterItems.Count() - 1
            chapterPosition = 0
            if m.chapterStatus.startPositions <> invalid and i < m.chapterStatus.startPositions.Count() then chapterPosition = m.chapterStatus.startPositions[i]
            if chapterPosition < 0 then chapterPosition = 0
            if m.timeline.totalDurationSeconds > 0 and chapterPosition > m.timeline.totalDurationSeconds then chapterPosition = m.timeline.totalDurationSeconds
            positions.Push(chapterPosition)
        end for
    end if

    if m.playbackControls <> invalid then m.playbackControls.chapterMarkerPositions = positions
end sub

'-------------------------------------------------------------------------------
' openChapterList
'-------------------------------------------------------------------------------
sub openChapterList()

    m.log.write("openChapterList")

    if m.dialogRefs.chapterList = invalid then return
    if m.playbackContent.chapterItems = invalid or m.playbackContent.chapterItems.Count() <= 1 then return

    updateChapterList()
    m.dialogRefs.chapterList.callFunc("open")
end sub

'-------------------------------------------------------------------------------
' closeChapterList
'-------------------------------------------------------------------------------
sub closeChapterList()

    m.log.write("closeChapterList")

    if m.dialogRefs.chapterList <> invalid then m.dialogRefs.chapterList.callFunc("close")
end sub

'-------------------------------------------------------------------------------
' updateChapterList
'-------------------------------------------------------------------------------
sub updateChapterList()

    m.log.write("updateChapterList")

    if m.dialogRefs.chapterList = invalid then return

    m.dialogRefs.chapterList.tracks = m.playbackContent.chapterItems
    m.dialogRefs.chapterList.currentTrackIndex = getCurrentChapterIndex()
    m.dialogRefs.chapterList.audiobookTitle = m.playbackContent.audiobookTitle
    updateCurrentChapterStatus()
end sub

'-------------------------------------------------------------------------------
' updateCurrentChapterStatus
'-------------------------------------------------------------------------------
sub updateCurrentChapterStatus(currentTime = invalid as dynamic)

    m.log.write("updateCurrentChapterStatus")

    if m.chapterStatus.deferUpdates = true then
        m.chapterStatus.pendingUpdate = true
        return
    end if

    title = ""
    if m.playbackContent.chapterItems <> invalid and m.playbackContent.chapterItems.Count() > 1 then
        index = getCurrentChapterIndex(currentTime)
        if index >= 0 and index < m.playbackContent.chapterItems.Count() then
            chapter = m.playbackContent.chapterItems[index]
            if chapter <> invalid then title = SafeString(chapter.title, "")
        end if
    end if

    if m.playbackControls <> invalid then m.playbackControls.trackTitle = title
end sub

'-------------------------------------------------------------------------------
' beginChapterStatusUpdateBatch
'-------------------------------------------------------------------------------
sub beginChapterStatusUpdateBatch()

    m.log.write("beginChapterStatusUpdateBatch")

    m.chapterStatus.deferUpdates = true
    m.chapterStatus.pendingUpdate = false
end sub

'-------------------------------------------------------------------------------
' endChapterStatusUpdateBatch
'-------------------------------------------------------------------------------
sub endChapterStatusUpdateBatch()

    m.log.write("endChapterStatusUpdateBatch")

    pendingUpdate = (m.chapterStatus.pendingUpdate = true)
    m.chapterStatus.deferUpdates = false
    m.chapterStatus.pendingUpdate = false

    if pendingUpdate = true then updateCurrentChapterStatus()
end sub

'-------------------------------------------------------------------------------
' onChapterListClosed
'-------------------------------------------------------------------------------
sub onChapterListClosed()

    m.log.write("onChapterListClosed")

    focusChaptersButton()
end sub

'-------------------------------------------------------------------------------
' focusChaptersButton
'-------------------------------------------------------------------------------
sub focusChaptersButton()

    m.log.write("focusChaptersButton")

    if m.playbackControls <> invalid and m.playbackControls.showChapters = true then updatePlaybackControlsFocus(3)
end sub

'-------------------------------------------------------------------------------
' onChapterSelected
'-------------------------------------------------------------------------------
sub onChapterSelected()

    m.log.write("onChapterSelected")

    if m.dialogRefs.chapterList = invalid then return

    selection = m.dialogRefs.chapterList.selectedChapter
    if selection = invalid or selection.index = invalid then return

    index = selection.index
    if m.playbackContent.chapterItems = invalid then return
    if index < 0 or index >= m.playbackContent.chapterItems.Count() then return

    focusChaptersButton()

    stopProgressTimer()
    chapterPosition = 0
    if m.chapterStatus.startPositions <> invalid and index < m.chapterStatus.startPositions.Count() then chapterPosition = m.chapterStatus.startPositions[index]
    beginChapterStatusUpdateBatch()
    seekToGlobalTime(chapterPosition, m.playbackState.isPaused <> true, true)
    endChapterStatusUpdateBatch()
end sub

'-------------------------------------------------------------------------------
' getCurrentChapterIndex
'-------------------------------------------------------------------------------
function getCurrentChapterIndex(currentTime = invalid as dynamic) as integer

    m.log.write("getCurrentChapterIndex")

    if m.playbackContent.chapterItems = invalid or m.playbackContent.chapterItems.Count() = 0 then return 0

    currentIndex = 0
    if currentTime = invalid then currentTime = getPlaybackCurrentTimeSeconds()
    currentTime = clampGlobalTime(currentTime)
    for i = 0 to m.playbackContent.chapterItems.Count() - 1
        chapterPosition = 0
        if m.chapterStatus.startPositions <> invalid and i < m.chapterStatus.startPositions.Count() then chapterPosition = m.chapterStatus.startPositions[i]
        if currentTime >= chapterPosition then currentIndex = i
    end for

    return currentIndex
end function

'-------------------------------------------------------------------------------
' getChapterStartPosition
'-------------------------------------------------------------------------------
function getChapterStartPosition(chapter as dynamic) as integer

    m.log.write("getChapterStartPosition")

    if chapter = invalid then return 0
    if chapter.startOffset <> invalid then return int(val(chapter.startOffset.ToStr()))
    return 0
end function

'-------------------------------------------------------------------------------
' togglePlayPause
'-------------------------------------------------------------------------------
sub togglePlayPause()

    m.log.write("togglePlayPause")

    if m.playbackRefs.audioPlayer = invalid then return

    if m.playbackState.isPaused <> true and m.playbackRefs.audioPlayer.state = "playing" then
        m.playbackRefs.audioPlayer.control = "pause"
        m.playbackState.isPaused = true
        stopProgressTimer()
        enableScreenSaver()
        updateProgress(getPlaybackCurrentTimeSeconds())
        requestSyncPlaybackSession("pause")
        setStatus("Paused")
    else
        m.playbackState.isPaused = false
        restartScreensaverOverlayDelay()
        disableScreenSaver()
        if m.playbackRefs.audioPlayer.state = "paused" then
            m.playbackRefs.audioPlayer.control = "resume"
        else
            m.playbackRefs.audioPlayer.control = "play"
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

    m.log.write("updatePlayPauseButton")

    if m.playbackControls = invalid then return

    m.playbackControls.isPlaying = (m.playbackState.isPaused <> true and m.playbackRefs.audioPlayer <> invalid and m.playbackRefs.audioPlayer.state = "playing")
end sub

'-------------------------------------------------------------------------------
' onProgressTimerFired
'-------------------------------------------------------------------------------
sub onProgressTimerFired()

    m.log.write("onProgressTimerFired")

    accumulatePlaybackListeningTime()
    position = getPlaybackCurrentTimeSeconds()

    if isPlaybackCompleteAtPosition(position) then
        handlePlaybackComplete()
        return
    end if

    if m.progressScrub.isActive = true then
        m.progressScrub.targetSeconds = position
        updatePlaybackPosition(position)
        updateProgressScrubPreview()
        requestPeriodicPlaybackSync()
        return
    end if

    updatePlaybackPosition(position)
    requestPeriodicPlaybackSync()
end sub

'-------------------------------------------------------------------------------
' isPlaybackCompleteAtPosition
'-------------------------------------------------------------------------------
function isPlaybackCompleteAtPosition(position as integer) as boolean

    m.log.write("isPlaybackCompleteAtPosition")

    if m.playbackState.complete = true then return false
    if m.playbackState.hasStarted <> true then return false
    if m.progressScrub.isActive = true then return false

    duration = getPlaybackDurationSeconds()
    if duration <= 0 then return false

    return position >= duration
end function

'-------------------------------------------------------------------------------
' accumulatePlaybackListeningTime
'-------------------------------------------------------------------------------
sub accumulatePlaybackListeningTime()

    m.log.write("accumulatePlaybackListeningTime")

    if m.playbackRefs.audioPlayer = invalid then return
    if SafeString(m.playbackRefs.audioPlayer.state, "") <> "playing" then
        m.playbackSync.lastProgressTickAtSeconds = 0
        return
    end if

    nowSeconds = getNowSeconds()
    if m.playbackSync.lastProgressTickAtSeconds > 0 then
        elapsedSeconds = nowSeconds - m.playbackSync.lastProgressTickAtSeconds
        if elapsedSeconds > 0 and elapsedSeconds < 10 then
            m.playbackSync.listeningTimeSinceSync = m.playbackSync.listeningTimeSinceSync + elapsedSeconds
        end if
    end if

    m.playbackSync.lastProgressTickAtSeconds = nowSeconds
end sub

'-------------------------------------------------------------------------------
' requestPeriodicPlaybackSync
'-------------------------------------------------------------------------------
sub requestPeriodicPlaybackSync()

    m.log.write("requestPeriodicPlaybackSync")

    if m.playbackState.isPaused = true then return
    if m.isClosing = true then return
    if m.playbackRefs.audioPlayer = invalid then return
    if SafeString(m.playbackRefs.audioPlayer.state, "") <> "playing" then return

    syncIntervalSeconds = m.playbackSync.config.syncIntervalSeconds
    if m.playbackSync.lastSyncedCurrentTimeSeconds <= 0 then syncIntervalSeconds = m.playbackSync.config.firstSyncIntervalSeconds

    if m.playbackSync.listeningTimeSinceSync >= syncIntervalSeconds then
        requestSyncPlaybackSession("periodic")
    end if
end sub

'-------------------------------------------------------------------------------
' getCurrentPlaybackPosition
'-------------------------------------------------------------------------------
function getCurrentPlaybackPosition() as integer

    m.log.write("getCurrentPlaybackPosition")

    if m.playbackRefs.audioPlayer = invalid or m.playbackRefs.audioPlayer.position = invalid then return 0
    return int(val(m.playbackRefs.audioPlayer.position.ToStr()))
end function

'-------------------------------------------------------------------------------
' getCurrentTrackPlaybackPosition
'-------------------------------------------------------------------------------
function getCurrentTrackPlaybackPosition() as integer

    m.log.write("getCurrentTrackPlaybackPosition")

    position = getPlaybackCurrentTimeSeconds() - m.timeline.currentTrackStartPosition
    if position < 0 then position = 0
    return position
end function

'-------------------------------------------------------------------------------
' setPlaybackVisualTarget
'-------------------------------------------------------------------------------
sub setPlaybackVisualTarget(targetTime as dynamic)

    m.log.write("setPlaybackVisualTarget")

    m.playbackSync.visualTargetSeconds = clampGlobalTime(targetTime)
    updateProgress(m.playbackSync.visualTargetSeconds, true)
    updateCurrentChapterStatus(m.playbackSync.visualTargetSeconds)
end sub

'-------------------------------------------------------------------------------
' getPlaybackCurrentTimeSeconds
'-------------------------------------------------------------------------------
function getPlaybackCurrentTimeSeconds() as integer

    m.log.write("getPlaybackCurrentTimeSeconds")

    if m.playbackSync.visualTargetSeconds <> invalid then
        actualTime = getActualPlaybackCurrentTimeSeconds()
        targetTime = clampGlobalTime(m.playbackSync.visualTargetSeconds)
        if m.playbackState.hasStarted <> true then return targetTime
        if Abs(actualTime - targetTime) <= 2 then
            m.playbackSync.visualTargetSeconds = invalid
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

    m.log.write("getActualPlaybackCurrentTimeSeconds")

    if m.playbackRefs.audioPlayer = invalid then return clampGlobalTime(m.timeline.currentTimeSeconds)
    if m.playbackContent.tracks = invalid or m.playbackContent.tracks.Count() = 0 then return clampGlobalTime(m.timeline.currentTimeSeconds)
    if m.playbackState.hasStarted <> true then return clampGlobalTime(m.timeline.currentTimeSeconds)

    currentPosition = getCurrentPlaybackPosition()
    if m.hlsRetry.isTranscode = true then return getHlsPlaybackCurrentTime(currentPosition)

    if m.timeline.currentTrackIndex < 0 or m.timeline.currentTrackIndex >= m.playbackContent.tracks.Count() then return clampGlobalTime(m.timeline.currentTimeSeconds)
    return clampGlobalTime(PlaybackTrackTime_GetTrackStartPosition(m.playbackContent.tracks[m.timeline.currentTrackIndex]) + currentPosition)
end function

'-------------------------------------------------------------------------------
' getHlsPlaybackCurrentTime
'-------------------------------------------------------------------------------
function getHlsPlaybackCurrentTime(currentPosition as integer) as integer

    m.log.write("getHlsPlaybackCurrentTime")

    currentTime = currentPosition
    if m.hlsRetry.startupSeekTargetSeconds = invalid then return clampGlobalTime(currentTime)

    targetTime = clampGlobalTime(m.hlsRetry.startupSeekTargetSeconds)
    if currentTime >= targetTime + 3 then
        m.hlsRetry.startupSeekTargetSeconds = invalid
        return clampGlobalTime(currentTime)
    end if

    return targetTime
end function

'-------------------------------------------------------------------------------
' getPlaybackDurationSeconds
'-------------------------------------------------------------------------------
function getPlaybackDurationSeconds() as integer

    m.log.write("getPlaybackDurationSeconds")

    if m.playbackContext.session <> invalid and m.playbackContext.session.duration <> invalid then
        return int(val(m.playbackContext.session.duration.ToStr()))
    end if

    return PlaybackTrackTime_GetPlaybackDurationSeconds(m.playbackContent.tracks, m.timeline.totalDurationSeconds)
end function

'-------------------------------------------------------------------------------
' getPlaybackTimeListenedSeconds
'-------------------------------------------------------------------------------
function getPlaybackTimeListenedSeconds() as integer

    m.log.write("getPlaybackTimeListenedSeconds")

    timeListened = int(m.playbackSync.listeningTimeSinceSync)
    if timeListened < 0 then return 0
    return timeListened
end function

'-------------------------------------------------------------------------------
' getNowSeconds
'-------------------------------------------------------------------------------
function getNowSeconds() as integer

    m.log.write("getNowSeconds")

    dateTime = CreateObject("roDateTime")
    return dateTime.AsSeconds()
end function

'-------------------------------------------------------------------------------
' updateProgress
'-------------------------------------------------------------------------------
sub updateProgress(positionSeconds as integer, forceUpdate = false as boolean)

    m.log.write("updateProgress")

    if forceUpdate <> true and m.playbackState.hasStarted <> true then return

    if positionSeconds < 0 then positionSeconds = 0
    if m.timeline.totalDurationSeconds > 0 and positionSeconds > m.timeline.totalDurationSeconds then positionSeconds = m.timeline.totalDurationSeconds

    if m.playbackControls <> invalid then m.playbackControls.positionSeconds = positionSeconds
end sub

'-------------------------------------------------------------------------------
' updateTotalDuration
'-------------------------------------------------------------------------------
sub updateTotalDuration()

    m.log.write("updateTotalDuration")

    if m.playbackControls <> invalid then m.playbackControls.totalDurationSeconds = m.timeline.totalDurationSeconds
end sub

'-------------------------------------------------------------------------------
' resetProgress
'-------------------------------------------------------------------------------
sub resetProgress()

    m.log.write("resetProgress")

    updateProgress(m.timeline.currentTimeSeconds, true)
end sub

'-------------------------------------------------------------------------------
' startProgressTimer
'-------------------------------------------------------------------------------
sub startProgressTimer()

    m.log.write("startProgressTimer")

    if m.playbackSync.lastProgressTickAtSeconds <= 0 then m.playbackSync.lastProgressTickAtSeconds = getNowSeconds()
    if m.timerRefs.progressTimer <> invalid then m.timerRefs.progressTimer.control = "start"
    if m.progressScrub.isActive = true then
        m.progressScrub.targetSeconds = getPlaybackCurrentTimeSeconds()
        updateProgressScrubPreview()
    else
        updateProgress(getPlaybackCurrentTimeSeconds())
    end if
end sub

'-------------------------------------------------------------------------------
' stopProgressTimer
'-------------------------------------------------------------------------------
sub stopProgressTimer()

    m.log.write("stopProgressTimer")

    if m.timerRefs.progressTimer <> invalid then m.timerRefs.progressTimer.control = "stop"
    m.playbackSync.lastProgressTickAtSeconds = 0
end sub



