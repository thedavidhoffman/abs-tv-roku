'-------------------------------------------------------------------------------
' PlayerAudio_GetState
'-------------------------------------------------------------------------------
function PlayerAudio_GetState() as string
    if m.playbackRefs.audioPlayer = invalid then return ""
    return SafeString(m.playbackRefs.audioPlayer.state, "")
end function

'-------------------------------------------------------------------------------
' PlayerAudio_GetPosition
'-------------------------------------------------------------------------------
function PlayerAudio_GetPosition() as integer
    if m.playbackRefs.audioPlayer = invalid or m.playbackRefs.audioPlayer.position = invalid then return 0
    return Number_ToInteger(m.playbackRefs.audioPlayer.position)
end function

'-------------------------------------------------------------------------------
' PlayerAudio_SetControl
'-------------------------------------------------------------------------------
sub PlayerAudio_SetControl(control as string)
    if m.playbackRefs.audioPlayer <> invalid then m.playbackRefs.audioPlayer.control = control
end sub

'-------------------------------------------------------------------------------
' PlayerAudio_Stop
'-------------------------------------------------------------------------------
sub PlayerAudio_Stop()
    PlayerAudio_SetControl("stop")
end sub

'-------------------------------------------------------------------------------
' PlayerAudio_SetContent
'-------------------------------------------------------------------------------
sub PlayerAudio_SetContent(content as dynamic)
    if m.playbackRefs.audioPlayer <> invalid then m.playbackRefs.audioPlayer.content = content
end sub

'-------------------------------------------------------------------------------
' PlayerAudio_ClearContent
'-------------------------------------------------------------------------------
sub PlayerAudio_ClearContent()
    PlayerAudio_SetContent(invalid)
end sub

'-------------------------------------------------------------------------------
' PlayerAudio_Seek
'-------------------------------------------------------------------------------
sub PlayerAudio_Seek(positionSeconds as integer)
    if m.playbackRefs.audioPlayer <> invalid then m.playbackRefs.audioPlayer.seek = positionSeconds
end sub

'-------------------------------------------------------------------------------
' PlayerAudio_SetScreenSaverDisabled
'-------------------------------------------------------------------------------
sub PlayerAudio_SetScreenSaverDisabled(disabled as boolean)
    if m.playbackRefs.audioPlayer <> invalid then m.playbackRefs.audioPlayer.disableScreenSaver = disabled
end sub

'-------------------------------------------------------------------------------
' PlayerAudio_IsPlaying
'-------------------------------------------------------------------------------
function PlayerAudio_IsPlaying() as boolean
    return PlayerAudio_GetState() = "playing"
end function

'-------------------------------------------------------------------------------
' PlayerAudio_IsPaused
'-------------------------------------------------------------------------------
function PlayerAudio_IsPaused() as boolean
    return PlayerAudio_GetState() = "paused"
end function

'-------------------------------------------------------------------------------
' PlayerAudio_IsFinished
'-------------------------------------------------------------------------------
function PlayerAudio_IsFinished() as boolean
    return PlayerAudio_GetState() = "finished"
end function
