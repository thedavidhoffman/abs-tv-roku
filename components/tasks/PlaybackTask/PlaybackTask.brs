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
        m.top.response = startPlayback(request)
    else if action = "syncPlaybackSession" then
        m.top.response = syncPlaybackSession(request)
    else if action = "closePlaybackSession" then
        m.top.response = closePlaybackSession(request)
    else
        m.top.response = { ok: false, errorMessage: "Unknown playback request action." }
    end if
end sub

'-------------------------------------------------------------------------------
' createPlaybackLogger
'-------------------------------------------------------------------------------
function createPlaybackLogger(suffix = "" as string) as object

    label = "Playback"
    if suffix <> invalid and suffix <> "" then label = label + "::" + suffix

    return CreateLogger(label)

end function

'-------------------------------------------------------------------------------
' startPlayback
'-------------------------------------------------------------------------------
function startPlayback(request as object) as object

    log = createPlaybackLogger("Start")
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
    forceTranscode = request.forceTranscode = true
    forceDirectPlay = request.forceDirectPlay = true
    if forceTranscode = true then forceDirectPlay = false

    ' Build request JSON with Json.brs helpers instead of FormatJson(), because Roku
    ' lowercases object keys during serialization and ABS requires exact key casing
    ' for fields such as supportedMimeTypes.
    bodyData = __BuildPlaybackStartBody(forceTranscode, forceDirectPlay)
    body = __BuildPlaybackStartBodyJson(bodyData)

    ' build the POST url
    playbackUrl = server + "/api/items/" + itemId + "/play"

    ' make the playback request
    playbackResult = HttpClient_Request(playbackUrl, "POST", token, body)

  ' request logging
    log.write("request...")
    log.write("      url: " + playbackUrl)
    log.write("      body:")
    log.writeJson(body, 6)
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
    chapters = __MapChapters(playbackSession, tracks, log)

    ' playback data
    action = "startPlayback"
    playbackSessionId = __GetSessionId(playbackSession)
    currentTime = __GetNumber(playbackSession.currentTime)
    duration = __GetNumber(playbackSession.duration)
    playMethod = __GetInteger(playbackSession.playMethod, -1)
    isHlsTranscode = __IsSessionHlsTranscode(playbackSession, tracks)
    if forceDirectPlay = true and isHlsTranscode = true then log.error("Force direct play request returned an HLS/transcode session.")

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
    __LogAudioTrackDetails(log, playbackSession)
    __LogSourceAudioFiles(log, playbackSession)
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
' closePlaybackSession
'-------------------------------------------------------------------------------
function closePlaybackSession(request as object) as object

    log = createPlaybackLogger("CloseSession")
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

    body = __BuildPlaybackProgressBodyJson(request)

    __LogPlaybackProgressRequest(log, sessionId, request)

    result = HttpClient_Request(server + "/api/session/" + sessionId.ToStr() + "/close", "POST", token, body)
    result.action = "closePlaybackSession"
    __LogPlaybackSessionResponse(log, "close", sessionId, result)

    return result

end function

'-------------------------------------------------------------------------------
' syncPlaybackSession
'-------------------------------------------------------------------------------
function syncPlaybackSession(request as object) as object

    log = createPlaybackLogger("SyncSession")

    server = request.server
    token = request.token
    sessionId = request.sessionId

    if sessionId = invalid or sessionId = "" then
        return { ok: false, action: "syncPlaybackSession", errorMessage: "No playback session was available to sync." }
    end if

    body = __BuildPlaybackProgressBodyJson(request)

    __LogPlaybackProgressRequest(log, sessionId, request)

    result = HttpClient_Request(server + "/api/session/" + sessionId.ToStr() + "/sync", "POST", token, body)
    result.action = "syncPlaybackSession"
    '__LogPlaybackSessionResponse(log, "sync", sessionId, result)

    return result

end function

'-------------------------------------------------------------------------------
' __BuildPlaybackProgressBodyJson
'-------------------------------------------------------------------------------
function __BuildPlaybackProgressBodyJson(request as dynamic) as string
    parts = []
    if request.currentTime <> invalid then parts.Push(Json_NumberPair("currentTime", request.currentTime))
    if request.timeListened <> invalid then parts.Push(Json_NumberPair("timeListened", request.timeListened))
    if request.duration <> invalid then parts.Push(Json_NumberPair("duration", request.duration))
    return Json_Object(parts)
