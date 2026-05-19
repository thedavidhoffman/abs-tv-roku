'-------------------------------------------------------------------------------
' Personalized API
'-------------------------------------------------------------------------------
' Gets dynamically generated "shelves" for display on the home page. These
' shelves are tailored to the authenticated user's listening history and library
' contents.

'-------------------------------------------------------------------------------
' Personalized_Load
'-------------------------------------------------------------------------------
function Personalized_Load(request as object) as object

    log = CreateLogger("(API) Personalized_Load")

    server = request.server
    token = request.token
    bookLibraryId = request.bookLibraryId

    if bookLibraryId = invalid or bookLibraryId = "" then
        
        authorizeUrl = server + "/api/authorize"
        log.write(authorizeUrl)
        
        authResult = HttpClient_Request(authorizeUrl, "POST", token, "")
        
        if authResult.ok <> true then
            log.flush()
            return authResult
        end if
        
        bookLibraryId = Session_ResolveBookLibraryId(authResult.data)
    end if

    if bookLibraryId = invalid or bookLibraryId = "" then
        log.flush()
        return { ok: false, errorMessage: "No book library was found for this account." }
    end if

    personalizedUrl = server + "/api/libraries/" + bookLibraryId + "/personalized"
    log.write(personalizedUrl)

    result = HttpClient_Request(personalizedUrl, "GET", token, invalid)
    
    if result.ok <> true then
        log.flush()
        return result
    end if

    log.flush()

    return {
        ok: true
        action: "loadPersonalized"
        bookLibraryId: bookLibraryId
        shelves: result.data
    }
end function
