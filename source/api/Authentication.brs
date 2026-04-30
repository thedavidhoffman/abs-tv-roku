'-------------------------------------------------------------------------------
' Authentication_Login
'-------------------------------------------------------------------------------
function Authentication_Login(request as Object) as Object

    ? "(API) Authentication_Login..."

    server = NormalizeServerUrl(request.server)
    body = FormatJson({
        username: request.username
        password: request.password
    })
    result = HttpClient_Request(server + "/login", "POST", invalid, body)
    if result.ok <> true then return result
    payload = result.data

    if payload = invalid or payload.user = invalid or payload.user.token = invalid then
        return { ok: false, errorMessage: "The server response did not include a token." }
    end if

    ? ""

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
function Authentication_AuthorizeToken(request as Object) as Object

    ? "(API) Authentication_AuthorizeToken..."

    server = NormalizeServerUrl(request.server)
    result = HttpClient_Request(server + "/api/authorize", "POST", request.token, "")
    if result.ok <> true then return result

    ? ""
    
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
function Authentication_Logout(request as Object) as Object
    server = NormalizeServerUrl(request.server)
    result = HttpClient_Request(server + "/logout", "POST", request.token, "")
    if result.ok <> true and result.status <> 401 then
        return result
    end if
    return { ok: true, action: "logout" }
end function