end function

'-------------------------------------------------------------------------------
' __LogPlaybackProgressRequest
'-------------------------------------------------------------------------------
sub __LogPlaybackProgressRequest(log as object, sessionId as dynamic, request as dynamic)
    if request.currentTime = invalid and request.timeListened = invalid and request.duration = invalid then
        log.write("sessionId=" + sessionId.ToStr() + " progressData=omitted")
        return
    end if

    log.write("sessionId=" + sessionId.ToStr() + " currentTime=" + SafeString(request.currentTime, "invalid") + " timeListened=" + SafeString(request.timeListened, "invalid") + " duration=" + SafeString(request.duration, "invalid"))
end sub

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
function __BuildPlaybackStartBody(forceTranscode = false as boolean, forceDirectPlay = false as boolean) as object
    deviceInfo = CreateObject("roDeviceInfo")
    model = deviceInfo.GetModel()
    modelDisplayName = deviceInfo.GetModelDisplayName()

    return {
        deviceInfo: {
            clientName: "ABSTV"
            clientVersion: "1.1.2"
            manufacturer: "Roku"
            model: modelDisplayName + " " + model
        }
        forceDirectPlay: forceDirectPlay
        forceTranscode: forceTranscode
        supportedMimeTypes: __GetSupportedMimeTypes(forceTranscode)
        mediaPlayer: "roku"
    }
end function

'-------------------------------------------------------------------------------
' __BuildPlaybackStartBodyJson
'-------------------------------------------------------------------------------
function __BuildPlaybackStartBodyJson(bodyData as object) as string
    deviceInfo = bodyData.deviceInfo
    deviceInfoParts = [
        Json_Pair("clientName", deviceInfo.clientName)
        Json_Pair("clientVersion", deviceInfo.clientVersion)
        Json_Pair("manufacturer", deviceInfo.manufacturer)
        Json_Pair("model", deviceInfo.model)
    ]

    parts = [
        Json_ObjectPair("deviceInfo", deviceInfoParts)
        Json_BooleanPair("forceDirectPlay", bodyData.forceDirectPlay)
        Json_BooleanPair("forceTranscode", bodyData.forceTranscode)
        Json_ArrayPair("supportedMimeTypes", bodyData.supportedMimeTypes)
        Json_Pair("mediaPlayer", bodyData.mediaPlayer)
    ]

    return Json_Object(parts)
end function

'-------------------------------------------------------------------------------
' __GetSupportedMimeTypes
'-------------------------------------------------------------------------------
function __GetSupportedMimeTypes(includeHls as boolean) as object
    mimeTypes = [
        "audio/mpeg"
        "audio/mp3"
        "audio/mp4"
        "audio/aac"
        "audio/m4a"
        "audio/x-m4a"
        "audio/m4b"
        "audio/x-m4b"
        "audio/x-mpeg"
    ]

    if includeHls <> true then return mimeTypes

    mimeTypes.Push("application/vnd.apple.mpegurl")
    mimeTypes.Push("application/x-mpegURL")
    mimeTypes.Push("application/x-mpegurl")
    mimeTypes.Push("application/vnd.apple.mpegURL")

    return mimeTypes
end function

'-------------------------------------------------------------------------------
' __MapTracks
'-------------------------------------------------------------------------------
function __MapTracks(server as string, token as dynamic, session as dynamic, log as object) as object
    mappedTracks = []
    tracks = invalid
    if session <> invalid then tracks = session.audioTracks
    audioFiles = __GetSourceAudioFiles(session)
    sessionId = __GetSessionId(session)

    log.write("playback mapping audioTracks=" + Array_GetCount(tracks).ToStr())

    if tracks = invalid then return mappedTracks

    for i = 0 to tracks.Count() - 1
        track = tracks[i]
        if track <> invalid then
            url = __BuildTrackUrl(server, token, sessionId, track)
            if url <> "" then
                trackIndex = __GetTrackIndex(track, i)
                sourceAudioFile = __GetSourceAudioFile(audioFiles, trackIndex, i)
                mappedTracks.Push({
                    index: trackIndex
                    url: url
                    title: __GetTrackTitle(track, i)
                    startOffset: __GetNumber(track.startOffset)
                    durationSeconds: __GetNumber(track.duration)
                    contentUrl: SafeString(track.contentUrl, "")
                    mimeType: __GetTrackMimeType(track)
                    isHls: __IsHlsTrack(track)
                    codec: __GetSourceAudioFileField(sourceAudioFile, "codec")
                    bitRate: __GetSourceAudioFileField(sourceAudioFile, "bitRate")
                    channels: __GetSourceAudioFileField(sourceAudioFile, "channels")
                    channelLayout: __GetSourceAudioFileField(sourceAudioFile, "channelLayout")
                    sampleRate: __GetSourceAudioFileField(sourceAudioFile, "sampleRate")
                    format: __GetSourceAudioFileField(sourceAudioFile, "format")
                })
            end if
        end if
    end for

    return mappedTracks
