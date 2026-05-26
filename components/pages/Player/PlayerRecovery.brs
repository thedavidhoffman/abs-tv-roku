'-------------------------------------------------------------------------------
' PlayerRecovery_TryRecover
'-------------------------------------------------------------------------------
function PlayerRecovery_TryRecover(reason as string) as boolean
    if __RestartWithTranscodeFallback(reason) then return true
    if __ScheduleHlsStartupRetry(reason) then return true
    if __RefreshHlsPlaybackSession(reason) then return true
    return false
end function

'-------------------------------------------------------------------------------
' PlayerRecovery_OnHlsRetryTimerFired
'-------------------------------------------------------------------------------
sub PlayerRecovery_OnHlsRetryTimerFired()

    logPlayerVerbose("PlayerRecovery_OnHlsRetryTimerFired")

    __RetryHlsPlayback()

end sub

'-------------------------------------------------------------------------------
' __RestartWithTranscodeFallback
'-------------------------------------------------------------------------------
function __RestartWithTranscodeFallback(reason as string) as boolean

    logPlayerVerbose("__RestartWithTranscodeFallback")

    if not __CanRestartWithTranscodeFallback() then return false

    m.recovery.transcodeHlsFallbackAttempted = true
    logPlayer("direct playback fallback reason=" + reason)
    __RestartPlaybackSession(true, "direct-play-fallback-" + reason)
    return true

end function

'-------------------------------------------------------------------------------
' __RefreshHlsPlaybackSession
'-------------------------------------------------------------------------------
function __RefreshHlsPlaybackSession(reason as string) as boolean

    logPlayerVerbose("__RefreshHlsPlaybackSession")

    if not __CanRefreshHlsPlaybackSession() then return false

    m.recovery.sessionRefreshAttempted = true
    logPlayer("HLS session refresh reason=" + reason)
    __RestartPlaybackSession(true, "hls-session-refresh-" + reason)
    return true

end function

'-------------------------------------------------------------------------------
' __RestartPlaybackSession
'-------------------------------------------------------------------------------
sub __RestartPlaybackSession(forceTranscode as boolean, reason as string)

    logPlayerVerbose("__RestartPlaybackSession")

    currentTime = getPlaybackCurrentTimeSeconds()
    logPlayer("restarting playback session reason=" + reason + " currentTime=" + currentTime.ToStr() + " forceTranscode=" + forceTranscode.ToStr())

    resetMediaNodeForNewPlayback()
    resetPlaybackSessionState()
    resetPlaybackRetryState(false)
    m.timeline.currentTimeSeconds = currentTime
    m.timeline.requestedStartPositionSeconds = currentTime
    setStatus("Starting playback...")
    requestStartPlaybackSession(forceTranscode, currentTime)

end sub

'-------------------------------------------------------------------------------
' __ScheduleHlsStartupRetry
'-------------------------------------------------------------------------------
function __ScheduleHlsStartupRetry(reason as string) as boolean

    logPlayerVerbose("__ScheduleHlsStartupRetry")

    if not __CanScheduleHlsStartupRetry() then return false
    if m.recovery.retryPending = true then return true
    retryMax = __GetHlsRetryMax()
    if m.recovery.retryCount >= retryMax then return false

    m.recovery.retryCount = m.recovery.retryCount + 1
    m.recovery.retryPending = true
    stopProgressTimer()
    logPlayer("HLS startup retry " + m.recovery.retryCount.ToStr() + "/" + retryMax.ToStr() + " reason=" + reason + " currentTime=" + m.timeline.currentTimeSeconds.ToStr())

    PlayerAudio_Stop()
    if m.timerRefs.hlsRetryTimer <> invalid then
        m.timerRefs.hlsRetryTimer.control = "stop"
        m.timerRefs.hlsRetryTimer.control = "start"
    else
        __RetryHlsPlayback()
    end if

    return true

end function

'-------------------------------------------------------------------------------
' __CanRestartWithTranscodeFallback
'-------------------------------------------------------------------------------
function __CanRestartWithTranscodeFallback() as boolean
    if m.isClosing = true then return false
    if m.recovery.isHlsTranscode = true then return false
    if m.recovery.transcodeHlsFallbackAttempted = true then return false
    return true
end function

'-------------------------------------------------------------------------------
' __CanRefreshHlsPlaybackSession
'-------------------------------------------------------------------------------
function __CanRefreshHlsPlaybackSession() as boolean
    if m.isClosing = true then return false
    if m.recovery.isHlsTranscode <> true then return false
    if m.recovery.sessionRefreshAttempted = true then return false
    return true
end function

'-------------------------------------------------------------------------------
' __CanScheduleHlsStartupRetry
'-------------------------------------------------------------------------------
function __CanScheduleHlsStartupRetry() as boolean
    if m.isClosing = true then return false
    if m.recovery.isHlsTranscode <> true then return false
    return true
end function

'-------------------------------------------------------------------------------
' __GetHlsRetryMax
'-------------------------------------------------------------------------------
function __GetHlsRetryMax() as integer

    logPlayerVerbose("__GetHlsRetryMax")

    if m.recovery.startupSeekTargetSeconds <> invalid then return m.recovery.resumeMax
    return m.recovery.retryMax

end function

'-------------------------------------------------------------------------------
' __RetryHlsPlayback
'-------------------------------------------------------------------------------
sub __RetryHlsPlayback()

    logPlayerVerbose("__RetryHlsPlayback")

    if m.isClosing = true then return
    if m.playbackContent.tracks = invalid or m.playbackContent.tracks.Count() = 0 then return

    m.recovery.retryPending = false
    m.timeline.pendingSeekSeconds = getTrackSeekPosition(m.timeline.currentTrackIndex, m.timeline.currentTimeSeconds)
    playCurrentTrack(true)

end sub
