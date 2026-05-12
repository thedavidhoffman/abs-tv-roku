'-------------------------------------------------------------------------------
' Playback_CreateLogger
'-------------------------------------------------------------------------------
function Playback_CreateLogger(suffix = "" as string) as object

    label = "Playback"
    if suffix <> invalid and suffix <> "" then label = label + "::" + suffix

    return CreateLogger(label, false)

end function

'-------------------------------------------------------------------------------
' Playback_Start
'-------------------------------------------------------------------------------
function Playback_Start(request as object) as object

    log = Playback_CreateLogger("Start")
    log.write("executing............")

    ' validate request parameters
    validationResult = __ValidateStartRequest(request, log)
    if validationResult.ok <> true then return validationResult

    ' local working vars
    server = request.server
    token = request.token
    itemId = request.itemId
    title = SafeString(request.title, "")

    ' build the POST body
    bodyData = __BuildPlaybackStartBody(request.forceTranscode = true)
    body = FormatJson(bodyData)

    ' build the POST url
    playbackUrl = server + "/api/items/" + itemId + "/play"

    ' make the playback request
    playbackResult = HttpClient_Request(playbackUrl, "POST", token, body)

  ' request logging
    log.write("request...")
    log.write("      url: " + playbackUrl)
    log.write("      body:")
    log.write("            forceDirectPlay=" + bodyData.forceDirectPlay.ToStr())
    log.write("            forceTranscode=" + bodyData.forceTranscode.ToStr())
    log.write("            supportedMimeTypes:")
    for each mimeType in bodyData.supportedMimeTypes
        log.write("                  " + SafeString(mimeType))
    end for
    log.write("      response status = " + SafeString(playbackResult.status))

    if playbackResult.ok <> true then
        playbackResult.action = "startPlayback"
        playbackResult.requestCounter = request.requestCounter
        return playbackResult
    end if

    playbackSession = playbackResult.data

    ' tracks are the playable audio units. Player uses them to decide what URL to load, what stream format
    ' to use, how to map global ABS time to a Roku track seek position, and how to advance between direct-play files.
    tracks = __MapTracks(server, token, playbackSession, log)
    if tracks.Count() = 0 then
        return { ok: false, action: "startPlayback", errorMessage: "No playable audio tracks were returned." }
    end if

    ' chapters are the navigation/display units. Player uses them for the Chapters list and the right-aligned
    ' chapter title/status. They may not match audio files. A single audio file can have many chapters, and a
    ' multi-file book can have chapters that cross or differ from track boundaries.
    chapters = __MapChapters(playbackSession)

    ' playback data
    action = "startPlayback"
    playbackSessionId = __GetSessionId(playbackSession)
    currentTime = __GetNumber(playbackSession.currentTime)
    duration = __GetNumber(playbackSession.duration)
    playMethod = __GetInteger(playbackSession.playMethod, -1)
    isHlsTranscode = __IsSessionHlsTranscode(playbackSession, tracks)

    ' logging
    log.write("function response...")
    log.write("      action = " + action)
    log.write("      itemId = " + itemId)
    log.write("      title = " + title)
    log.write("      playbackSessionId = " + playbackSessionId)
    log.write("      currentTime = " + SafeString(currentTime))
    log.write("      duration = " + SafeString(duration))
    log.write("      playMethod = " + SafeString(playMethod))
    log.write("      isHlsTranscode = " + SafeString(isHlsTranscode))
    log.write("      requestCounter = " + SafeString(request.requestCounter))

    __LogTracks(log, tracks)
    __LogChapters(log, chapters)

    return {
        ok: true
        action: action
        itemId: itemId
        title: title
        playbackSession: playbackSession
        playbackSessionId: playbackSessionId
        currentTime: currentTime
        duration: duration
        playMethod: playMethod
        isHlsTranscode: isHlsTranscode
        requestCounter: request.requestCounter
        tracks: tracks
        chapters: chapters
    }

end function

