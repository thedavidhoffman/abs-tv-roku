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
        m.top.response = { ok: false, errorMessage: "Invalid in-progress request." }
        return
    end if

    m.top.response = loadInProgress(request)
end sub

'-------------------------------------------------------------------------------
' loadInProgress
'-------------------------------------------------------------------------------
function loadInProgress(request as object) as object

    log = CreateLogger("(API) loadInProgress")
    server = request.server
    token = request.token

    inProgressUrl = server + "/api/me/items-in-progress?limit=100"
    result = HttpClient_Request(inProgressUrl, "GET", token, invalid)

    log.write(inProgressUrl)
    log.write("status = " + SafeString(result.status, ""))

    if result.ok <> true then return result

    libraryItems = []
    if result.data <> invalid and result.data.libraryItems <> invalid then libraryItems = result.data.libraryItems
    mediaProgress = MediaProgressMapper_MapInProgressItems(libraryItems)
    sourceProgress = loadSourceProgress(server, token, request.sourceItemId, log)
    if sourceProgress <> invalid then mediaProgress.Push(sourceProgress)

    return {
        ok: true
        action: "loadInProgress"
        status: result.status
        libraryItems: libraryItems
        mediaProgress: mediaProgress
        sourceItemId: request.sourceItemId
    }
    
end function

'-------------------------------------------------------------------------------
' loadSourceProgress
'-------------------------------------------------------------------------------
function loadSourceProgress(server as string, token as dynamic, sourceItemId as dynamic, log as object) as dynamic
    if sourceItemId = invalid or sourceItemId = "" then return invalid

    progressUrl = server + "/api/me/progress/" + sourceItemId.ToStr()
    log.write(progressUrl)

    result = HttpClient_Request(progressUrl, "GET", token, invalid)
    
    if result.ok <> true then return invalid

    return MediaProgressMapper_MapProgressItem(result.data)
end function


