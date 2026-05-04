'-------------------------------------------------------------------------------
' Playback_Start
'-------------------------------------------------------------------------------
function Playback_Start(request as object) as object
    log = CreateLogger("Playback_Start")

    server = NormalizeServerUrl(request.server)
    token = request.token
    itemId = request.itemId

    if itemId = invalid or itemId = "" then
        return { ok: false, errorMessage: "No audiobook was selected." }
    end if

    ' get the item (so that we have track data)
    itemResult = Item_Load(request)
    itemPayload = invalid
    if itemResult.ok = true then itemPayload = itemResult.data
    Item_LogTracks(itemPayload)

    bodyData = {
        deviceInfo: {
            clientName: "ABSTV"
            clientVersion: "0.1.0"
            manufacturer: "Roku"
            model: "Roku"
        }
        forceDirectPlay: false
        forceTranscode: true
        supportedMimeTypes: [
            "application/vnd.apple.mpegurl"
            "application/x-mpegURL"
            "audio/mpegurl"
            "audio/x-mpegurl"
        ]
        mediaPlayer: "roku"
    }
    body = FormatJson(bodyData)

    log.log("forceDirectPlay=" + bodyData.forceDirectPlay.ToStr() + " forceTranscode=" + bodyData.forceTranscode.ToStr() + " supportedMimeTypes=" + ___JoinStringValues(bodyData.supportedMimeTypes))

    playbackUrl = server + "/api/items/" + itemId + "/play"
    playbackResult = HttpClient_Request(playbackUrl, "POST", token, body)

    log.log(playbackUrl)
    log.log("status = " + SafeString(playbackResult.status))

    if playbackResult.ok <> true then return playbackResult

    tracks = ___MapTracks(server, token, playbackResult.data, itemPayload, log)
    if tracks.Count() = 0 then
        return { ok: false, errorMessage: "No playable audio tracks were returned." }
    end if

    return {
        ok: true
        action: "startPlayback"
        itemId: itemId
        title: request.title
        playbackSession: playbackResult.data
        tracks: tracks
    }
end function

'-------------------------------------------------------------------------------
' Playback_CloseSession
'-------------------------------------------------------------------------------
function Playback_CloseSession(request as object) as object
    log = CreateLogger("Playback_CloseSession")

    server = NormalizeServerUrl(request.server)
    token = request.token
    sessionId = request.sessionId

    if sessionId = invalid or sessionId = "" then
        return { ok: false, action: "closePlaybackSession", errorMessage: "No playback session was available to close." }
    end if

    bodyData = {}
    if request.currentTime <> invalid then bodyData.currentTime = request.currentTime
    if request.timeListened <> invalid then bodyData.timeListened = request.timeListened
    if request.duration <> invalid then bodyData.duration = request.duration

    log.log("sessionId=" + sessionId.ToStr() + " currentTime=" + SafeString(bodyData.currentTime, "invalid") + " timeListened=" + SafeString(bodyData.timeListened, "invalid") + " duration=" + SafeString(bodyData.duration, "invalid"))

    result = HttpClient_Request(server + "/api/session/" + sessionId.ToStr() + "/close", "POST", token, FormatJson(bodyData))
    result.action = "closePlaybackSession"
    return result
end function

'-------------------------------------------------------------------------------
' ___JoinStringValues
'-------------------------------------------------------------------------------
function ___JoinStringValues(values as dynamic) as string
    if values = invalid then return ""

    result = ""
    for each value in values
        if result <> "" then result = result + ", "
        result = result + SafeString(value, "")
    end for

    return result
end function

