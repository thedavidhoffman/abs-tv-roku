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

    server = NormalizeServerUrl(request.server)
    token = request.token
    bookLibraryId = request.bookLibraryId

    if bookLibraryId = invalid or bookLibraryId = "" then
        authorizeUrl = server + "/api/authorize"
        authResult = HttpClient_Request(authorizeUrl, "POST", token, "")
        log.add(authorizeUrl)
        log.add("status = " + SafeString(authResult.status, ""))
        if authResult.ok <> true then
            log.flush()
            return authResult
        end if
        bookLibraryId = ResolveBookLibraryId(authResult.data)
    end if

    if bookLibraryId = invalid or bookLibraryId = "" then
        log.flush()
        return { ok: false, errorMessage: "No book library was found for this account." }
    end if

    personalizedUrl = server + "/api/libraries/" + bookLibraryId + "/personalized"
    result = HttpClient_Request(personalizedUrl, "GET", token, invalid)
    log.add(personalizedUrl)
    log.add("status = " + SafeString(result.status, ""))
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
