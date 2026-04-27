'-------------------------------------------------------------------------------
' Playback_Start
'-------------------------------------------------------------------------------
function Playback_Start(request as Object) as Object
    server = NormalizeServerUrl(request.server)
    token = request.token
    itemId = request.itemId

    if itemId = invalid or itemId = "" then
        return { ok: false, errorMessage: "No audiobook was selected." }
    end if

    body = FormatJson({
        deviceInfo: {
            clientName: "ABSTV"
            clientVersion: "0.1.0"
            manufacturer: "Roku"
            model: "Roku"
        }
        forceDirectPlay: false
        forceTranscode: false
        supportedMimeTypes: [
            "audio/mpeg"
        ]
        mediaPlayer: "roku"
    })

    result = HttpClient_Request(server + "/api/items/" + itemId + "/play", "POST", token, body)
    if result.ok <> true then return result

    itemResult = HttpClient_Request(server + "/api/items/" + itemId, "GET", token, invalid)
    itemPayload = invalid
    if itemResult.ok = true then itemPayload = itemResult.data

    tracks = Playback_Internal_MapTracks(server, token, result.data, itemPayload)
    if tracks.Count() = 0 then
        return { ok: false, errorMessage: "No playable audio tracks were returned." }
    end if

    return {
        ok: true
        action: "startPlayback"
        itemId: itemId
        title: request.title
        playbackSession: result.data
        tracks: tracks
    }
end function

'-------------------------------------------------------------------------------
' Playback_Internal_MapTracks
'-------------------------------------------------------------------------------
function Playback_Internal_MapTracks(server as String, token as Dynamic, payload as Dynamic, itemPayload as Dynamic) as Object
    mappedTracks = []
    tracks = Playback_Internal_GetSessionTracks(payload)
    files = Playback_Internal_GetSessionFiles(payload, itemPayload)
    sessionId = invalid

    if payload <> invalid and payload.id <> invalid then sessionId = payload.id

    ? "playback mapping"; " audioTracks="; Playback_Internal_GetArrayCount(tracks); " files="; Playback_Internal_GetArrayCount(files)

    if files <> invalid and files.Count() > 0 and tracks <> invalid and tracks.Count() = 1 then
        track = tracks[0]
        startPositionSeconds = 0
        for i = 0 to files.Count() - 1
            file = files[i]
            durationSeconds = Playback_Internal_GetTrackDurationSeconds(file, track)
            mappedTracks.Push({
                url: Playback_Internal_BuildUrl(server, token, sessionId, track)
                title: Playback_Internal_GetTrackTitle(file, track, i)
                durationSeconds: durationSeconds
                startPositionSeconds: startPositionSeconds
                mimeType: Playback_Internal_GetTrackMimeType(file, track)
            })
            startPositionSeconds = startPositionSeconds + durationSeconds
        end for
    else if files <> invalid and files.Count() > 0 and (tracks = invalid or files.Count() > tracks.Count()) then
        for i = 0 to files.Count() - 1
            file = files[i]
            track = Playback_Internal_GetTrackForFileIndex(tracks, file, i)
            url = Playback_Internal_BuildFileUrl(server, token, sessionId, file, track, i)
            if url <> "" then
                mappedTracks.Push({
                    url: url
                    title: Playback_Internal_GetTrackTitle(file, track, i)
                    durationSeconds: Playback_Internal_GetTrackDurationSeconds(file, track)
                    mimeType: Playback_Internal_GetTrackMimeType(file, track)
                })
            end if
        end for
    else if tracks <> invalid then
        for i = 0 to tracks.Count() - 1
            track = tracks[i]
            file = Playback_Internal_GetFileForTrack(files, track, i)
            contentUrl = invalid
            if track.contentUrl <> invalid then contentUrl = track.contentUrl
            if contentUrl <> invalid and contentUrl <> "" then
                mappedTracks.Push({
                    url: Playback_Internal_BuildUrl(server, token, sessionId, track)
                    title: Playback_Internal_GetTrackTitle(file, track, i)
                    durationSeconds: Playback_Internal_GetTrackDurationSeconds(file, track)
                    mimeType: Playback_Internal_GetTrackMimeType(file, track)
                })
            end if
        end for
    end if

    return mappedTracks
end function

'-------------------------------------------------------------------------------
' Playback_Internal_GetArrayCount
'-------------------------------------------------------------------------------
function Playback_Internal_GetArrayCount(values as Dynamic) as Integer
    if values = invalid then return 0
    return values.Count()
end function

'-------------------------------------------------------------------------------
' Playback_Internal_GetTrackForFileIndex
'-------------------------------------------------------------------------------
function Playback_Internal_GetTrackForFileIndex(tracks as Dynamic, file as Dynamic, fallbackIndex as Integer) as Dynamic
    if tracks = invalid or tracks.Count() = 0 then return invalid

    fileIndex = Playback_Internal_GetFileIndex(file, fallbackIndex)
    for each track in tracks
        if track.index <> invalid and int(val(track.index.ToStr())) = fileIndex then return track
        if track.trackNum <> invalid and int(val(track.trackNum.ToStr())) = fileIndex then return track
    end for

    if fallbackIndex >= 0 and fallbackIndex < tracks.Count() then return tracks[fallbackIndex]
    return invalid
