'-------------------------------------------------------------------------------
' Playback_CreateLogger
'-------------------------------------------------------------------------------
function Playback_CreateLogger(suffix = "" as string) as object

    label = "Playback_Start"
    if suffix <> invalid and suffix <> "" then label = label + "::" + suffix

    return CreateLogger(label, false)

end function

'-------------------------------------------------------------------------------
' Playback_Start
'-------------------------------------------------------------------------------
function Playback_Start(request as object) as object

    log = Playback_CreateLogger()

    '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    ' parameter validation
    '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    if request = invalid then
        log.write("Invalid playback request: request is invalid.")
        return { ok: false, errorMessage: "Invalid playback request." }
    end if

    if Type(request) <> "roAssociativeArray" then
        log.write("Invalid playback request: request type is " + Type(request) + ".")
        return { ok: false, errorMessage: "Invalid playback request." }
    end if

    if request.server = invalid or request.server = "" then
        log.write("Invalid playback request: server is missing.")
        return { ok: false, errorMessage: "No Audiobookshelf server was provided." }
    end if

    if request.token = invalid or request.token = "" then
        log.write("Invalid playback request: token is missing.")
        return { ok: false, errorMessage: "No authentication token was provided." }
    end if

    if request.itemId = invalid or request.itemId = "" then
        log.write("Invalid playback request: itemId is missing.")
        return { ok: false, errorMessage: "No audiobook was selected." }
    end if

    if request.title = invalid then request.title = ""

    ' local working vars
    server = NormalizeServerUrl(request.server)
    token = request.token
    itemId = request.itemId

    ' get the item (so that we have track data)
    itemResult = Item_Load(request)
    itemPayload = invalid
    if itemResult.ok = true then itemPayload = itemResult.data
    Item_LogTracks(itemPayload)

    ' Roku device info
    deviceInfo = CreateObject("roDeviceInfo")
    model = deviceInfo.GetModel()
    modelDisplayName = deviceInfo.GetModelDisplayName()

    ' abs playback config
    bodyData = {
        deviceInfo: {
            clientName: "ABSTV"
            clientVersion: "0.1.0"
            manufacturer: "Roku"
            model: modelDisplayName + " " + model
        }
        forceDirectPlay: false
        forceTranscode: false
        supportedMimeTypes: [
            "audio/mpeg"
            "audio/mp4"
            "audio/aac"
            "application/vnd.apple.mpegurl"
            "application/x-mpegURL"
        ]
        mediaPlayer: "roku"
    }

    body = FormatJson(bodyData)

    log.write("forceDirectPlay=" + bodyData.forceDirectPlay.ToStr() + " forceTranscode=" + bodyData.forceTranscode.ToStr() + " supportedMimeTypes=" + Array_JoinStringValues(bodyData.supportedMimeTypes))

    playbackUrl = server + "/api/items/" + itemId + "/play"
    playbackResult = HttpClient_Request(playbackUrl, "POST", token, body)

    log.write(playbackUrl)
    log.write("status = " + SafeString(playbackResult.status))

    if playbackResult.ok <> true then return playbackResult

    tracks = __MapTracks(server, token, playbackResult.data, itemPayload, log)
    if tracks.Count() = 0 then
        return { ok: false, errorMessage: "No playable audio tracks were returned." }
    end if

    result = {
        ok: true
        action: "startPlayback"
        itemId: itemId
        title: request.title
        playbackSession: playbackResult.data
        tracks: tracks
    }

    __LogMappedTracks(log, tracks)

    return result

end function

'-------------------------------------------------------------------------------
' __LogMappedTracks
'-------------------------------------------------------------------------------
sub __LogMappedTracks(log as object, tracks as dynamic)

    log.write("Mapped tracks:")

    if tracks = invalid or tracks.Count() = 0 then
        log.write("    none")
        return
    end if

    for i = 0 to tracks.Count() - 1
        track = tracks[i]

        log.write("  track=" + i.ToStr() + "............")

        if track <> invalid then
            log.write("    title: " + SafeString(track.title, ""))
            log.write("    durationSeconds: " + SafeString(track.durationSeconds, "invalid"))
            log.write("    startPositionSeconds: " + SafeString(track.startPositionSeconds, "invalid"))
            log.write("    mimeType: " + SafeString(track.mimeType, ""))
            log.write("    url: " + SafeString(track.url, ""))
        else
            log.write("    invalid track")
        end if

    end for
end sub

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

    log.write("sessionId=" + sessionId.ToStr() + " currentTime=" + SafeString(bodyData.currentTime, "invalid") + " timeListened=" + SafeString(bodyData.timeListened, "invalid") + " duration=" + SafeString(bodyData.duration, "invalid"))

    result = HttpClient_Request(server + "/api/session/" + sessionId.ToStr() + "/close", "POST", token, FormatJson(bodyData))
    result.action = "closePlaybackSession"

    return result

end function