end function

'-------------------------------------------------------------------------------
' __GetSourceAudioFiles
'-------------------------------------------------------------------------------
function __GetSourceAudioFiles(session as dynamic) as dynamic
    if session <> invalid and session.libraryItem <> invalid and session.libraryItem.media <> invalid then
        return session.libraryItem.media.audioFiles
    end if

    return invalid
end function

'-------------------------------------------------------------------------------
' __GetSourceAudioFile
'-------------------------------------------------------------------------------
function __GetSourceAudioFile(audioFiles as dynamic, trackIndex as integer, fallbackIndex as integer) as dynamic
    if audioFiles = invalid or audioFiles.Count() = 0 then return invalid

    for each audioFile in audioFiles
        if audioFile <> invalid and audioFile.index <> invalid and __GetInteger(audioFile.index, -1) = trackIndex then
            return audioFile
        end if
    end for

    if fallbackIndex >= 0 and fallbackIndex < audioFiles.Count() then return audioFiles[fallbackIndex]
    return invalid
end function

'-------------------------------------------------------------------------------
' __GetSourceAudioFileField
'-------------------------------------------------------------------------------
function __GetSourceAudioFileField(audioFile as dynamic, fieldName as string) as dynamic
    if audioFile = invalid then return invalid
    fieldValue = audioFile[fieldName]
    if fieldValue <> invalid then return fieldValue

    metadata = audioFile.metadata
    if metadata <> invalid then return metadata[fieldName]

    return invalid
end function

'-------------------------------------------------------------------------------
' __MapChapters
'-------------------------------------------------------------------------------
function __MapChapters(session as dynamic, tracks as dynamic, log as object) as object
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

    ' Some ABS playback sessions can return a partial chapter list whose first
    ' chapter starts at 0 even though it maps to a later audio file. In that case
    ' use audio tracks as chapter items so navigation still covers the full book.
    if __ShouldUseTracksAsChapters(chapters, tracks, session) then
        log.error("session chapters appear partial; using audio tracks as chapter items")
        return __MapTracksAsChapters(tracks)
    end if

    return chapters
end function

'-------------------------------------------------------------------------------
' __ShouldUseTracksAsChapters
'-------------------------------------------------------------------------------
function __ShouldUseTracksAsChapters(chapters as dynamic, tracks as dynamic, session as dynamic) as boolean
    if chapters = invalid or tracks = invalid then return false
    if chapters.Count() = 0 or tracks.Count() = 0 then return false
    if chapters.Count() >= tracks.Count() then return false

    chapterCoverage = __GetChapterCoverageSeconds(chapters)
    mediaDuration = __GetMediaDurationSeconds(session, tracks)
    if mediaDuration <= 0 then return false

    return chapterCoverage < (mediaDuration * 0.9)
end function

'-------------------------------------------------------------------------------
' __MapTracksAsChapters
'-------------------------------------------------------------------------------
function __MapTracksAsChapters(tracks as dynamic) as object
    chapters = []
    if tracks = invalid then return chapters

    for i = 0 to tracks.Count() - 1
        track = tracks[i]
        if track <> invalid then
            chapters.Push({
                index: i
                title: SafeString(track.title, "Track " + (i + 1).ToStr())
                startOffset: __GetNumber(track.startOffset)
                durationSeconds: __GetNumber(track.durationSeconds)
                isChapter: true
                source: "track"
            })
        end if
    end for

    return chapters
end function

