'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.log = CreateLogger("PlaybackTask")
    m.log.write("init")
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
    validationResult = validateStartRequest(request, log)
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
    bodyData = buildPlaybackStartBody(forceTranscode, forceDirectPlay)
    body = buildPlaybackStartBodyJson(bodyData)

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
    tracks = mapTracks(server, token, playbackSession, log)
    if tracks.Count() = 0 then
        return { ok: false, action: "startPlayback", errorMessage: "No playable audio tracks were returned." }
    end if

    ' chapters are the navigation/display units. Player uses them for the Chapters list and the right-aligned
    ' chapter title/status. They may not match audio files. A single audio file can have many chapters, and a
    ' multi-file book can have chapters that cross or differ from track boundaries.
    chapters = PlaybackChapterMapper_MapSessionChapters(playbackSession)
    if PlaybackChapterMapper_ShouldUseTracks(chapters, tracks, playbackSession) then
        log.error("session chapters appear partial; using audio tracks as chapter items")
        chapters = PlaybackChapterMapper_MapTracks(tracks)
    end if

    ' playback data
    action = "startPlayback"
    playbackSessionId = getSessionId(playbackSession)
    currentTime = Number_ToFloat(playbackSession.currentTime)
    duration = Number_ToFloat(playbackSession.duration)
    playMethod = Number_ToInteger(playbackSession.playMethod, -1)
    isHlsTranscode = isSessionHlsTranscode(playbackSession, tracks)
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

    logTracks(log, tracks)
    logAudioTrackDetails(log, playbackSession)
    logSourceAudioFiles(log, playbackSession)
    logChapters(log, chapters)

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

    body = buildPlaybackProgressBodyJson(request)

    logPlaybackProgressRequest(log, sessionId, request)

    result = HttpClient_Request(server + "/api/session/" + sessionId.ToStr() + "/close", "POST", token, body)
    result.action = "closePlaybackSession"
    logPlaybackSessionResponse(log, "close", sessionId, result)

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

    body = buildPlaybackProgressBodyJson(request)

    logPlaybackProgressRequest(log, sessionId, request)

    result = HttpClient_Request(server + "/api/session/" + sessionId.ToStr() + "/sync", "POST", token, body)
    result.action = "syncPlaybackSession"
    'logPlaybackSessionResponse(log, "sync", sessionId, result)

    return result

end function

'-------------------------------------------------------------------------------
' buildPlaybackProgressBodyJson
'-------------------------------------------------------------------------------
function buildPlaybackProgressBodyJson(request as dynamic) as string
    parts = []
    if request.currentTime <> invalid then parts.Push(Json_NumberPair("currentTime", request.currentTime))
    if request.timeListened <> invalid then parts.Push(Json_NumberPair("timeListened", request.timeListened))
    if request.duration <> invalid then parts.Push(Json_NumberPair("duration", request.duration))
    return Json_Object(parts)
end function

'-------------------------------------------------------------------------------
' logPlaybackProgressRequest
'-------------------------------------------------------------------------------
sub logPlaybackProgressRequest(log as object, sessionId as dynamic, request as dynamic)
    if request.currentTime = invalid and request.timeListened = invalid and request.duration = invalid then
        log.write("sessionId=" + sessionId.ToStr() + " progressData=omitted")
        return
    end if

    log.write("sessionId=" + sessionId.ToStr() + " currentTime=" + SafeString(request.currentTime, "invalid") + " timeListened=" + SafeString(request.timeListened, "invalid") + " duration=" + SafeString(request.duration, "invalid"))
end sub

'-------------------------------------------------------------------------------
' logPlaybackSessionResponse
'-------------------------------------------------------------------------------
sub logPlaybackSessionResponse(log as object, operation as string, sessionId as dynamic, result as dynamic)
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
' validateStartRequest
'-------------------------------------------------------------------------------
function validateStartRequest(request as dynamic, log as object) as object
    if request = invalid then return validationError(log, "Invalid playback request: request is invalid.")
    if Type(request) <> "roAssociativeArray" then return validationError(log, "Invalid playback request: request type is " + Type(request) + ".")
    if request.server = invalid or request.server = "" then return validationError(log, "Invalid playback request: server is missing.")
    if request.token = invalid or request.token = "" then return validationError(log, "Invalid playback request: token is missing.")
    if request.itemId = invalid or request.itemId = "" then return validationError(log, "Invalid playback request: itemId is missing.")
    return { ok: true }
end function

'-------------------------------------------------------------------------------
' validationError
'-------------------------------------------------------------------------------
function validationError(log as object, message as string) as object
    log.error(message)
    return { ok: false, action: "startPlayback", errorMessage: message }
end function