'-------------------------------------------------------------------------------
' Playback_SyncSession
'-------------------------------------------------------------------------------
function Playback_SyncSession(request as object) as object

    log = CreateLogger("Playback_SyncSession")

    server = NormalizeServerUrl(request.server)
    token = request.token
    sessionId = request.sessionId

    if sessionId = invalid or sessionId = "" then
        return { ok: false, action: "syncPlaybackSession", errorMessage: "No playback session was available to sync." }
    end if

    bodyData = {}
    if request.currentTime <> invalid then bodyData.currentTime = request.currentTime
    if request.timeListened <> invalid then bodyData.timeListened = request.timeListened
    if request.duration <> invalid then bodyData.duration = request.duration

    log.write("sessionId=" + sessionId.ToStr() + " currentTime=" + SafeString(bodyData.currentTime, "invalid") + " timeListened=" + SafeString(bodyData.timeListened, "invalid") + " duration=" + SafeString(bodyData.duration, "invalid"))

    result = HttpClient_Request(server + "/api/session/" + sessionId.ToStr() + "/sync", "POST", token, FormatJson(bodyData))
    result.action = "syncPlaybackSession"

    return result

end function

'-------------------------------------------------------------------------------
' __MapTracks
'-------------------------------------------------------------------------------
function __MapTracks(server as string, token as dynamic, payload as dynamic, itemPayload as dynamic, log as object) as object

    mappedTracks = []
    tracks = __GetSessionTracks(payload)
    files = __GetSessionFiles(payload, itemPayload)
    sessionId = invalid

    if payload <> invalid and payload.id <> invalid then sessionId = payload.id

    log.write("playback mapping audioTracks=" + Array_GetCount(tracks).ToStr() + " files=" + Array_GetCount(files).ToStr())

    if files <> invalid and files.Count() > 0 and tracks <> invalid and tracks.Count() = 1 then
        track = tracks[0]
        startPositionSeconds = 0
        for i = 0 to files.Count() - 1
            file = files[i]
            durationSeconds = __GetTrackDurationSeconds(file, track)
            mappedTracks.Push({
                url: __BuildPlaybackUrl(server, token, sessionId, track)
                title: __GetTrackTitle(file, track, i)
                durationSeconds: durationSeconds
                startPositionSeconds: startPositionSeconds
                mimeType: __GetTrackMimeType(file, track)
            })
            startPositionSeconds = startPositionSeconds + durationSeconds
        end for
    else if files <> invalid and files.Count() > 0 and (tracks = invalid or files.Count() > tracks.Count()) then
        for i = 0 to files.Count() - 1
            file = files[i]
            track = __GetTrackForFileIndex(tracks, file, i)
            url = __BuildFileUrl(server, token, sessionId, file, track, i, log)
            if url <> "" then
                mappedTracks.Push({
                    url: url
                    title: __GetTrackTitle(file, track, i)
                    durationSeconds: __GetTrackDurationSeconds(file, track)
                    mimeType: __GetTrackMimeType(file, track)
                })
            end if
        end for
    else if tracks <> invalid then
        for i = 0 to tracks.Count() - 1
            track = tracks[i]
            file = __GetFileForTrack(files, track, i)
            contentUrl = invalid
            if track.contentUrl <> invalid then contentUrl = track.contentUrl
            if contentUrl <> invalid and contentUrl <> "" then
                mappedTracks.Push({
                    url: __BuildPlaybackUrl(server, token, sessionId, track)
                    title: __GetTrackTitle(file, track, i)
                    durationSeconds: __GetTrackDurationSeconds(file, track)
                    mimeType: __GetTrackMimeType(file, track)
                })
            end if
        end for
    end if

    return mappedTracks
end function

'-------------------------------------------------------------------------------
' __GetTrackForFileIndex
'-------------------------------------------------------------------------------
function __GetTrackForFileIndex(tracks as dynamic, file as dynamic, fallbackIndex as integer) as dynamic
    if tracks = invalid or tracks.Count() = 0 then return invalid

    fileIndex = __GetFileIndex(file, fallbackIndex)
    for each track in tracks
        if track.index <> invalid and int(val(track.index.ToStr())) = fileIndex then return track
        if track.trackNum <> invalid and int(val(track.trackNum.ToStr())) = fileIndex then return track
    end for

    if fallbackIndex >= 0 and fallbackIndex < tracks.Count() then return tracks[fallbackIndex]
    return invalid
end function

'-------------------------------------------------------------------------------
' __GetFileIndex
'-------------------------------------------------------------------------------
function __GetFileIndex(file as dynamic, fallbackIndex as integer) as integer
    if file <> invalid then
        if file.index <> invalid then return int(val(file.index.ToStr()))
        if file.trackNum <> invalid then return int(val(file.trackNum.ToStr()))
    end if

    return fallbackIndex
end function

'-------------------------------------------------------------------------------
' __BuildFileUrl
'-------------------------------------------------------------------------------
function __BuildFileUrl(server as string, token as dynamic, sessionId as dynamic, file as dynamic, track as dynamic, fallbackIndex as integer, log as object) as string
    if track <> invalid and track.contentUrl <> invalid and track.contentUrl <> "" then
        return __BuildPlaybackUrl(server, token, sessionId, track)
    end if

    if file <> invalid and file.contentUrl <> invalid and file.contentUrl <> "" then
        return __BuildPlaybackUrl(server, token, sessionId, file)
    end if

    if sessionId <> invalid and sessionId <> "" then
        return server + "/public/session/" + sessionId + "/track/" + __GetFileIndex(file, fallbackIndex).ToStr()
    end if

    return ""