'-------------------------------------------------------------------------------
' Playback_CloseSession
'-------------------------------------------------------------------------------
function Playback_CloseSession(request as object) as object

    log = Playback_CreateLogger("CloseSession")
    log.write("executing...")

    server = request.server
    token = request.token
    sessionId = request.sessionId

    if sessionId = invalid or sessionId = "" then
        log.error("No playback session was available to close.")
        return {
            ok: false
            action: "closePlaybackSession"
            errorMessage: "No playback session was available to close."
        }
    end if

    bodyData = {}
    if request.currentTime <> invalid then bodyData.currentTime = request.currentTime
    if request.timeListened <> invalid then bodyData.timeListened = request.timeListened
    if request.duration <> invalid then bodyData.duration = request.duration
    body = __BuildPlaybackProgressBodyJson(request)

    log.write("sessionId=" + sessionId.ToStr() + " currentTime=" + SafeString(bodyData.currentTime, "invalid") + " timeListened=" + SafeString(bodyData.timeListened, "invalid") + " duration=" + SafeString(bodyData.duration, "invalid"))

    result = HttpClient_Request(server + "/api/session/" + sessionId.ToStr() + "/close", "POST", token, body)
    result.action = "closePlaybackSession"
    __LogPlaybackSessionResponse(log, "close", sessionId, result)

    return result

end function

'-------------------------------------------------------------------------------
' Playback_SyncSession
'-------------------------------------------------------------------------------
function Playback_SyncSession(request as object) as object

    log = Playback_CreateLogger("SyncSession")

    server = request.server
    token = request.token
    sessionId = request.sessionId

    if sessionId = invalid or sessionId = "" then
        return { ok: false, action: "syncPlaybackSession", errorMessage: "No playback session was available to sync." }
    end if

    bodyData = {}
    if request.currentTime <> invalid then bodyData.currentTime = request.currentTime
    if request.timeListened <> invalid then bodyData.timeListened = request.timeListened
    if request.duration <> invalid then bodyData.duration = request.duration
    body = __BuildPlaybackProgressBodyJson(request)

    log.write("sessionId=" + sessionId.ToStr() + " currentTime=" + SafeString(bodyData.currentTime, "invalid") + " timeListened=" + SafeString(bodyData.timeListened, "invalid") + " duration=" + SafeString(bodyData.duration, "invalid"))

    result = HttpClient_Request(server + "/api/session/" + sessionId.ToStr() + "/sync", "POST", token, body)
    result.action = "syncPlaybackSession"
    __LogPlaybackSessionResponse(log, "sync", sessionId, result)

    return result

end function

'-------------------------------------------------------------------------------
' __BuildPlaybackProgressBodyJson
'-------------------------------------------------------------------------------
function __BuildPlaybackProgressBodyJson(request as dynamic) as string
    parts = []
    if request.currentTime <> invalid then parts.Push(Chr(34) + "currentTime" + Chr(34) + ":" + __JsonNumber(request.currentTime))
    if request.timeListened <> invalid then parts.Push(Chr(34) + "timeListened" + Chr(34) + ":" + __JsonNumber(request.timeListened))
    if request.duration <> invalid then parts.Push(Chr(34) + "duration" + Chr(34) + ":" + __JsonNumber(request.duration))
    return "{" + __JoinJsonParts(parts) + "}"
end function

'-------------------------------------------------------------------------------
' __LogPlaybackSessionResponse
'-------------------------------------------------------------------------------
sub __LogPlaybackSessionResponse(log as object, operation as string, sessionId as dynamic, result as dynamic)
    if log = invalid then return

    status = "invalid"
    ok = "invalid"
    message = ""
    hasData = false
    if result <> invalid then
        status = SafeString(result.status, "invalid")
        ok = SafeString(result.ok, "invalid")
        message = SafeString(result.errorMessage, "")
    end if

    log.write(operation + " response sessionId=" + SafeString(sessionId, "invalid") + " status=" + status + " ok=" + ok + " hasData=" + hasData.ToStr() + " errorMessage=" + message)