'-------------------------------------------------------------------------------
' __GetChapterCoverageSeconds
'-------------------------------------------------------------------------------
function __GetChapterCoverageSeconds(chapters as dynamic) as float
    if chapters = invalid or chapters.Count() = 0 then return 0

    lastChapter = chapters[chapters.Count() - 1]
    if lastChapter = invalid then return 0

    return __GetNumber(lastChapter.startOffset) + __GetNumber(lastChapter.durationSeconds)
end function

'-------------------------------------------------------------------------------
' __GetMediaDurationSeconds
'-------------------------------------------------------------------------------
function __GetMediaDurationSeconds(session as dynamic, tracks as dynamic) as float
    if session <> invalid and session.duration <> invalid then return __GetNumber(session.duration)
    if tracks = invalid then return 0

    duration = 0.0
    for each track in tracks
        if track <> invalid then duration = duration + __GetNumber(track.durationSeconds)
    end for

    return duration
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
' __LogAudioTrackDetails
'-------------------------------------------------------------------------------
sub __LogAudioTrackDetails(log as object, session as dynamic)
    log.write("Audio track details:")

    tracks = invalid
    if session <> invalid then tracks = session.audioTracks
    if tracks = invalid or tracks.Count() = 0 then
        log.write("    none")
        return
    end if

    for i = 0 to tracks.Count() - 1
        track = tracks[i]
        if track <> invalid then
            parts = [i.ToStr()]
            __PushLogField(parts, "index", track.index)
            __PushLogField(parts, "contentUrl", track.contentUrl)
            __PushLogField(parts, "mimeType", track.mimeType)
            __PushLogField(parts, "duration", track.duration)
            __PushTrackMetadataFields(parts, track.metadata)
            log.writeBracketed(parts)
        else
            log.write("    invalid track")
        end if
    end for
end sub

'-------------------------------------------------------------------------------
' __LogSourceAudioFiles
'-------------------------------------------------------------------------------
sub __LogSourceAudioFiles(log as object, session as dynamic)
    log.write("Source audio files:")

    audioFiles = invalid
    if session <> invalid and session.libraryItem <> invalid and session.libraryItem.media <> invalid then
        audioFiles = session.libraryItem.media.audioFiles
    end if

    if audioFiles = invalid or audioFiles.Count() = 0 then
        log.write("    none")
        return
    end if

    for i = 0 to audioFiles.Count() - 1
        file = audioFiles[i]
        if file <> invalid then
            parts = [i.ToStr()]
            __PushLogField(parts, "index", file.index)
            __PushLogField(parts, "title", file.title)
            __PushLogField(parts, "contentUrl", file.contentUrl)
            __PushLogField(parts, "mimeType", file.mimeType)
            __PushLogField(parts, "startOffset", file.startOffset)
            __PushLogField(parts, "duration", file.duration)
            __PushLogField(parts, "format", file.format)
            __PushLogField(parts, "bitRate", file.bitRate)
            __PushLogField(parts, "sampleRate", file.sampleRate)
            __PushLogField(parts, "channels", file.channels)
            __PushLogField(parts, "channelLayout", file.channelLayout)
            __PushLogField(parts, "codec", file.codec)
            __PushLogField(parts, "timeBase", file.timeBase)
            __PushTrackMetadataFields(parts, file.metadata)
            log.writeBracketed(parts)
        else
            log.write("    invalid file")
        end if
    end for
end sub

'-------------------------------------------------------------------------------
' __PushTrackMetadataFields
'-------------------------------------------------------------------------------
sub __PushTrackMetadataFields(parts as object, metadata as dynamic)
    if metadata = invalid then return

    __PushLogField(parts, "filename", metadata.filename)
    __PushLogField(parts, "ext", metadata.ext)
    __PushLogField(parts, "size", metadata.size)
    __PushLogField(parts, "bitRate", metadata.bitRate)
    __PushLogField(parts, "sampleRate", metadata.sampleRate)
    __PushLogField(parts, "channels", metadata.channels)
    __PushLogField(parts, "codec", metadata.codec)
    __PushLogField(parts, "format", metadata.format)
end sub

'-------------------------------------------------------------------------------
' __PushLogField
'-------------------------------------------------------------------------------
sub __PushLogField(parts as object, name as string, value as dynamic)
    if value = invalid then return
    parts.Push(name + "=" + SafeString(value))
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