'-------------------------------------------------------------------------------
' ___MapTracks
'-------------------------------------------------------------------------------
function ___MapTracks(server as string, token as dynamic, payload as dynamic, itemPayload as dynamic, log as object) as object
    mappedTracks = []
    tracks = ___GetSessionTracks(payload)
    files = ___GetSessionFiles(payload, itemPayload)
    sessionId = invalid

    if payload <> invalid and payload.id <> invalid then sessionId = payload.id

    log.log("playback mapping audioTracks=" + ___GetArrayCount(tracks).ToStr() + " files=" + ___GetArrayCount(files).ToStr())

    if files <> invalid and files.Count() > 0 and tracks <> invalid and tracks.Count() = 1 then
        track = tracks[0]
        startPositionSeconds = 0
        for i = 0 to files.Count() - 1
            file = files[i]
            durationSeconds = ___GetTrackDurationSeconds(file, track)
            mappedTracks.Push({
                url: ___BuildUrl(server, token, sessionId, track)
                title: ___GetTrackTitle(file, track, i)
                durationSeconds: durationSeconds
                startPositionSeconds: startPositionSeconds
                mimeType: ___GetTrackMimeType(file, track)
            })
            startPositionSeconds = startPositionSeconds + durationSeconds
        end for
    else if files <> invalid and files.Count() > 0 and (tracks = invalid or files.Count() > tracks.Count()) then
        for i = 0 to files.Count() - 1
            file = files[i]
            track = ___GetTrackForFileIndex(tracks, file, i)
            url = ___BuildFileUrl(server, token, sessionId, file, track, i)
            if url <> "" then
                mappedTracks.Push({
                    url: url
                    title: ___GetTrackTitle(file, track, i)
                    durationSeconds: ___GetTrackDurationSeconds(file, track)
                    mimeType: ___GetTrackMimeType(file, track)
                })
            end if
        end for
    else if tracks <> invalid then
        for i = 0 to tracks.Count() - 1
            track = tracks[i]
            file = ___GetFileForTrack(files, track, i)
            contentUrl = invalid
            if track.contentUrl <> invalid then contentUrl = track.contentUrl
            if contentUrl <> invalid and contentUrl <> "" then
                mappedTracks.Push({
                    url: ___BuildUrl(server, token, sessionId, track)
                    title: ___GetTrackTitle(file, track, i)
                    durationSeconds: ___GetTrackDurationSeconds(file, track)
                    mimeType: ___GetTrackMimeType(file, track)
                })
            end if
        end for
    end if

    return mappedTracks
end function

'-------------------------------------------------------------------------------
' ___GetArrayCount
'-------------------------------------------------------------------------------
function ___GetArrayCount(values as dynamic) as integer
    if values = invalid then return 0
    return values.Count()
end function

'-------------------------------------------------------------------------------
' ___GetTrackForFileIndex
'-------------------------------------------------------------------------------
function ___GetTrackForFileIndex(tracks as dynamic, file as dynamic, fallbackIndex as integer) as dynamic
    if tracks = invalid or tracks.Count() = 0 then return invalid

    fileIndex = ___GetFileIndex(file, fallbackIndex)
    for each track in tracks
        if track.index <> invalid and int(val(track.index.ToStr())) = fileIndex then return track
        if track.trackNum <> invalid and int(val(track.trackNum.ToStr())) = fileIndex then return track
    end for

    if fallbackIndex >= 0 and fallbackIndex < tracks.Count() then return tracks[fallbackIndex]
    return invalid
end function

'-------------------------------------------------------------------------------
' ___GetFileIndex
'-------------------------------------------------------------------------------
function ___GetFileIndex(file as dynamic, fallbackIndex as integer) as integer
    if file <> invalid then
        if file.index <> invalid then return int(val(file.index.ToStr()))
        if file.trackNum <> invalid then return int(val(file.trackNum.ToStr()))
    end if

    return fallbackIndex
end function

'-------------------------------------------------------------------------------
' ___BuildFileUrl
'-------------------------------------------------------------------------------
function ___BuildFileUrl(server as string, token as dynamic, sessionId as dynamic, file as dynamic, track as dynamic, fallbackIndex as integer) as string
    if track <> invalid and track.contentUrl <> invalid and track.contentUrl <> "" then
        return ___BuildUrl(server, token, sessionId, track)
    end if

    if file <> invalid and file.contentUrl <> invalid and file.contentUrl <> "" then
        return ___BuildUrl(server, token, sessionId, file)
    end if

    if sessionId <> invalid and sessionId <> "" then
        return server + "/public/session/" + sessionId + "/track/" + ___GetFileIndex(file, fallbackIndex).ToStr()
    end if

    return ""
end function

'-------------------------------------------------------------------------------
' ___GetSessionTracks
'-------------------------------------------------------------------------------
function ___GetSessionTracks(payload as dynamic) as dynamic
    if payload = invalid then return invalid

    if payload.audioTracks <> invalid then return payload.audioTracks
    if payload.libraryItem <> invalid and payload.libraryItem.media <> invalid then
        if payload.libraryItem.media.audioTracks <> invalid then return payload.libraryItem.media.audioTracks
    end if

    return invalid
end function

'-------------------------------------------------------------------------------
' ___GetSessionFiles
'-------------------------------------------------------------------------------
function ___GetSessionFiles(payload as dynamic, itemPayload as dynamic) as dynamic
    files = ___GetItemFiles(itemPayload)
    if files <> invalid then return files

    if payload <> invalid and payload.libraryItem <> invalid then return ___GetItemFiles(payload.libraryItem)
    return ___GetItemFiles(payload)
end function

