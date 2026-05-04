'-------------------------------------------------------------------------------
' Item API
'-------------------------------------------------------------------------------
' Loads a specific Audiobookshelf library item by id. Playback uses this module
' to inspect the selected item's audio tracks and files after starting a session.

'-------------------------------------------------------------------------------
' Item_Load
'-------------------------------------------------------------------------------
function Item_Load(request as object) as object
    log = CreateLogger("(API) Item_Load")

    server = NormalizeServerUrl(request.server)
    token = request.token
    itemId = request.itemId

    if itemId = invalid or itemId = "" then
        log.flush()
        return { ok: false, errorMessage: "No audiobook was selected." }
    end if

    itemUrl = server + "/api/items/" + itemId
    result = HttpClient_Request(itemUrl, "GET", token, invalid)
    log.add(itemUrl)
    log.add("status = " + SafeString(result.status, ""))
    log.flush()

    return result
end function

'-------------------------------------------------------------------------------
' Item_LogTracks
'-------------------------------------------------------------------------------
sub Item_LogTracks(item as dynamic)
    log = CreateLogger("(API) Item_LogTracks")

    if item = invalid then
        log.add("No item payload available for track data.")
        log.flush()
        return
    end if

    if item.media = invalid then
        log.add("No item.media payload available for track data.")
        log.flush()
        return
    end if

    if item.media.audioFiles = invalid then
        log.add("No item.media.audioFiles payload available for track data.")
        log.flush()
        return
    end if

    audioFiles = item.media.audioFiles

    log.add("Item has " +  __GetArrayCount(audioFiles).ToStr() + " files")

    log.add("Audio files:")
    for i = 0 to item.media.audioFiles.Count() - 1
        file = audioFiles[i]
        fileInfo = "  File " + i.ToStr() + ":"
        if file.index <> invalid then fileInfo = fileInfo + " index=" + file.index.ToStr()
        if file.metadata <> invalid and file.metadata.filename <> invalid then fileInfo = fileInfo + " filename=" + SafeString(file.metadata.filename)
        if file.duration <> invalid then fileInfo = fileInfo + " duration=" + file.duration.ToStr()
        if file.mimeType <> invalid then fileInfo = fileInfo + " mimeType=" + SafeString(file.mimeType)
        log.add(fileInfo)
    end for

    log.flush()
end sub

'-------------------------------------------------------------------------------
' __GetArrayCount
'-------------------------------------------------------------------------------
function __GetArrayCount(values as dynamic) as integer
    if values = invalid then return 0
    return values.Count()
end function
