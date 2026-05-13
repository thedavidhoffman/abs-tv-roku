'-------------------------------------------------------------------------------
' Authentication_Login
'-------------------------------------------------------------------------------
function Authentication_Login(request as object) as object

    log = CreateLogger("(API) Authentication_Login")

    server = request.server
    body = __BuildLoginBodyJson(request)
    loginUrl = server + "/login"
    result = HttpClient_Request(loginUrl, "POST", invalid, body)
    log.write(loginUrl)
    log.write("status = " + SafeString(result.status, ""))
    if result.ok <> true then
        log.flush()
        return result
    end if
    payload = result.data

    if payload = invalid or payload.user = invalid or payload.user.token = invalid then
        log.flush()
        return { ok: false, errorMessage: "The server response did not include a token." }
    end if

    log.flush()

    return {
        ok: true
        action: "login"
        server: server
        payload: payload
    }
end function

'-------------------------------------------------------------------------------
' __BuildLoginBodyJson
'-------------------------------------------------------------------------------
function __BuildLoginBodyJson(request as object) as string
    return "{" + __JoinLoginJsonParts([
        __LoginJsonPair("username", request.username)
        __LoginJsonPair("password", request.password)
    ]) + "}"
end function

'-------------------------------------------------------------------------------
' __LoginJsonPair
'-------------------------------------------------------------------------------
function __LoginJsonPair(name as string, value as dynamic) as string
    return __LoginJsonString(name) + ":" + __LoginJsonString(value)
end function

'-------------------------------------------------------------------------------
' __LoginJsonString
'-------------------------------------------------------------------------------
function __LoginJsonString(value as dynamic) as string
    text = SafeString(value, "")
    text = String_Replace(text, "\", "\\")
    text = String_Replace(text, Chr(34), "\" + Chr(34))
    return Chr(34) + text + Chr(34)
end function

'-------------------------------------------------------------------------------
' __JoinLoginJsonParts
'-------------------------------------------------------------------------------
function __JoinLoginJsonParts(parts as object) as string
    text = ""
    if parts = invalid then return text

    for i = 0 to parts.Count() - 1
        if i > 0 then text = text + ","
        text = text + parts[i]
    end for

    return text
end function

'-------------------------------------------------------------------------------
' Authentication_AuthorizeToken
'-------------------------------------------------------------------------------
function Authentication_AuthorizeToken(request as object) as object

    log = CreateLogger("(API) Authentication_AuthorizeToken")

    server = request.server
    authorizeUrl = server + "/api/authorize"
    result = HttpClient_Request(authorizeUrl, "POST", request.token, "")
    log.write(authorizeUrl)
    log.write("status = " + SafeString(result.status, ""))
    if result.ok <> true then
        log.flush()
        return result
    end if

    log.flush()

    return {
        ok: true
        action: "authorize"
        server: server
        token: request.token
        payload: result.data
    }
end function

'-------------------------------------------------------------------------------
' Authentication_Logout
'-------------------------------------------------------------------------------
function Authentication_Logout(request as object) as object
    log = CreateLogger("(API) Authentication_Logout")
    server = request.server
    logoutUrl = server + "/logout"
    result = HttpClient_Request(logoutUrl, "POST", request.token, "")
    log.write(logoutUrl)
    log.write("status = " + SafeString(result.status, ""))
    if result.ok <> true and result.status <> 401 then
        log.flush()
        return result
    end if
    log.flush()
    return { ok: true, action: "logout" }
end function
