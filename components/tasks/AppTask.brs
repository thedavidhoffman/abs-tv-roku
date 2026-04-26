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
        m.top.response = { ok: false, errorMessage: "Invalid request." }
        return
    end if

    action = request.action
    if action = "login" then
        m.top.response = doLogin(request)
    else if action = "authorize" then
        m.top.response = doAuthorize(request)
    else if action = "logout" then
        m.top.response = doLogout(request)
    else if action = "loadLibrary" then
        m.top.response = loadLibrary(request)
    else if action = "startPlayback" then
        m.top.response = startPlayback(request)
    else if action = "loadBooks" then
        m.top.response = loadBooks(request)
    else if action = "loadSeries" then
        m.top.response = loadSeries(request)
    else
        m.top.response = { ok: false, errorMessage: "Unknown request action." }
    end if
end sub

'-------------------------------------------------------------------------------
' doLogin
'-------------------------------------------------------------------------------
function doLogin(request as Object) as Object
    server = NormalizeServerUrl(request.server)
    body = FormatJson({
        username: request.username
        password: request.password
    })
    result = doRequest(server + "/login", "POST", invalid, body)
    if result.ok <> true then return result
    payload = result.data
    if payload = invalid or payload.user = invalid or payload.user.token = invalid then
        return { ok: false, errorMessage: "The server response did not include a token." }
    end if
    librariesResult = loadLibraries(server, payload.user.token)
    if librariesResult.ok <> true then return librariesResult
    return {
        ok: true
        action: "login"
        server: server
        payload: payload
        libraries: librariesResult.libraries
    }
end function

'-------------------------------------------------------------------------------
' doAuthorize
'-------------------------------------------------------------------------------
function doAuthorize(request as Object) as Object
    server = NormalizeServerUrl(request.server)
    result = doRequest(server + "/api/authorize", "POST", request.token, "")
    if result.ok <> true then return result
    librariesResult = loadLibraries(server, request.token)
    if librariesResult.ok <> true then return librariesResult
    return {
        ok: true
        action: "authorize"
        server: server
        payload: result.data
        libraries: librariesResult.libraries
    }
end function

'-------------------------------------------------------------------------------
' doLogout
'-------------------------------------------------------------------------------
function doLogout(request as Object) as Object
    server = NormalizeServerUrl(request.server)
    result = doRequest(server + "/logout", "POST", request.token, "")
    if result.ok <> true and result.status <> 401 then
        return result
    end if
    return { ok: true, action: "logout" }
end function

'-------------------------------------------------------------------------------
' loadLibraries
'-------------------------------------------------------------------------------
function loadLibraries(server as String, token as Dynamic) as Object
    result = doRequest(server + "/api/libraries", "GET", token, invalid)
    if result.ok <> true then return result

    return {
        ok: true
        libraries: mapLibraries(result.data)
    }
end function

'-------------------------------------------------------------------------------
' mapLibraries
'-------------------------------------------------------------------------------
function mapLibraries(payload as Dynamic) as Object
    mappedLibraries = []
    libraries = invalid

    if payload <> invalid then
        if payload.libraries <> invalid then
            libraries = payload.libraries
        else if Type(payload) = "roArray" then
            libraries = payload
        end if
    end if

    if libraries <> invalid then
        for each library in libraries
            mappedLibraries.Push({
                id: library.id
                name: library.name
            })
        end for
    end if

    return mappedLibraries
end function

'-------------------------------------------------------------------------------
' loadLibrary
'-------------------------------------------------------------------------------
function loadLibrary(request as Object) as Object
    server = NormalizeServerUrl(request.server)
    token = request.token
    bookLibraryId = request.bookLibraryId

    if bookLibraryId = invalid or bookLibraryId = "" then
        authResult = doRequest(server + "/api/authorize", "POST", token, "")
        if authResult.ok <> true then return authResult
        bookLibraryId = ResolveBookLibraryId(authResult.data)
    end if

    if bookLibraryId = invalid or bookLibraryId = "" then
        return { ok: false, errorMessage: "No book library was found for this account." }
    end if

    allItems = []
    page = 0
    limit = 100
    keepLoading = true

    while keepLoading
        libraryUrl = server + "/api/libraries/" + bookLibraryId + "/items?limit=" + limit.ToStr() + "&page=" + page.ToStr() + "&sort=media.metadata.title&desc=0&minified=0&collapseseries=0"
        libraryResult = doRequest(libraryUrl, "GET", token, invalid)
        if libraryResult.ok <> true then return libraryResult

        results = invalid
        if libraryResult.data <> invalid and libraryResult.data.results <> invalid then results = libraryResult.data.results

        if results = invalid or results.Count() = 0 then
            keepLoading = false
        else
            for each item in results
                allItems.Push(item)
            end for

            page = page + 1
            keepLoading = (results.Count() = limit)
        end if
    end while

    return {
        ok: true
        action: "loadLibrary"
        bookLibraryId: bookLibraryId
        libraryItems: allItems
    }
