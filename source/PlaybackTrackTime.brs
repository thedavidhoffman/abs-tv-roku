'-------------------------------------------------------------------------------
' PlaybackTrackTime_GetChapterItems
'-------------------------------------------------------------------------------
function PlaybackTrackTime_GetChapterItems(chapters as dynamic, tracks as dynamic) as object
    if chapters <> invalid and chapters.Count() > 0 then return chapters
    if tracks <> invalid then return tracks
    return []
end function

'-------------------------------------------------------------------------------
' PlaybackTrackTime_ClampGlobalTime
'-------------------------------------------------------------------------------
function PlaybackTrackTime_ClampGlobalTime(timeSeconds as dynamic, durationSeconds as integer) as integer
    if timeSeconds = invalid then timeSeconds = 0

    result = int(val(timeSeconds.ToStr()))
    if result < 0 then result = 0
    if durationSeconds > 0 and result > durationSeconds then result = durationSeconds

    return result
end function

'-------------------------------------------------------------------------------
' PlaybackTrackTime_GetTrackIndexForGlobalTime
'-------------------------------------------------------------------------------
function PlaybackTrackTime_GetTrackIndexForGlobalTime(tracks as dynamic, timeSeconds as dynamic, durationSeconds as integer, isHlsTranscode as boolean) as integer
    if tracks = invalid or tracks.Count() = 0 then return 0
    if isHlsTranscode = true then return 0

    targetTime = PlaybackTrackTime_ClampGlobalTime(timeSeconds, durationSeconds)
    lastIndex = tracks.Count() - 1
    for i = 0 to lastIndex
        track = tracks[i]
        trackStart = PlaybackTrackTime_GetTrackStartPosition(track)
        trackDuration = PlaybackTrackTime_GetTrackDurationSeconds(track)
        trackEnd = trackStart + trackDuration

        if targetTime >= trackStart and (trackDuration <= 0 or targetTime < trackEnd or i = lastIndex) then return i
    end for

    return 0
end function

'-------------------------------------------------------------------------------
' PlaybackTrackTime_GetTrackSeekPosition
'-------------------------------------------------------------------------------
function PlaybackTrackTime_GetTrackSeekPosition(tracks as dynamic, trackIndex as integer, globalTime as dynamic, durationSeconds as integer, isHlsTranscode as boolean) as integer
    seekTime = PlaybackTrackTime_ClampGlobalTime(globalTime, durationSeconds)
    if isHlsTranscode = true then return seekTime
    if tracks = invalid or trackIndex < 0 or trackIndex >= tracks.Count() then return seekTime

    seekTime = seekTime - PlaybackTrackTime_GetTrackStartPosition(tracks[trackIndex])
    if seekTime < 0 then seekTime = 0

    trackDuration = PlaybackTrackTime_GetTrackDurationSeconds(tracks[trackIndex])
    if trackDuration > 0 and seekTime > trackDuration then seekTime = trackDuration

    return seekTime
end function

'-------------------------------------------------------------------------------
' PlaybackTrackTime_GetTrackDurationSeconds
'-------------------------------------------------------------------------------
function PlaybackTrackTime_GetTrackDurationSeconds(track as dynamic) as integer
    if track = invalid then return 0
    if track.durationSeconds = invalid then return 0
    return int(val(track.durationSeconds.ToStr()))
end function

'-------------------------------------------------------------------------------
' PlaybackTrackTime_GetTrackStartPosition
'-------------------------------------------------------------------------------
function PlaybackTrackTime_GetTrackStartPosition(track as dynamic) as integer
    if track = invalid then return 0
    if track.startOffset <> invalid then return int(val(track.startOffset.ToStr()))
    return 0
end function

'-------------------------------------------------------------------------------
' PlaybackTrackTime_GetPlaybackDurationSeconds
'-------------------------------------------------------------------------------
function PlaybackTrackTime_GetPlaybackDurationSeconds(tracks as dynamic, totalDurationSeconds as integer) as integer
    if totalDurationSeconds > 0 then return totalDurationSeconds
    if tracks = invalid or tracks.Count() = 0 then return 0

    durationSeconds = 0
    for each track in tracks
        durationSeconds = durationSeconds + PlaybackTrackTime_GetTrackDurationSeconds(track)
    end for

    return durationSeconds
end function

'-------------------------------------------------------------------------------
' PlaybackTrackTime_GetStreamFormat
'-------------------------------------------------------------------------------
function PlaybackTrackTime_GetStreamFormat(mimeType as dynamic, url as dynamic) as string
    streamUrl = LCase(SafeString(url, ""))
    if Instr(1, streamUrl, ".m3u8") > 0 or Instr(1, streamUrl, "/hls/") > 0 then return "hls"

    mime = LCase(SafeString(mimeType, "audio/mpeg"))
    if Instr(1, mime, "mp4") > 0 then return "mp4"
    if Instr(1, mime, "m4a") > 0 then return "mp4"
    if Instr(1, mime, "m4b") > 0 then return "mp4"
    if Instr(1, mime, "aac") > 0 then return "aac"

    return "mp3"
end function
