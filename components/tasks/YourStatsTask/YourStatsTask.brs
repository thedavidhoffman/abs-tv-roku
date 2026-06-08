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
        m.top.response = { ok: false, errorMessage: "Invalid stats request." }
        return
    end if

    m.top.response = loadYourStats(request)
end sub

'-------------------------------------------------------------------------------
' loadYourStats
'-------------------------------------------------------------------------------
function loadYourStats(request as object) as object

    log = CreateLogger("(API) loadYourStats")

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
