'-------------------------------------------------------------------------------
' Session_BuildAuthenticatedSession
'-------------------------------------------------------------------------------
function Session_BuildAuthenticatedSession(response as object) as object
    payload = response.payload
    sessionToken = payload.user.token
    server = response.server
    username = payload.user.username
    userId = payload.user.id

    return {
        server: server
        username: username
        token: sessionToken
        userId: userId
        bookLibraryId: Session_GetInitialLibraryId(response)
        libraries: response.libraries
    }
end function

'-------------------------------------------------------------------------------
' Session_SaveAuthenticatedSession
'-------------------------------------------------------------------------------
sub Session_SaveAuthenticatedSession(session as object)
    SaveAuthState(session.server, session.username, session.token, session.userId)
end sub

'-------------------------------------------------------------------------------
' Session_GetInitialLibraryId
'-------------------------------------------------------------------------------
function Session_GetInitialLibraryId(response as object) as dynamic
    libraryId = ResolveBookLibraryId(response.payload)
    if libraryId <> invalid and libraryId <> "" then return libraryId

    if response.libraries <> invalid and response.libraries.Count() > 0 then
        return response.libraries[0].id
    end if

    return invalid
end function