'-------------------------------------------------------------------------------
' buildPlaybackStartBody
'-------------------------------------------------------------------------------
function buildPlaybackStartBody(forceTranscode = false as boolean, forceDirectPlay = false as boolean) as object
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
        supportedMimeTypes: getSupportedMimeTypes(forceTranscode)
        mediaPlayer: "roku"
    }
end function

'-------------------------------------------------------------------------------
' buildPlaybackStartBodyJson
'-------------------------------------------------------------------------------
function buildPlaybackStartBodyJson(bodyData as object) as string
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
' getSupportedMimeTypes
'-------------------------------------------------------------------------------
function getSupportedMimeTypes(includeHls as boolean) as object
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
' mapTracks
'-------------------------------------------------------------------------------
function mapTracks(server as string, token as dynamic, session as dynamic, log as object) as object
    mappedTracks = []
    tracks = invalid
    if session <> invalid then tracks = session.audioTracks
    audioFiles = getSourceAudioFiles(session)
    sessionId = getSessionId(session)

    log.write("playback mapping audioTracks=" + Array_GetCount(tracks).ToStr())

    if tracks = invalid then return mappedTracks

    for i = 0 to tracks.Count() - 1
        track = tracks[i]
        if track <> invalid then
            url = buildTrackUrl(server, token, sessionId, track)
            if url <> "" then
                trackIndex = getTrackIndex(track, i)
                sourceAudioFile = getSourceAudioFile(audioFiles, trackIndex, i)
                mappedTracks.Push({
                    index: trackIndex
                    url: url
                    title: getTrackTitle(track, i)
                    startOffset: Number_ToFloat(track.startOffset)
                    durationSeconds: Number_ToFloat(track.duration)
                    contentUrl: SafeString(track.contentUrl, "")
                    mimeType: getTrackMimeType(track)
                    isHls: isHlsTrack(track)
                    codec: getSourceAudioFileField(sourceAudioFile, "codec")
                    bitRate: getSourceAudioFileField(sourceAudioFile, "bitRate")
                    channels: getSourceAudioFileField(sourceAudioFile, "channels")
                    channelLayout: getSourceAudioFileField(sourceAudioFile, "channelLayout")
                    sampleRate: getSourceAudioFileField(sourceAudioFile, "sampleRate")
                    format: getSourceAudioFileField(sourceAudioFile, "format")
                })
            end if
        end if
    end for

    return mappedTracks
end function

'-------------------------------------------------------------------------------
' getSourceAudioFiles
'-------------------------------------------------------------------------------
function getSourceAudioFiles(session as dynamic) as dynamic
    if session <> invalid and session.libraryItem <> invalid and session.libraryItem.media <> invalid then
        return session.libraryItem.media.audioFiles
    end if

    return invalid
end function

'-------------------------------------------------------------------------------
' getSourceAudioFile
'-------------------------------------------------------------------------------
function getSourceAudioFile(audioFiles as dynamic, trackIndex as integer, fallbackIndex as integer) as dynamic
    if audioFiles = invalid or audioFiles.Count() = 0 then return invalid

    for each audioFile in audioFiles
        if audioFile <> invalid and audioFile.index <> invalid and Number_ToInteger(audioFile.index, -1) = trackIndex then
            return audioFile
        end if
    end for

    if fallbackIndex >= 0 and fallbackIndex < audioFiles.Count() then return audioFiles[fallbackIndex]
    return invalid
end function

'-------------------------------------------------------------------------------
' getSourceAudioFileField
'-------------------------------------------------------------------------------
function getSourceAudioFileField(audioFile as dynamic, fieldName as string) as dynamic
    if audioFile = invalid then return invalid
    fieldValue = audioFile[fieldName]
    if fieldValue <> invalid then return fieldValue

    metadata = audioFile.metadata
    if metadata <> invalid then return metadata[fieldName]

    return invalid
end function

'-------------------------------------------------------------------------------
' buildTrackUrl
'-------------------------------------------------------------------------------
function buildTrackUrl(server as string, token as dynamic, sessionId as dynamic, track as dynamic) as string
    contentUrl = SafeString(track.contentUrl, "")
    if contentUrl = "" then return ""

    if isHlsUrl(contentUrl) then return buildAuthenticatedContentUrl(server, token, contentUrl)
    if sessionId <> invalid and sessionId <> "" then return server + "/public/session/" + sessionId.ToStr() + "/track/" + getTrackIndex(track, 0).ToStr()

    return buildAuthenticatedContentUrl(server, token, contentUrl)
end function

