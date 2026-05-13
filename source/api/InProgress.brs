'-------------------------------------------------------------------------------
' InProgress_Load
'-------------------------------------------------------------------------------
function InProgress_Load(request as object) as object

    log = CreateLogger("(API) InProgress_Load")
    server = request.server
    token = request.token

    inProgressUrl = server + "/api/me/items-in-progress?limit=100"
    result = HttpClient_Request(inProgressUrl, "GET", token, invalid)
    log.write(inProgressUrl)
    log.write("status = " + SafeString(result.status, ""))
    if result.ok <> true then
        log.flush()
        return result
    end if

    libraryItems = []
    if result.data <> invalid and result.data.libraryItems <> invalid then libraryItems = result.data.libraryItems
    mediaProgress = MediaProgressMapper_MapInProgressItems(libraryItems)
    sourceProgress = __InProgress_LoadSourceProgress(server, token, request.sourceItemId, log)
    if sourceProgress <> invalid then mediaProgress.Push(sourceProgress)

    log.flush()

    return {
        ok: true
        action: "loadInProgress"
        status: result.status
        libraryItems: libraryItems
        mediaProgress: mediaProgress
        requestCounter: request.counter
        sourceItemId: request.sourceItemId
    }
end function

'-------------------------------------------------------------------------------
' __InProgress_LoadSourceProgress
'-------------------------------------------------------------------------------
function __InProgress_LoadSourceProgress(server as string, token as dynamic, sourceItemId as dynamic, log as object) as dynamic
    if sourceItemId = invalid or sourceItemId = "" then return invalid

    progressUrl = server + "/api/me/progress/" + sourceItemId.ToStr()
    result = HttpClient_Request(progressUrl, "GET", token, invalid)
    log.write(progressUrl)
    log.write("source progress status = " + SafeString(result.status, ""))

    if result.ok <> true then return invalid

    return MediaProgressMapper_MapProgressItem(result.data)
end function
