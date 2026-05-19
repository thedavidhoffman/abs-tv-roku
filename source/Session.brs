'-------------------------------------------------------------------------------
' Session_BuildAuthenticatedSession
'-------------------------------------------------------------------------------
function Session_BuildAuthenticatedSession(response as object) as object
    payload = response.payload
    sessionToken = response.token
    if payload <> invalid and payload.user <> invalid and payload.user.token <> invalid then sessionToken = payload.user.token
    server = NormalizeServerUrl(response.server)
    username = payload.user.username
    userId = payload.user.id

    return {
        server: server
        username: username
        token: sessionToken
        userId: userId
        bookLibraryId: Session_GetInitialLibraryId(response)
        libraries: response.libraries
        mediaProgress: MediaProgressMapper_Map(payload)
    }
end function

'-------------------------------------------------------------------------------
' Session_SaveAuthenticatedSession
'-------------------------------------------------------------------------------
sub Session_SaveAuthenticatedSession(session as object)
    AuthStore_Save(session.server, session.username, session.token, session.userId)
end sub

'-------------------------------------------------------------------------------
' Session_GetInitialLibraryId
'-------------------------------------------------------------------------------
function Session_GetInitialLibraryId(response as object) as dynamic
    libraryId = Session_ResolveBookLibraryId(response.payload)
    if libraryId <> invalid and libraryId <> "" then return libraryId

    if response.libraries <> invalid and response.libraries.Count() > 0 then
        return response.libraries[0].id
    end if

    return invalid
end function

'-------------------------------------------------------------------------------
' Session_ResolveBookLibraryId
'-------------------------------------------------------------------------------
function Session_ResolveBookLibraryId(payload as dynamic) as dynamic
    if payload = invalid then return invalid

    if payload.userDefaultLibraryId <> invalid then
        defaultId = payload.userDefaultLibraryId.ToStr()
        if payload.libraries <> invalid then
            for each library in payload.libraries
                if library.id = defaultId and library.mediaType = "book" then
                    return defaultId
                end if
            end for
        end if
    end if

    libraries = invalid
    if payload.libraries <> invalid then libraries = payload.libraries
    if libraries = invalid and payload.user <> invalid and payload.user.librariesAccessible <> invalid then
        libraries = payload.user.librariesAccessible
    end if

    if libraries <> invalid then
        for each library in libraries
            if library.mediaType = "book" then return library.id
        end for
    end if

    return invalid
end function
