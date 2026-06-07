'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.top.functionName = "executeRequest"
end sub

'-------------------------------------------------------------------------------
' executeRequest
'-------------------------------------------------------------------------------
sub executeRequest()
    request = m.top.request
    if request = invalid then
        m.top.response = { ok: false, errorMessage: "Invalid playback request." }
        return
    end if

    action = request.action
    if action = "startPlayback" then
        m.top.response = Playback_Start(request)
    else if action = "syncPlaybackSession" then
        m.top.response = Playback_SyncSession(request)
    else if action = "closePlaybackSession" then
        m.top.response = Playback_CloseSession(request)
    else
        m.top.response = { ok: false, errorMessage: "Unknown playback request action." }
    end if
end sub
