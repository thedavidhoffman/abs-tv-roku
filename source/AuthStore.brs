'-------------------------------------------------------------------------------
' GetAuthStore
'-------------------------------------------------------------------------------
function GetAuthStore() as object
    return CreateObject("roRegistrySection", "ABSTV")
end function

'-------------------------------------------------------------------------------
' SaveAuthState
'-------------------------------------------------------------------------------
sub SaveAuthState(server as string, username as string, token as string, userId as dynamic)
    authStore = GetAuthStore()
    authStore.Write("server", server)
    authStore.Write("username", username)
    authStore.Write("token", token)
    if userId <> invalid then authStore.Write("userId", userId)
    authStore.Flush()
end sub

'-------------------------------------------------------------------------------
' LoadAuthState
'-------------------------------------------------------------------------------
function LoadAuthState() as object
    ClearAuthState(false)
    authStore = GetAuthStore()
    return {
        server: authStore.Read("server")
        username: authStore.Read("username")
        token: authStore.Read("token")
        userId: authStore.Read("userId")
    }
end function

'-------------------------------------------------------------------------------
' ClearAuthState
'-------------------------------------------------------------------------------
sub ClearAuthState(clearServer as boolean)
    authStore = GetAuthStore()
    authStore.Delete("token")
    authStore.Delete("userId")
    if clearServer then
        authStore.Delete("server")
        authStore.Delete("username")
    end if
    authStore.Flush()
end sub
