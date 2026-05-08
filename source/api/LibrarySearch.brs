'-------------------------------------------------------------------------------
' Library Search API
'-------------------------------------------------------------------------------
' Searches within a selected Audiobookshelf library.

'-------------------------------------------------------------------------------
' LibrarySearch_Search
'-------------------------------------------------------------------------------
function LibrarySearch_Search(request as object) as object

    log = CreateLogger("(API) LibrarySearch_Search", false)

    server = request.server
    token = request.token
    bookLibraryId = request.bookLibraryId
    searchTerm = StringUtils_CollapseWhitespace(SafeString(request.searchTerm, ""))

    if Len(searchTerm) < 3 then
        log.write("Invalid search term: minimum of 3 characters required")
        return { ok: false, errorMessage: "Enter at least 3 characters." }
    end if

    if Len(searchTerm) > 25 then searchTerm = Left(searchTerm, 25)

    if bookLibraryId = invalid or bookLibraryId = "" then
        authorizeUrl = server + "/api/authorize"
        authResult = HttpClient_Request(authorizeUrl, "POST", token, "")
        log.write(authorizeUrl)
        log.write("status = " + SafeString(authResult.status, ""))
        if authResult.ok <> true then
            return authResult
        end if
        bookLibraryId = ResolveBookLibraryId(authResult.data)
    end if

    if bookLibraryId = invalid or bookLibraryId = "" then
        log.flush()
        return { ok: false, errorMessage: "No book library was found for this account." }
    end if

    searchUrl = server + "/api/libraries/" + bookLibraryId + "/search?q=" + Encode_Url(searchTerm)
    if request.limit <> invalid then searchUrl = searchUrl + "&limit=" + request.limit.ToStr()

    result = HttpClient_Request(searchUrl, "GET", token, invalid)
    log.write(searchUrl)
    log.write("status = " + SafeString(result.status, ""))
    if result.ok <> true then
        log.flush()
        return result
    end if

    log.flush()

    return {
        ok: true
        action: "searchLibrary"
        bookLibraryId: bookLibraryId
        searchTerm: searchTerm
        results: result.data
    }
end function