end function

'-------------------------------------------------------------------------------
' startPlayback
'-------------------------------------------------------------------------------
function startPlayback(request as Object) as Object
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

    result = doRequest(server + "/api/items/" + itemId + "/play", "POST", token, body)
    if result.ok <> true then return result

    itemResult = doRequest(server + "/api/items/" + itemId, "GET", token, invalid)
    itemPayload = invalid
    if itemResult.ok = true then itemPayload = itemResult.data

    tracks = mapPlaybackTracks(server, token, result.data, itemPayload)
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
' mapPlaybackTracks
'-------------------------------------------------------------------------------
function mapPlaybackTracks(server as String, token as Dynamic, payload as Dynamic, itemPayload as Dynamic) as Object
    mappedTracks = []
    tracks = getPlaybackSessionTracks(payload)
    files = getPlaybackSessionFiles(payload, itemPayload)
    sessionId = invalid

    if payload <> invalid and payload.id <> invalid then sessionId = payload.id

    ? "playback mapping"; " audioTracks="; getArrayCount(tracks); " files="; getArrayCount(files)

    if files <> invalid and files.Count() > 0 and tracks <> invalid and tracks.Count() = 1 then
        track = tracks[0]
        startPositionSeconds = 0
        for i = 0 to files.Count() - 1
            file = files[i]
            durationSeconds = getPlaybackTrackDurationSeconds(file, track)
            mappedTracks.Push({
                url: buildPlaybackUrl(server, token, sessionId, track)
                title: getPlaybackTrackTitle(file, track, i)
                durationSeconds: durationSeconds
                startPositionSeconds: startPositionSeconds
                mimeType: getPlaybackTrackMimeType(file, track)
            })
            startPositionSeconds = startPositionSeconds + durationSeconds
        end for
    else if files <> invalid and files.Count() > 0 and (tracks = invalid or files.Count() > tracks.Count()) then
        for i = 0 to files.Count() - 1
            file = files[i]
            track = getPlaybackTrackForFileIndex(tracks, file, i)
            url = buildPlaybackFileUrl(server, token, sessionId, file, track, i)
            if url <> "" then
                mappedTracks.Push({
                    url: url
                    title: getPlaybackTrackTitle(file, track, i)
                    durationSeconds: getPlaybackTrackDurationSeconds(file, track)
                    mimeType: getPlaybackTrackMimeType(file, track)
                })
            end if
        end for
    else if tracks <> invalid then
        for i = 0 to tracks.Count() - 1
            track = tracks[i]
            file = getPlaybackFileForTrack(files, track, i)
            contentUrl = invalid
            if track.contentUrl <> invalid then contentUrl = track.contentUrl
            if contentUrl <> invalid and contentUrl <> "" then
                mappedTracks.Push({
                    url: buildPlaybackUrl(server, token, sessionId, track)
                    title: getPlaybackTrackTitle(file, track, i)
                    durationSeconds: getPlaybackTrackDurationSeconds(file, track)
                    mimeType: getPlaybackTrackMimeType(file, track)
                })
            end if
        end for
    end if

    return mappedTracks
end function

'-------------------------------------------------------------------------------
' getArrayCount
'-------------------------------------------------------------------------------
function getArrayCount(values as Dynamic) as Integer
    if values = invalid then return 0
    return values.Count()
end function

'-------------------------------------------------------------------------------
' getPlaybackTrackForFileIndex
'-------------------------------------------------------------------------------
function getPlaybackTrackForFileIndex(tracks as Dynamic, file as Dynamic, fallbackIndex as Integer) as Dynamic
    if tracks = invalid or tracks.Count() = 0 then return invalid

    fileIndex = getPlaybackFileIndex(file, fallbackIndex)
    for each track in tracks
        if track.index <> invalid and int(val(track.index.ToStr())) = fileIndex then return track
        if track.trackNum <> invalid and int(val(track.trackNum.ToStr())) = fileIndex then return track
    end for

    if fallbackIndex >= 0 and fallbackIndex < tracks.Count() then return tracks[fallbackIndex]
    return invalid
end function

'-------------------------------------------------------------------------------
' getPlaybackFileIndex
'-------------------------------------------------------------------------------
function getPlaybackFileIndex(file as Dynamic, fallbackIndex as Integer) as Integer
    if file <> invalid then
        if file.index <> invalid then return int(val(file.index.ToStr()))
        if file.trackNum <> invalid then return int(val(file.trackNum.ToStr()))
    end if

    return fallbackIndex
end function