end sub

'-------------------------------------------------------------------------------
' __ValidateStartRequest
'-------------------------------------------------------------------------------
function __ValidateStartRequest(request as dynamic, log as object) as object
    if request = invalid then return __ValidationError(log, "Invalid playback request: request is invalid.")
    if Type(request) <> "roAssociativeArray" then return __ValidationError(log, "Invalid playback request: request type is " + Type(request) + ".")
    if request.server = invalid or request.server = "" then return __ValidationError(log, "Invalid playback request: server is missing.")
    if request.token = invalid or request.token = "" then return __ValidationError(log, "Invalid playback request: token is missing.")
    if request.itemId = invalid or request.itemId = "" then return __ValidationError(log, "Invalid playback request: itemId is missing.")
    return { ok: true }
end function

'-------------------------------------------------------------------------------
' __ValidationError
'-------------------------------------------------------------------------------
function __ValidationError(log as object, message as string) as object
    log.error(message)
    return { ok: false, action: "startPlayback", errorMessage: message }
end function

'-------------------------------------------------------------------------------
' __BuildPlaybackStartBody
'-------------------------------------------------------------------------------
function __BuildPlaybackStartBody(forceTranscode = false as boolean) as object
    deviceInfo = CreateObject("roDeviceInfo")
    model = deviceInfo.GetModel()
    modelDisplayName = deviceInfo.GetModelDisplayName()

    return {
        deviceInfo: {
            clientName: "ABSTV"
            clientVersion: "0.1.0"
            manufacturer: "Roku"
            model: modelDisplayName + " " + model
        }
        forceDirectPlay: false
        forceTranscode: forceTranscode
        supportedMimeTypes: [
            "audio/mpeg"
            "audio/mp4"
            "audio/aac"
            "application/vnd.apple.mpegurl"
            "application/x-mpegURL"
            "application/x-mpegurl"
            "application/vnd.apple.mpegURL"
        ]
        mediaPlayer: "roku"
    }
end function

'-------------------------------------------------------------------------------
' __MapTracks
'-------------------------------------------------------------------------------
function __MapTracks(server as string, token as dynamic, session as dynamic, log as object) as object
    mappedTracks = []
    tracks = invalid
    if session <> invalid then tracks = session.audioTracks
    sessionId = __GetSessionId(session)

    log.write("playback mapping audioTracks=" + Array_GetCount(tracks).ToStr())

    if tracks = invalid then return mappedTracks

    for i = 0 to tracks.Count() - 1
        track = tracks[i]
        if track <> invalid then
            url = __BuildTrackUrl(server, token, sessionId, track)
            if url <> "" then
                mappedTracks.Push({
                    index: __GetTrackIndex(track, i)
                    url: url
                    title: __GetTrackTitle(track, i)
                    startOffset: __GetNumber(track.startOffset)
                    durationSeconds: __GetNumber(track.duration)
                    contentUrl: SafeString(track.contentUrl, "")
                    mimeType: __GetTrackMimeType(track)
                    isHls: __IsHlsTrack(track)
                })
            end if
        end if
    end for

    return mappedTracks
end function

'-------------------------------------------------------------------------------
' __MapChapters
'-------------------------------------------------------------------------------
function __MapChapters(session as dynamic) as object
    chapters = []
    if session = invalid or session.chapters = invalid or session.chapters.Count() = 0 then return chapters

    for i = 0 to session.chapters.Count() - 1
        chapter = session.chapters[i]
        if chapter <> invalid then
            startTime = __GetChapterStart(chapter)
            endTime = __GetChapterEnd(chapter, session, i)
            duration = endTime - startTime
            if duration < 0 then duration = 0
            chapters.Push({
                index: i
                title: __GetChapterTitle(chapter, i)
                startOffset: startTime
                durationSeconds: duration
                isChapter: true
            })
        end if
    end for

    return chapters