'-------------------------------------------------------------------------------
' buildAuthenticatedContentUrl
'-------------------------------------------------------------------------------
function buildAuthenticatedContentUrl(server as string, token as dynamic, contentUrl as string) as string
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
' logTracks
'-------------------------------------------------------------------------------
sub logTracks(log as object, tracks as dynamic)
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
' logAudioTrackDetails
'-------------------------------------------------------------------------------
sub logAudioTrackDetails(log as object, session as dynamic)
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
            pushLogField(parts, "index", track.index)
            pushLogField(parts, "contentUrl", track.contentUrl)
            pushLogField(parts, "mimeType", track.mimeType)
            pushLogField(parts, "duration", track.duration)
            pushTrackMetadataFields(parts, track.metadata)
            log.writeBracketed(parts)
        else
            log.write("    invalid track")
        end if
    end for
end sub

'-------------------------------------------------------------------------------
' logSourceAudioFiles
'-------------------------------------------------------------------------------
sub logSourceAudioFiles(log as object, session as dynamic)
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
            pushLogField(parts, "index", file.index)
            pushLogField(parts, "title", file.title)
            pushLogField(parts, "contentUrl", file.contentUrl)
            pushLogField(parts, "mimeType", file.mimeType)
            pushLogField(parts, "startOffset", file.startOffset)
            pushLogField(parts, "duration", file.duration)
            pushLogField(parts, "format", file.format)
            pushLogField(parts, "bitRate", file.bitRate)
            pushLogField(parts, "sampleRate", file.sampleRate)
            pushLogField(parts, "channels", file.channels)
            pushLogField(parts, "channelLayout", file.channelLayout)
            pushLogField(parts, "codec", file.codec)
            pushLogField(parts, "timeBase", file.timeBase)
            pushTrackMetadataFields(parts, file.metadata)
            log.writeBracketed(parts)
        else
            log.write("    invalid file")
        end if
    end for
end sub

'-------------------------------------------------------------------------------
' pushTrackMetadataFields
'-------------------------------------------------------------------------------
sub pushTrackMetadataFields(parts as object, metadata as dynamic)
    if metadata = invalid then return

    pushLogField(parts, "filename", metadata.filename)
    pushLogField(parts, "ext", metadata.ext)
    pushLogField(parts, "size", metadata.size)
    pushLogField(parts, "bitRate", metadata.bitRate)
    pushLogField(parts, "sampleRate", metadata.sampleRate)
    pushLogField(parts, "channels", metadata.channels)
    pushLogField(parts, "codec", metadata.codec)
    pushLogField(parts, "format", metadata.format)
end sub

'-------------------------------------------------------------------------------
' pushLogField
'-------------------------------------------------------------------------------
sub pushLogField(parts as object, name as string, value as dynamic)
    if value = invalid then return
    parts.Push(name + "=" + SafeString(value))
end sub

'-------------------------------------------------------------------------------
' logChapters
'-------------------------------------------------------------------------------
sub logChapters(log as object, chapters as dynamic)
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
' isSessionHlsTranscode
'-------------------------------------------------------------------------------
function isSessionHlsTranscode(session as dynamic, tracks as object) as boolean
    if session <> invalid and session.playMethod <> invalid and Number_ToInteger(session.playMethod, -1) <> 0 then return true
    if tracks <> invalid and tracks.Count() = 1 and tracks[0] <> invalid and tracks[0].isHls = true then return true
    return false
end function

'-------------------------------------------------------------------------------
' isHlsTrack
'-------------------------------------------------------------------------------
function isHlsTrack(track as dynamic) as boolean
    if track = invalid then return false
    return isHlsUrl(SafeString(track.contentUrl, ""))
end function

'-------------------------------------------------------------------------------
' isHlsUrl
'-------------------------------------------------------------------------------
function isHlsUrl(url as string) as boolean
    text = LCase(url)
    return Instr(1, text, "/hls") > 0 or Instr(1, text, ".m3u8") > 0
end function

'-------------------------------------------------------------------------------
' getSessionId
'-------------------------------------------------------------------------------
function getSessionId(session as dynamic) as dynamic
    if session = invalid then return invalid
    return session.id
end function

'-------------------------------------------------------------------------------
' getTrackIndex
'-------------------------------------------------------------------------------
function getTrackIndex(track as dynamic, fallbackIndex as integer) as integer
    if track <> invalid and track.index <> invalid then return Number_ToInteger(track.index, fallbackIndex)
    return fallbackIndex
end function

'-------------------------------------------------------------------------------
' getTrackTitle
'-------------------------------------------------------------------------------
function getTrackTitle(track as dynamic, index as integer) as string
    if track <> invalid then
        title = FirstNonEmpty([track.title, track.name], "")
        if title <> "" and title <> "Audiobook" then return title
    end if

    return "Track " + (index + 1).ToStr()
end function

'-------------------------------------------------------------------------------
' getTrackMimeType
'-------------------------------------------------------------------------------
function getTrackMimeType(track as dynamic) as string
    if track <> invalid and track.mimeType <> invalid then return SafeString(track.mimeType, "audio/mpeg")
    return "audio/mpeg"
end function

