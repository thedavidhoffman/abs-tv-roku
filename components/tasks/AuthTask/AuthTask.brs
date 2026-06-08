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
        m.top.response = { ok: false, errorMessage: "Invalid auth request." }
        return
    end if

    action = request.action
    if action = "login" then
        m.top.response = login(request)
    else if action = "authorize" then
        m.top.response = authorize(request)
    else if action = "logout" then
        m.top.response = logout(request)
    else
        m.top.response = { ok: false, errorMessage: "Unknown auth request action." }
    end if
end sub

'-------------------------------------------------------------------------------
' login
'-------------------------------------------------------------------------------
function login(request as object) as object
    authResult = authenticateLogin(request)
    if authResult.ok <> true then return authResult

    librariesResult = loadLibraries(authResult.server, authResult.payload.user.token)
    if librariesResult.ok <> true then return librariesResult

    authResult.libraries = librariesResult.libraries
    return authResult
end function

'-------------------------------------------------------------------------------
' authorize
'-------------------------------------------------------------------------------
function authorize(request as object) as object
    authResult = authorizeToken(request)
    if authResult.ok <> true then return authResult

    librariesResult = loadLibraries(authResult.server, request.token)
    if librariesResult.ok <> true then return librariesResult

    authResult.libraries = librariesResult.libraries
    return authResult
end function

'-------------------------------------------------------------------------------
' Libraries API
'-------------------------------------------------------------------------------
' Loads and maps top-level Audiobookshelf libraries from /api/libraries. These
' are typically [audiobooks] or [audiobooks, podcasts].

'-------------------------------------------------------------------------------
' loadLibraries
'-------------------------------------------------------------------------------
function loadLibraries(server as string, token as dynamic) as object

    log = CreateLogger("(API) loadLibraries")

    librariesUrl = server + "/api/libraries"
    log.write(librariesUrl)

    result = HttpClient_Request(librariesUrl, "GET", token, invalid)
    if result.ok <> true then return result

    libraries = LibraryMapper_Map(result.data)

    ' TEMP/DEV TOGGLE: limit libraries to the first entry for one-library testing.
    'if libraries <> invalid and libraries.Count() > 1 then libraries = [libraries[0]]

    return {
        ok: true
        libraries: libraries
    }
end function

'-------------------------------------------------------------------------------
' authenticateLogin
'-------------------------------------------------------------------------------
function authenticateLogin(request as object) as object

    log = CreateLogger("(API) authenticateLogin")

    server = request.server
    body = __BuildLoginBodyJson(request)
    loginUrl = server + "/login"
    result = HttpClient_Request(loginUrl, "POST", invalid, body)

    log.write(loginUrl)
    log.write("status = " + SafeString(result.status, ""))

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
' __BuildLoginBodyJson
'-------------------------------------------------------------------------------
function __BuildLoginBodyJson(request as object) as string
    return Json_Object([
        Json_Pair("username", request.username)
        Json_Pair("password", request.password)
    ])
end function

'-------------------------------------------------------------------------------
' authorizeToken
'-------------------------------------------------------------------------------
function authorizeToken(request as object) as object

    log = CreateBufferedLogger("(API) authorizeToken")

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
' logout
'-------------------------------------------------------------------------------
function logout(request as object) as object
    log = CreateBufferedLogger("(API) logout")
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


