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
