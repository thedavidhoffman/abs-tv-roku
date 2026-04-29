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
        m.top.response = login(request)
    else if action = "authorize" then
        m.top.response = authorize(request)
    else if action = "logout" then
        m.top.response = Authentication_Logout(request)
    else if action = "loadLibrary" then
        m.top.response = LibraryItems_Load(request)
    else if action = "loadSeries" then
        m.top.response = Series_Load(request)
    else if action = "startPlayback" then
        m.top.response = Playback_Start(request)
    else
        m.top.response = { ok: false, errorMessage: "Unknown request action." }
    end if
end sub

'-------------------------------------------------------------------------------
' login
'-------------------------------------------------------------------------------
function login(request as Object) as Object
    authResult = Authentication_Login(request)
    if authResult.ok <> true then return authResult

    librariesResult = Libraries_Load(authResult.server, authResult.payload.user.token)
    if librariesResult.ok <> true then return librariesResult

    authResult.libraries = librariesResult.libraries
    return authResult
end function

'-------------------------------------------------------------------------------
' authorize
'-------------------------------------------------------------------------------
function authorize(request as Object) as Object
    authResult = Authentication_AuthorizeToken(request)
    if authResult.ok <> true then return authResult

    librariesResult = Libraries_Load(authResult.server, request.token)
    if librariesResult.ok <> true then return librariesResult

    authResult.libraries = librariesResult.libraries
    return authResult
end function