end function

'-------------------------------------------------------------------------------
' __BuildTrackUrl
'-------------------------------------------------------------------------------
function __BuildTrackUrl(server as string, token as dynamic, sessionId as dynamic, track as dynamic) as string
    contentUrl = SafeString(track.contentUrl, "")
    if contentUrl = "" then return ""

    if __IsHlsUrl(contentUrl) then return __BuildAuthenticatedContentUrl(server, token, contentUrl)
    if sessionId <> invalid and sessionId <> "" then return server + "/public/session/" + sessionId.ToStr() + "/track/" + __GetTrackIndex(track, 0).ToStr()

    return __BuildAuthenticatedContentUrl(server, token, contentUrl)
end function

'-------------------------------------------------------------------------------
' __BuildAuthenticatedContentUrl
'-------------------------------------------------------------------------------
function __BuildAuthenticatedContentUrl(server as string, token as dynamic, contentUrl as string) as string
    if Instr(1, LCase(contentUrl), "http://") <> 1 and Instr(1, LCase(contentUrl), "https://") <> 1 then
        if Left(contentUrl, 1) <> "/" then contentUrl = "/" + contentUrl
        contentUrl = server + contentUrl
    end if

    contentUrl = String_Replace(contentUrl, " ", "%20")
    separator = "?"
    if Instr(1, contentUrl, "?") > 0 then separator = "&"
    if token <> invalid and token <> "" then contentUrl = contentUrl + separator + "token=" + token

    return contentUrl
end function

'-------------------------------------------------------------------------------
' __LogTracks
'-------------------------------------------------------------------------------
sub __LogTracks(log as object, tracks as dynamic)
    log.write("Mapped tracks:")

    if tracks = invalid or tracks.Count() = 0 then
        log.write("    none")
        return
    end if

    for i = 0 to tracks.Count() - 1
        track = tracks[i]
        if track <> invalid then
            log.writeBracketed([
                i.ToStr()
                "trackIndex=" + SafeString(track.index)
                SafeString(track.title)
                "startOffset=" + SafeString(track.startOffset)
                "duration=" + SafeString(track.durationSeconds)
                SafeString(track.mimeType)
            ])
        else
            log.write("    invalid track")
        end if
    end for
end sub

'-------------------------------------------------------------------------------
' __LogChapters
'-------------------------------------------------------------------------------
sub __LogChapters(log as object, chapters as dynamic)
    log.write("Mapped chapters:")

    if chapters = invalid or chapters.Count() = 0 then
        log.write("    none")
        return
    end if

    for i = 0 to chapters.Count() - 1
        chapter = chapters[i]
        if chapter <> invalid then
            log.writeBracketed([
                i.ToStr()
                "chapterIndex=" + SafeString(chapter.index)
                SafeString(chapter.title)
                "startOffset=" + SafeString(chapter.startOffset)
                "duration=" + SafeString(chapter.durationSeconds)
            ])
        else
            log.write("    invalid chapter")
        end if
    end for
end sub

'-------------------------------------------------------------------------------
' __IsSessionHlsTranscode
'-------------------------------------------------------------------------------
function __IsSessionHlsTranscode(session as dynamic, tracks as object) as boolean
    if session <> invalid and session.playMethod <> invalid and __GetInteger(session.playMethod, -1) <> 0 then return true
    if tracks <> invalid and tracks.Count() = 1 and tracks[0] <> invalid and tracks[0].isHls = true then return true
    return false
end function

'-------------------------------------------------------------------------------
' __IsHlsTrack
'-------------------------------------------------------------------------------
function __IsHlsTrack(track as dynamic) as boolean
    if track = invalid then return false
    return __IsHlsUrl(SafeString(track.contentUrl, ""))
end function

'-------------------------------------------------------------------------------
' __IsHlsUrl
'-------------------------------------------------------------------------------
function __IsHlsUrl(url as string) as boolean
    text = LCase(url)
    return Instr(1, text, "/hls") > 0 or Instr(1, text, ".m3u8") > 0
