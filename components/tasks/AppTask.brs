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
    return {
        ok: true
        action: "login"
        server: server
        payload: payload
    }
end function

'-------------------------------------------------------------------------------
' doAuthorize
'-------------------------------------------------------------------------------
function doAuthorize(request as Object) as Object
    server = NormalizeServerUrl(request.server)
    result = doRequest(server + "/api/authorize", "POST", request.token, "")
    if result.ok <> true then return result
    return {
        ok: true
        action: "authorize"
        server: server
        payload: result.data
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