'-------------------------------------------------------------------------------
' ___GetItemFiles
'-------------------------------------------------------------------------------
function ___GetItemFiles(item as dynamic) as dynamic
    if item = invalid or item.media = invalid then return invalid

    if item.media.audioFiles <> invalid then return item.media.audioFiles
    if item.media.tracks <> invalid then return item.media.tracks
    return invalid
end function

'-------------------------------------------------------------------------------
' ___GetFileForTrack
'-------------------------------------------------------------------------------
function ___GetFileForTrack(files as dynamic, track as dynamic, fallbackIndex as integer) as dynamic
    if files = invalid or files.Count() = 0 then return invalid

    trackIndex = fallbackIndex
    if track <> invalid and track.index <> invalid then trackIndex = int(val(track.index.ToStr()))

    for each file in files
        if file.index <> invalid and int(val(file.index.ToStr())) = trackIndex then return file
        if file.trackNum <> invalid and int(val(file.trackNum.ToStr())) = trackIndex then return file
    end for

    if fallbackIndex >= 0 and fallbackIndex < files.Count() then return files[fallbackIndex]
    return invalid
end function

'-------------------------------------------------------------------------------
' ___GetTrackTitle
'-------------------------------------------------------------------------------
function ___GetTrackTitle(file as dynamic, track as dynamic, index as integer) as string
    title = ""

    if file <> invalid then
        if file.metaTags <> invalid then
            title = FirstNonEmpty([file.metaTags.tagTitle], "")
        end if
        if file.metadata <> invalid then
            title = FirstNonEmpty([title, file.metadata.title, file.metadata.trackTitle, file.metadata.name], "")
        end if
        title = FirstNonEmpty([title, file.trackTitle], "")
    end if

    if title = "" and track <> invalid then
        title = FirstNonEmpty([track.title, track.name], "")
    end if

    if title = "" or title = "Audiobook" then title = "Track " + (index + 1).ToStr()
    return title
end function

'-------------------------------------------------------------------------------
' ___GetTrackMimeType
'-------------------------------------------------------------------------------
function ___GetTrackMimeType(file as dynamic, track as dynamic) as string
    if track <> invalid and track.mimeType <> invalid then return SafeString(track.mimeType, "audio/mpeg")
    if file <> invalid and file.mimeType <> invalid then return SafeString(file.mimeType, "audio/mpeg")
    if file <> invalid and file.metadata <> invalid and file.metadata.mimeType <> invalid then return SafeString(file.metadata.mimeType, "audio/mpeg")
    return "audio/mpeg"
end function

'-------------------------------------------------------------------------------
' ___GetTrackDurationSeconds
'-------------------------------------------------------------------------------
function ___GetTrackDurationSeconds(file as dynamic, track as dynamic) as integer
    duration = invalid

    if file <> invalid then
        if file.duration <> invalid then duration = file.duration
        if duration = invalid and file.metadata <> invalid and file.metadata.duration <> invalid then duration = file.metadata.duration
    end if

    if duration = invalid and track <> invalid then
        if track.duration <> invalid then duration = track.duration
        if duration = invalid and track.durationSeconds <> invalid then duration = track.durationSeconds
    end if

    if duration = invalid then return 0
    return int(val(duration.ToStr()))
end function

'-------------------------------------------------------------------------------
' ___BuildUrl
'-------------------------------------------------------------------------------
function ___BuildUrl(server as string, token as dynamic, sessionId as dynamic, track as dynamic) as string
    contentUrl = SafeString(track.contentUrl, "")
    lowerContentUrl = LCase(contentUrl)

    isHlsUrl = (Instr(1, lowerContentUrl, "/hls") > 0 or Instr(1, lowerContentUrl, ".m3u8") > 0)
    if sessionId <> invalid and sessionId <> "" and isHlsUrl = false then
        return server + "/public/session/" + sessionId + "/track/" + track.index.ToStr()
    end if

    url = contentUrl
    if Instr(1, LCase(url), "http://") <> 1 and Instr(1, LCase(url), "https://") <> 1 then
        if Left(url, 1) <> "/" then url = "/" + url
        url = server + url
    end if

    url = ___ReplaceString(url, " ", "%20")
    separator = "?"
    if Instr(1, url, "?") > 0 then separator = "&"
    if token <> invalid and token <> "" then url = url + separator + "token=" + token
    return url
end function

'-------------------------------------------------------------------------------
' ___ReplaceString
'-------------------------------------------------------------------------------
function ___ReplaceString(value as string, oldValue as string, newValue as string) as string
    result = ""
    remaining = value
    index = Instr(1, remaining, oldValue)

    while index > 0
        result = result + Left(remaining, index - 1) + newValue
        remaining = Mid(remaining, index + Len(oldValue))
        index = Instr(1, remaining, oldValue)
    end while

    return result + remaining
end function
