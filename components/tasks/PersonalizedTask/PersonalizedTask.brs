' Gets dynamically generated "shelves" for display on the home page. These
' shelves are tailored to the authenticated user's listening history and library
' contents.

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
        m.top.response = { ok: false, errorMessage: "Invalid personalized request." }
        return
    end if

    m.top.response = loadPersonalized(request)
end sub

'-------------------------------------------------------------------------------
' loadPersonalized
'-------------------------------------------------------------------------------
function loadPersonalized(request as object) as object

    log = CreateLogger("(API) loadPersonalized")

    server = request.server
    token = request.token
    bookLibraryId = request.bookLibraryId

    if bookLibraryId = invalid or bookLibraryId = "" then
        return { ok: false, errorMessage: "No book library was found for this account." }
    end if

    personalizedUrl = server + "/api/libraries/" + bookLibraryId + "/personalized"
    log.write(personalizedUrl)

    result = HttpClient_Request(personalizedUrl, "GET", token, invalid)
    
    if result.ok <> true then
        return result
    end if

    return {
        ok: true
        action: "loadPersonalized"
        bookLibraryId: bookLibraryId
        shelves: result.data
    }
    
end function