'-------------------------------------------------------------------------------
' buildPlaybackFileUrl
'-------------------------------------------------------------------------------
function buildPlaybackFileUrl(server as String, token as Dynamic, sessionId as Dynamic, file as Dynamic, track as Dynamic, fallbackIndex as Integer) as String
    if track <> invalid and track.contentUrl <> invalid and track.contentUrl <> "" then
        return buildPlaybackUrl(server, token, sessionId, track)
    end if

    if file <> invalid and file.contentUrl <> invalid and file.contentUrl <> "" then
        return buildPlaybackUrl(server, token, sessionId, file)
    end if

    if sessionId <> invalid and sessionId <> "" then
        return server + "/public/session/" + sessionId + "/track/" + getPlaybackFileIndex(file, fallbackIndex).ToStr()
    end if

    return ""
end function

'-------------------------------------------------------------------------------
' getPlaybackSessionTracks
'-------------------------------------------------------------------------------
function getPlaybackSessionTracks(payload as Dynamic) as Dynamic
    if payload = invalid then return invalid

    if payload.audioTracks <> invalid then return payload.audioTracks
    if payload.libraryItem <> invalid and payload.libraryItem.media <> invalid then
        if payload.libraryItem.media.audioTracks <> invalid then return payload.libraryItem.media.audioTracks
    end if

    return invalid
end function

'-------------------------------------------------------------------------------
' getPlaybackSessionFiles
'-------------------------------------------------------------------------------
function getPlaybackSessionFiles(payload as Dynamic, itemPayload as Dynamic) as Dynamic
    files = getPlaybackItemFiles(itemPayload)
    if files <> invalid then return files

    if payload <> invalid and payload.libraryItem <> invalid then return getPlaybackItemFiles(payload.libraryItem)
    return getPlaybackItemFiles(payload)
end function

'-------------------------------------------------------------------------------
' getPlaybackItemFiles
'-------------------------------------------------------------------------------
function getPlaybackItemFiles(item as Dynamic) as Dynamic
    if item = invalid or item.media = invalid then return invalid

    if item.media.audioFiles <> invalid then return item.media.audioFiles
    if item.media.tracks <> invalid then return item.media.tracks
    return invalid
end function

'-------------------------------------------------------------------------------
' getPlaybackFileForTrack
'-------------------------------------------------------------------------------
function getPlaybackFileForTrack(files as Dynamic, track as Dynamic, fallbackIndex as Integer) as Dynamic
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
' getPlaybackTrackTitle
'-------------------------------------------------------------------------------
function getPlaybackTrackTitle(file as Dynamic, track as Dynamic, index as Integer) as String
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
' getPlaybackTrackMimeType
'-------------------------------------------------------------------------------
function getPlaybackTrackMimeType(file as Dynamic, track as Dynamic) as String
    if track <> invalid and track.mimeType <> invalid then return SafeString(track.mimeType, "audio/mpeg")
    if file <> invalid and file.mimeType <> invalid then return SafeString(file.mimeType, "audio/mpeg")
    if file <> invalid and file.metadata <> invalid and file.metadata.mimeType <> invalid then return SafeString(file.metadata.mimeType, "audio/mpeg")
    return "audio/mpeg"
end function

'-------------------------------------------------------------------------------
' getPlaybackTrackDurationSeconds
'-------------------------------------------------------------------------------
function getPlaybackTrackDurationSeconds(file as Dynamic, track as Dynamic) as Integer
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
' buildPlaybackUrl
'-------------------------------------------------------------------------------
function buildPlaybackUrl(server as String, token as Dynamic, sessionId as Dynamic, track as Dynamic) as String
    contentUrl = SafeString(track.contentUrl, "")

    if sessionId <> invalid and sessionId <> "" and Instr(1, LCase(contentUrl), "/hls") <> 1 then
        return server + "/public/session/" + sessionId + "/track/" + track.index.ToStr()
    end if

    url = contentUrl
    if Instr(1, LCase(url), "http://") <> 1 and Instr(1, LCase(url), "https://") <> 1 then
        if Left(url, 1) <> "/" then url = "/" + url
        url = server + url
    end if

    url = ReplaceString(url, " ", "%20")
    separator = "?"
    if Instr(1, url, "?") > 0 then separator = "&"
    if token <> invalid and token <> "" then url = url + separator + "token=" + token
    return url
end function

'-------------------------------------------------------------------------------
' ReplaceString
'-------------------------------------------------------------------------------
function ReplaceString(value as String, oldValue as String, newValue as String) as String
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

