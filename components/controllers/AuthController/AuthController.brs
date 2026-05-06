'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.authApiTask = m.top.findNode("authApiTask")
    m.savedSession = AuthStore_Load()
    m.isResumingSession = false
    m.loginRequiredCounter = 0
    m.loginFailedCounter = 0
    m.sessionExpiredCounter = 0

    if m.authApiTask <> invalid then m.authApiTask.observeField("response", "onAuthApiResponse")
    m.top.savedSession = m.savedSession
end sub

'-------------------------------------------------------------------------------
' onResumeRequested
'-------------------------------------------------------------------------------
sub onResumeRequested()
    if hasSavedSession() then
        m.isResumingSession = true
        runAuthApiRequest({
            action: "authorize"
            server: m.savedSession.server
            token: m.savedSession.token
        })
    else
        publishLoginRequired("Enter your Audiobookshelf server to begin.")
    end if
end sub

'-------------------------------------------------------------------------------
' onLoginRequestChanged
'-------------------------------------------------------------------------------
sub onLoginRequestChanged()
    request = m.top.loginRequest
    if request = invalid then return

    m.isResumingSession = false
    runAuthApiRequest(request)
end sub

'-------------------------------------------------------------------------------
' onLogoutRequestChanged
'-------------------------------------------------------------------------------
sub onLogoutRequestChanged()
    request = m.top.logoutRequest

    if request <> invalid and request.server <> invalid and request.server <> "" and request.token <> invalid and request.token <> "" then
        runAuthApiRequest({
            action: "logout"
            server: request.server
            token: request.token
        })
    end if

    clearSavedSession()
    publishLoginRequired("Signed out.")
end sub

'-------------------------------------------------------------------------------
' clearSavedSession
'-------------------------------------------------------------------------------
sub clearSavedSession()
    AuthStore_Clear(false)
    if m.savedSession <> invalid then m.savedSession.token = ""
    m.top.savedSession = m.savedSession
end sub

'-------------------------------------------------------------------------------
' hasSavedSession
'-------------------------------------------------------------------------------
function hasSavedSession() as boolean
    if m.savedSession = invalid then return false
    if m.savedSession.token = invalid or m.savedSession.token = "" then return false
    if m.savedSession.server = invalid or m.savedSession.server = "" then return false

    return true
end function

'-------------------------------------------------------------------------------
' runAuthApiRequest
'-------------------------------------------------------------------------------
sub runAuthApiRequest(request as object)
    if m.authApiTask = invalid then return

    m.authApiTask.request = request
    m.authApiTask.control = "run"
end sub

'-------------------------------------------------------------------------------
' onAuthApiResponse
'-------------------------------------------------------------------------------
sub onAuthApiResponse()
    response = m.authApiTask.response
    if response = invalid then return

    action = getAuthResponseAction(response)
    if response.ok <> true then
        handleAuthError(response, action)
    else if action = "login" or action = "authorize" then
        m.isResumingSession = false
        storeAuthenticatedSession(response)
    end if
end sub

'-------------------------------------------------------------------------------
' getAuthResponseAction
'-------------------------------------------------------------------------------
function getAuthResponseAction(response as dynamic) as string
    if response <> invalid and response.action <> invalid then return response.action
    if m.authApiTask <> invalid and m.authApiTask.request <> invalid and m.authApiTask.request.action <> invalid then
        return m.authApiTask.request.action
    end if

    return ""
end function

'-------------------------------------------------------------------------------
' handleAuthError
'-------------------------------------------------------------------------------
sub handleAuthError(response as object, action as string)
    if m.isResumingSession = true then
        m.isResumingSession = false
        clearSavedSession()
        publishLoginRequired("Your saved session expired. Please sign in again.")
    else if response.authExpired = true then
        publishSessionExpired(response.errorMessage)
    else if action = "login" then
        publishLoginFailed("Login failed: " + SafeString(response.errorMessage, "Unknown error."))
    end if
end sub

'-------------------------------------------------------------------------------
' storeAuthenticatedSession
'-------------------------------------------------------------------------------
sub storeAuthenticatedSession(response as object)
    m.savedSession = Session_BuildAuthenticatedSession(response)
    Session_SaveAuthenticatedSession(m.savedSession)
    m.top.savedSession = m.savedSession
    m.top.authenticatedSession = m.savedSession
end sub

'-------------------------------------------------------------------------------
' publishLoginRequired
'-------------------------------------------------------------------------------
sub publishLoginRequired(message as string)
    m.loginRequiredCounter = m.loginRequiredCounter + 1
    m.top.loginRequired = {
        message: message
        counter: m.loginRequiredCounter
    }
end sub

'-------------------------------------------------------------------------------
' publishLoginFailed
'-------------------------------------------------------------------------------
sub publishLoginFailed(message as string)
    m.loginFailedCounter = m.loginFailedCounter + 1
    m.top.loginFailed = {
        message: message
        counter: m.loginFailedCounter
    }
end sub

'-------------------------------------------------------------------------------
' publishSessionExpired
'-------------------------------------------------------------------------------
sub publishSessionExpired(message as dynamic)
    clearSavedSession()

    m.sessionExpiredCounter = m.sessionExpiredCounter + 1
    m.top.sessionExpired = {
        message: SafeString(message, "Your session expired. Please sign in again.")
        counter: m.sessionExpiredCounter
    }
end sub