end function

'-------------------------------------------------------------------------------
' __GetSessionId
'-------------------------------------------------------------------------------
function __GetSessionId(session as dynamic) as dynamic
    if session = invalid then return invalid
    return session.id
end function

'-------------------------------------------------------------------------------
' __GetTrackIndex
'-------------------------------------------------------------------------------
function __GetTrackIndex(track as dynamic, fallbackIndex as integer) as integer
    if track <> invalid and track.index <> invalid then return __GetInteger(track.index, fallbackIndex)
    return fallbackIndex
end function

'-------------------------------------------------------------------------------
' __GetTrackTitle
'-------------------------------------------------------------------------------
function __GetTrackTitle(track as dynamic, index as integer) as string
    if track <> invalid then
        title = FirstNonEmpty([track.title, track.name], "")
        if title <> "" and title <> "Audiobook" then return title
    end if

    return "Track " + (index + 1).ToStr()
end function

'-------------------------------------------------------------------------------
' __GetTrackMimeType
'-------------------------------------------------------------------------------
function __GetTrackMimeType(track as dynamic) as string
    if track <> invalid and track.mimeType <> invalid then return SafeString(track.mimeType, "audio/mpeg")
    return "audio/mpeg"
end function

'-------------------------------------------------------------------------------
' __GetChapterStart
'-------------------------------------------------------------------------------
function __GetChapterStart(chapter as dynamic) as float
    if chapter.start <> invalid then return __GetNumber(chapter.start)
    if chapter.startTime <> invalid then return __GetNumber(chapter.startTime)
    if chapter.startOffset <> invalid then return __GetNumber(chapter.startOffset)
    return 0
end function

'-------------------------------------------------------------------------------
' __GetChapterEnd
'-------------------------------------------------------------------------------
function __GetChapterEnd(chapter as dynamic, session as dynamic, index as integer) as float
    if chapter.end <> invalid then return __GetNumber(chapter.end)
    if chapter.endTime <> invalid then return __GetNumber(chapter.endTime)
    if chapter.duration <> invalid then return __GetChapterStart(chapter) + __GetNumber(chapter.duration)
    if session <> invalid and session.chapters <> invalid and index + 1 < session.chapters.Count() then return __GetChapterStart(session.chapters[index + 1])
    if session <> invalid and session.duration <> invalid then return __GetNumber(session.duration)
    return __GetChapterStart(chapter)
end function

'-------------------------------------------------------------------------------
' __GetChapterTitle
'-------------------------------------------------------------------------------
function __GetChapterTitle(chapter as dynamic, index as integer) as string
    return FirstNonEmpty([chapter.title, chapter.name], "Chapter " + (index + 1).ToStr())
end function

'-------------------------------------------------------------------------------
' __GetNumber
'-------------------------------------------------------------------------------
function __GetNumber(value as dynamic) as float
    if value = invalid then return 0
    return val(value.ToStr())
end function

'-------------------------------------------------------------------------------
' __GetInteger
'-------------------------------------------------------------------------------
function __GetInteger(value as dynamic, fallback as integer) as integer
    if value = invalid then return fallback
    return int(val(value.ToStr()))
end function

'-------------------------------------------------------------------------------
' __JoinJsonParts
'-------------------------------------------------------------------------------
function __JoinJsonParts(parts as object) as string
    if parts = invalid or parts.Count() = 0 then return ""

    text = ""
    for i = 0 to parts.Count() - 1
        if i > 0 then text = text + ","
        text = text + parts[i]
    end for

    return text
end function

'-------------------------------------------------------------------------------
' __JsonNumber
'-------------------------------------------------------------------------------
function __JsonNumber(value as dynamic) as string
    if value = invalid then return "0"
    numberValue = val(value.ToStr())
    text = numberValue.ToStr()
    if Instr(1, text, ",") > 0 then text = String_Replace(text, ",", "")
    return text
end function
