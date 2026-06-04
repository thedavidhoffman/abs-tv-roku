'-------------------------------------------------------------------------------
' YourStats API
'-------------------------------------------------------------------------------
' Loads listening statistics for the authenticated Audiobookshelf user.

'-------------------------------------------------------------------------------
' YourStats_Load
'-------------------------------------------------------------------------------
function YourStats_Load(request as object) as object

    log = CreateLogger("(API) YourStats_Load")

    server = request.server
    token = request.token

    statsUrl = server + "/api/me/listening-stats"
    log.write(statsUrl)

    result = HttpClient_Request(statsUrl, "GET", token, invalid)

    if result.ok <> true then
        return result
    end if

    return {
        ok: true
        action: "loadYourStats"
        status: result.status
        stats: result.data
    }
end function