end function

'-------------------------------------------------------------------------------
' __GetSessionTracks
'-------------------------------------------------------------------------------
function __GetSessionTracks(payload as dynamic) as dynamic
    if payload = invalid then return invalid

    if payload.audioTracks <> invalid then return payload.audioTracks
    if payload.libraryItem <> invalid and payload.libraryItem.media <> invalid then
        if payload.libraryItem.media.audioTracks <> invalid then return payload.libraryItem.media.audioTracks
    end if

    return invalid
end function

'-------------------------------------------------------------------------------
' __GetSessionFiles
'-------------------------------------------------------------------------------
function __GetSessionFiles(payload as dynamic, itemPayload as dynamic) as dynamic
    files = __GetItemFiles(itemPayload)
    if files <> invalid then return files

    if payload <> invalid and payload.libraryItem <> invalid then return __GetItemFiles(payload.libraryItem)
    return __GetItemFiles(payload)
end function

'-------------------------------------------------------------------------------
' __GetItemFiles
'-------------------------------------------------------------------------------
function __GetItemFiles(item as dynamic) as dynamic
    if item = invalid or item.media = invalid then return invalid

    if item.media.audioFiles <> invalid then return item.media.audioFiles
    if item.media.tracks <> invalid then return item.media.tracks
    return invalid
end function

'-------------------------------------------------------------------------------
' __GetFileForTrack
'-------------------------------------------------------------------------------
function __GetFileForTrack(files as dynamic, track as dynamic, fallbackIndex as integer) as dynamic
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
' __GetTrackTitle
'-------------------------------------------------------------------------------
function __GetTrackTitle(file as dynamic, track as dynamic, index as integer) as string
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
' __GetTrackMimeType
'-------------------------------------------------------------------------------
function __GetTrackMimeType(file as dynamic, track as dynamic) as string
    if track <> invalid and track.mimeType <> invalid then return SafeString(track.mimeType, "audio/mpeg")
    if file <> invalid and file.mimeType <> invalid then return SafeString(file.mimeType, "audio/mpeg")
    if file <> invalid and file.metadata <> invalid and file.metadata.mimeType <> invalid then return SafeString(file.metadata.mimeType, "audio/mpeg")
    return "audio/mpeg"
end function

'-------------------------------------------------------------------------------
' __GetTrackDurationSeconds
'-------------------------------------------------------------------------------
function __GetTrackDurationSeconds(file as dynamic, track as dynamic) as integer
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
' __BuildPlaybackUrl
'-------------------------------------------------------------------------------
function __BuildPlaybackUrl(server as string, token as dynamic, sessionId as dynamic, track as dynamic) as string

    log = Playback_CreateLogger("BuildPlaybackUrl")
    log.writeHead()

    if server = invalid or server = "" then
        log.write("Invalid playback request: server is missing.")
        return { ok: false, errorMessage: "No Audiobookshelf server was provided." }
    end if

    if token = invalid or token = "" then
        log.write("Invalid playback request: token is missing.")
        return { ok: false, errorMessage: "No authentication token was provided." }
    end if

    if sessionId = invalid or sessionId = "" then
        log.write("Invalid playback request: sessionId is missing.")
        return { ok: false, errorMessage: "No sessionId was provided." }
    end if

    contentUrl = SafeString(track.contentUrl, "")
    contentUrl = LCase(contentUrl)

    log.write("trackContentUrl = " + contentUrl)

    ' determine if the url is hls
    isHlsUrl = (Instr(1, contentUrl, "/hls") > 0 or Instr(1, contentUrl, ".m3u8") > 0)
    log.write("isHlsUrl = " + isHlsUrl.ToStr())

    ' direct play (non hls) media is compatible with Roku as a playback device
    if sessionId <> invalid and sessionId <> "" and isHlsUrl = false then
        log.write("determined direct play from abs contentUrl")
        return server + "/public/session/" + sessionId + "/track/" + track.index.ToStr()
    end if

    ' roku doesn't support direct play of the media, so using hls to transcode
    ' HLS streaming, or HTTP Live Streaming, is a video streaming protocol developed by Apple that
    ' delivers audio and video content over the internet. It works by breaking video files into
    ' small segments, allowing for adaptive bitrate streaming that adjusts the quality based on
    ' the viewer's network conditions.
    log.write("determined hls from abs contentUrl")
    url = contentUrl
    if Instr(1, LCase(url), "http://") <> 1 and Instr(1, LCase(url), "https://") <> 1 then
        if Left(url, 1) <> "/" then url = "/" + url
        url = server + url
    end if

    url = StringUtils_Replace(url, " ", "%20")
    separator = "?"
    if Instr(1, url, "?") > 0 then separator = "&"
    if token <> invalid and token <> "" then url = url + separator + "token=" + token

    log.write("url result = " + url)
    log.write("")

    return url

end function

