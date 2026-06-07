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
        m.top.response = Authentication_Logout(request)
    else
        m.top.response = { ok: false, errorMessage: "Unknown auth request action." }
    end if
end sub

'-------------------------------------------------------------------------------
' login
'-------------------------------------------------------------------------------
function login(request as object) as object
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
function authorize(request as object) as object
    authResult = Authentication_AuthorizeToken(request)
    if authResult.ok <> true then return authResult

    librariesResult = Libraries_Load(authResult.server, request.token)
    if librariesResult.ok <> true then return librariesResult

    authResult.libraries = librariesResult.libraries
    return authResult
end function