'-------------------------------------------------------------------------------
' loadBooks
'-------------------------------------------------------------------------------
function loadBooks(request as Object) as Object
    server = NormalizeServerUrl(request.server)
    token = request.token
    bookLibraryId = request.bookLibraryId

    if bookLibraryId = invalid or bookLibraryId = "" then
        authResult = doRequest(server + "/api/authorize", "POST", token, "")
        if authResult.ok <> true then return authResult
        bookLibraryId = ResolveBookLibraryId(authResult.data)
    end if

    if bookLibraryId = invalid or bookLibraryId = "" then
        return { ok: false, errorMessage: "No book library was found for this account." }
    end if

    continueResult = doRequest(server + "/api/me/items-in-progress?limit=20", "GET", token, invalid)
    if continueResult.ok <> true then return continueResult

    recentUrl = server + "/api/libraries/" + bookLibraryId + "/items?limit=10&page=0&sort=addedAt&desc=1&minified=0&collapseseries=0"
    recentResult = doRequest(recentUrl, "GET", token, invalid)
    if recentResult.ok <> true then return recentResult

    return {
        ok: true
        action: "loadBooks"
        bookLibraryId: bookLibraryId
        continueListening: continueResult.data
        recentlyAdded: recentResult.data
    }
end function

'-------------------------------------------------------------------------------
' loadSeries
'-------------------------------------------------------------------------------
function loadSeries(request as Object) as Object
    server = NormalizeServerUrl(request.server)
    token = request.token
    bookLibraryId = request.bookLibraryId

    if bookLibraryId = invalid or bookLibraryId = "" then
        authResult = doRequest(server + "/api/authorize", "POST", token, "")
        if authResult.ok <> true then return authResult
        bookLibraryId = ResolveBookLibraryId(authResult.data)
    end if

    if bookLibraryId = invalid or bookLibraryId = "" then
        return { ok: false, errorMessage: "No book library was found for this account." }
    end if

    seriesUrl = server + "/api/libraries/" + bookLibraryId + "/series?limit=50&page=0&sort=addedAt&desc=1"
    seriesResult = doRequest(seriesUrl, "GET", token, invalid)
    if seriesResult.ok <> true then return seriesResult

    return {
        ok: true
        action: "loadSeries"
        bookLibraryId: bookLibraryId
        series: seriesResult.data
    }
end function

'-------------------------------------------------------------------------------
' doRequest
'-------------------------------------------------------------------------------
function doRequest(url as String, method as String, token as Dynamic, body as Dynamic) as Object
    
    ? "request"; " method="; method; " url="; url

    transfer = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.InitClientCertificates()
    transfer.EnableEncodings(true)
    transfer.SetMessagePort(port)
    transfer.SetUrl(url)
    transfer.AddHeader("Accept", "application/json")

    if token <> invalid and token <> "" then
        transfer.AddHeader("Authorization", "Bearer " + token)
    end if

    responseText = ""
    status = 0
    if method = "POST" then
        transfer.AddHeader("Content-Type", "application/json")
        requestStarted = transfer.AsyncPostFromString(invalidToEmpty(body))
    else
        requestStarted = transfer.AsyncGetToString()
    end if

    if requestStarted <> true then
        return { ok: false, status: 0, errorMessage: "Unable to start the request to the Audiobookshelf server." }
    end if

    msg = wait(30000, port)
    if msg = invalid then
        transfer.AsyncCancel()
        return { ok: false, status: 0, errorMessage: "The Audiobookshelf server request timed out." }
    end if

    if type(msg) <> "roUrlEvent" then
        return { ok: false, status: 0, errorMessage: "Unexpected response from the Audiobookshelf server." }
    end if

    status = msg.GetResponseCode()
    responseText = msg.GetString()
    ? "response"; " status="; status
    ? "response body="; responseText

    if status = 0 then
        return { ok: false, status: status, errorMessage: "Unable to reach the Audiobookshelf server." }
    end if

    if status = 401 and token <> invalid and token <> "" then
        return { ok: false, status: status, authExpired: true, errorMessage: "Your session has expired. Please sign in again." }
    end if

    data = invalid
    if responseText <> invalid and responseText <> "" then
        data = ParseJson(responseText)
    end if

    if status < 200 or status >= 300 then
        message = "Request failed."
        if data <> invalid then
            if data.error <> invalid then message = SafeString(data.error, message)
            if data.message <> invalid then message = SafeString(data.message, message)
        else if responseText <> invalid and TrimString(responseText) <> "" then
            message = TrimString(responseText)
        else if msg.GetFailureReason() <> invalid and TrimString(msg.GetFailureReason()) <> "" then
            message = TrimString(msg.GetFailureReason())
        end if
        return { ok: false, status: status, errorMessage: message }
    end if

    return { ok: true, status: status, data: data }
end function

'-------------------------------------------------------------------------------
' invalidToEmpty
'-------------------------------------------------------------------------------
function invalidToEmpty(value as Dynamic) as String
    if value = invalid then return ""
    return value
end function