end function

'-------------------------------------------------------------------------------
' Playback_Internal_GetFileIndex
'-------------------------------------------------------------------------------
function Playback_Internal_GetFileIndex(file as Dynamic, fallbackIndex as Integer) as Integer
    if file <> invalid then
        if file.index <> invalid then return int(val(file.index.ToStr()))
        if file.trackNum <> invalid then return int(val(file.trackNum.ToStr()))
    end if

    return fallbackIndex
end function

'-------------------------------------------------------------------------------
' Playback_Internal_BuildFileUrl
'-------------------------------------------------------------------------------
function Playback_Internal_BuildFileUrl(server as String, token as Dynamic, sessionId as Dynamic, file as Dynamic, track as Dynamic, fallbackIndex as Integer) as String
    if track <> invalid and track.contentUrl <> invalid and track.contentUrl <> "" then
        return Playback_Internal_BuildUrl(server, token, sessionId, track)
    end if

    if file <> invalid and file.contentUrl <> invalid and file.contentUrl <> "" then
        return Playback_Internal_BuildUrl(server, token, sessionId, file)
    end if

    if sessionId <> invalid and sessionId <> "" then
        return server + "/public/session/" + sessionId + "/track/" + Playback_Internal_GetFileIndex(file, fallbackIndex).ToStr()
    end if

    return ""
end function

'-------------------------------------------------------------------------------
' Playback_Internal_GetSessionTracks
'-------------------------------------------------------------------------------
function Playback_Internal_GetSessionTracks(payload as Dynamic) as Dynamic
    if payload = invalid then return invalid

    if payload.audioTracks <> invalid then return payload.audioTracks
    if payload.libraryItem <> invalid and payload.libraryItem.media <> invalid then
        if payload.libraryItem.media.audioTracks <> invalid then return payload.libraryItem.media.audioTracks
    end if

    return invalid
end function

'-------------------------------------------------------------------------------
' Playback_Internal_GetSessionFiles
'-------------------------------------------------------------------------------
function Playback_Internal_GetSessionFiles(payload as Dynamic, itemPayload as Dynamic) as Dynamic
    files = Playback_Internal_GetItemFiles(itemPayload)
    if files <> invalid then return files

    if payload <> invalid and payload.libraryItem <> invalid then return Playback_Internal_GetItemFiles(payload.libraryItem)
    return Playback_Internal_GetItemFiles(payload)
end function

'-------------------------------------------------------------------------------
' Playback_Internal_GetItemFiles
'-------------------------------------------------------------------------------
function Playback_Internal_GetItemFiles(item as Dynamic) as Dynamic
    if item = invalid or item.media = invalid then return invalid

    if item.media.audioFiles <> invalid then return item.media.audioFiles
    if item.media.tracks <> invalid then return item.media.tracks
    return invalid
end function

'-------------------------------------------------------------------------------
' Playback_Internal_GetFileForTrack
'-------------------------------------------------------------------------------
function Playback_Internal_GetFileForTrack(files as Dynamic, track as Dynamic, fallbackIndex as Integer) as Dynamic
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
' Playback_Internal_GetTrackTitle
'-------------------------------------------------------------------------------
function Playback_Internal_GetTrackTitle(file as Dynamic, track as Dynamic, index as Integer) as String
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
' Playback_Internal_GetTrackMimeType
'-------------------------------------------------------------------------------
function Playback_Internal_GetTrackMimeType(file as Dynamic, track as Dynamic) as String
    if track <> invalid and track.mimeType <> invalid then return SafeString(track.mimeType, "audio/mpeg")
    if file <> invalid and file.mimeType <> invalid then return SafeString(file.mimeType, "audio/mpeg")
    if file <> invalid and file.metadata <> invalid and file.metadata.mimeType <> invalid then return SafeString(file.metadata.mimeType, "audio/mpeg")
    return "audio/mpeg"
end function

'-------------------------------------------------------------------------------
' Playback_Internal_GetTrackDurationSeconds
'-------------------------------------------------------------------------------
function Playback_Internal_GetTrackDurationSeconds(file as Dynamic, track as Dynamic) as Integer
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
' Playback_Internal_BuildUrl
'-------------------------------------------------------------------------------
function Playback_Internal_BuildUrl(server as String, token as Dynamic, sessionId as Dynamic, track as Dynamic) as String
    contentUrl = SafeString(track.contentUrl, "")

    if sessionId <> invalid and sessionId <> "" and Instr(1, LCase(contentUrl), "/hls") <> 1 then
        return server + "/public/session/" + sessionId + "/track/" + track.index.ToStr()
    end if

    url = contentUrl
    if Instr(1, LCase(url), "http://") <> 1 and Instr(1, LCase(url), "https://") <> 1 then
        if Left(url, 1) <> "/" then url = "/" + url
        url = server + url
    end if

    url = Playback_Internal_ReplaceString(url, " ", "%20")
    separator = "?"
    if Instr(1, url, "?") > 0 then separator = "&"
    if token <> invalid and token <> "" then url = url + separator + "token=" + token
    return url
end function

'-------------------------------------------------------------------------------
' Playback_Internal_ReplaceString
'-------------------------------------------------------------------------------
function Playback_Internal_ReplaceString(value as String, oldValue as String, newValue as String) as String
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
