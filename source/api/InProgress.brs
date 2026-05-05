'-------------------------------------------------------------------------------
' InProgress_Load
'-------------------------------------------------------------------------------
function InProgress_Load(request as object) as object

    log = CreateLogger("(API) InProgress_Load")
    server = NormalizeServerUrl(request.server)
    token = request.token

    inProgressUrl = server + "/api/me/items-in-progress"
    result = HttpClient_Request(inProgressUrl, "GET", token, invalid)
    log.write(inProgressUrl)
    log.write("status = " + SafeString(result.status, ""))
    if result.ok <> true then
        log.flush()
        return result
    end if

    libraryItems = []
    if result.data <> invalid and result.data.libraryItems <> invalid then libraryItems = result.data.libraryItems

    log.flush()

    return {
        ok: true
        action: "loadInProgress"
        libraryItems: libraryItems
    }
end function
