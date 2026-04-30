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

    ? "(API) Personalized_Load..."

    server = NormalizeServerUrl(request.server)
    token = request.token
    bookLibraryId = request.bookLibraryId

    if bookLibraryId = invalid or bookLibraryId = "" then
        authResult = HttpClient_Request(server + "/api/authorize", "POST", token, "")
        if authResult.ok <> true then return authResult
        bookLibraryId = ResolveBookLibraryId(authResult.data)
    end if

    if bookLibraryId = invalid or bookLibraryId = "" then
        return { ok: false, errorMessage: "No book library was found for this account." }
    end if

    result = HttpClient_Request(server + "/api/libraries/" + bookLibraryId + "/personalized", "GET", token, invalid)
    if result.ok <> true then return result

    ? ""

    return {
        ok: true
        action: "loadPersonalized"
        bookLibraryId: bookLibraryId
        shelves: result.data
    }
end function
