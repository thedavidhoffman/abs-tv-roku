' Gets dynamically generated "shelves" for display on the home page. These
' shelves are tailored to the authenticated user's listening history and library
' contents.

'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.log = CreateLogger("PersonalizedTask")
    m.log.write("init")
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

    m.top.response = fetchPersonalizedShelves(request)
end sub

'-------------------------------------------------------------------------------
' fetchPersonalizedShelves
'-------------------------------------------------------------------------------
function fetchPersonalizedShelves(request as object) as object

    if request.bookLibraryId = invalid or request.bookLibraryId = "" then
        return { ok: false, errorMessage: "No book library was found for this account." }
    end if

    personalizedUrl = request.server + "/api/libraries/" + request.bookLibraryId + "/personalized"
    m.log.write(personalizedUrl)

    result = HttpClient_Request(personalizedUrl, "GET", request.token, invalid)
    
    if result.ok <> true then return result
    
    return {
        ok: true
        action: "fetchPersonalizedShelves"
        bookLibraryId: request.bookLibraryId
        shelves: result.data
    }
    
end function


