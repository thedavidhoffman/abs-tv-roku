'-------------------------------------------------------------------------------
' InProgress_Load
'-------------------------------------------------------------------------------
function InProgress_Load(request as object) as object

    server = NormalizeServerUrl(request.server)
    token = request.token

    result = HttpClient_Request(server + "/api/me/items-in-progress", "GET", token, invalid)
    if result.ok <> true then return result

    libraryItems = []
    if result.data <> invalid and result.data.libraryItems <> invalid then libraryItems = result.data.libraryItems

    return {
        ok: true
        action: "loadInProgress"
        libraryItems: libraryItems
    }
end function
