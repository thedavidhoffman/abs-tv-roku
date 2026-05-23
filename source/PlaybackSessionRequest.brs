'-------------------------------------------------------------------------------
' PlaybackSessionRequest_Build
'-------------------------------------------------------------------------------
function PlaybackSessionRequest_Build(action as string, playbackContext as dynamic, currentTime as integer, timeListened as integer, durationSeconds as integer, hasSyncedProgress as boolean, syncIntervalSeconds as integer, closeProgressSaveThresholdSeconds as integer) as dynamic
    if playbackContext = invalid then return invalid
    if playbackContext.sessionId = invalid or playbackContext.sessionId = "" then return invalid
    if playbackContext.server = invalid or playbackContext.server = "" then return invalid
    if playbackContext.token = invalid or playbackContext.token = "" then return invalid

    request = {
        action: action
        server: playbackContext.server
        token: playbackContext.token
        sessionId: playbackContext.sessionId
    }

    if PlaybackSessionRequest_ShouldSendProgress(action, timeListened, hasSyncedProgress, syncIntervalSeconds, closeProgressSaveThresholdSeconds) then
        request.currentTime = currentTime
        request.timeListened = timeListened
        request.duration = durationSeconds
    end if

    return request
end function

'-------------------------------------------------------------------------------
' PlaybackSessionRequest_ShouldSendProgress
'-------------------------------------------------------------------------------
function PlaybackSessionRequest_ShouldSendProgress(action as string, timeListened as integer, hasSyncedProgress as boolean, syncIntervalSeconds as integer, closeProgressSaveThresholdSeconds as integer) as boolean
    if action <> "closePlaybackSession" then return true
    if hasSyncedProgress then return timeListened >= syncIntervalSeconds
    return timeListened >= closeProgressSaveThresholdSeconds
end function
