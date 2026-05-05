'-------------------------------------------------------------------------------
' Authentication_Login
'-------------------------------------------------------------------------------
function Authentication_Login(request as object) as object

    log = CreateLogger("(API) Authentication_Login")

    server = NormalizeServerUrl(request.server)
    body = FormatJson({
        username: request.username
        password: request.password
    })
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
' Authentication_AuthorizeToken
'-------------------------------------------------------------------------------
function Authentication_AuthorizeToken(request as object) as object

    log = CreateLogger("(API) Authentication_AuthorizeToken")

    server = NormalizeServerUrl(request.server)
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
    server = NormalizeServerUrl(request.server)
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
