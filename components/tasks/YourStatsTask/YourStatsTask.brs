'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.log = CreateLogger("YourStatsTask")
    m.log.write("init")
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

    m.top.response = fetchListeningStats(request)
end sub

'-------------------------------------------------------------------------------
' fetchListeningStats
'-------------------------------------------------------------------------------
function fetchListeningStats(request as object) as object

    statsUrl = request.server + "/api/me/listening-stats"
    m.log.write(statsUrl)

    result = HttpClient_Request(statsUrl, "GET", request.token, invalid)

    if result.ok <> true then return result

    return {
        ok: true
        action: "fetchListeningStats"
        status: result.status
        stats: result.data
    }

end function
