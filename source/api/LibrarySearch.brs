'-------------------------------------------------------------------------------
' Library Search API
'-------------------------------------------------------------------------------
' Searches within a selected Audiobookshelf library.

'-------------------------------------------------------------------------------
' LibrarySearch_Search
'-------------------------------------------------------------------------------
function LibrarySearch_Search(request as object) as object

    log = CreateLogger("(API) LibrarySearch_Search")

    server = request.server
    token = request.token
    bookLibraryId = request.bookLibraryId
    searchTerm = SearchRules_NormalizeTerm(request.searchTerm)

    if Len(searchTerm) < SearchRules_MinLength() then
        log.write("Invalid search term: minimum of " + SearchRules_MinLength().ToStr() + " characters required")
        return { ok: false, errorMessage: "Enter at least " + SearchRules_MinLength().ToStr() + " characters." }
    end if

    if Len(searchTerm) > SearchRules_MaxLength() then searchTerm = Left(searchTerm, SearchRules_MaxLength())

    if bookLibraryId = invalid or bookLibraryId = "" then
        
        authorizeUrl = server + "/api/authorize"
        log.write(authorizeUrl)

        authResult = HttpClient_Request(authorizeUrl, "POST", token, "")
        
        if authResult.ok <> true then
            return authResult
        end if

        bookLibraryId = Session_ResolveBookLibraryId(authResult.data)
        
    end if

    if bookLibraryId = invalid or bookLibraryId = "" then
        return { ok: false, errorMessage: "No book library was found for this account." }
    end if

    searchUrl = server + "/api/libraries/" + bookLibraryId + "/search?q=" + Encode_Url(searchTerm)
    if request.limit <> invalid then searchUrl = searchUrl + "&limit=" + request.limit.ToStr()
    log.write(searchUrl)

    result = HttpClient_Request(searchUrl, "GET", token, invalid)

    if result.ok <> true then
        return result
    end if

    return {
        ok: true
        action: "searchLibrary"
        bookLibraryId: bookLibraryId
        searchTerm: searchTerm
        searchRequestCounter: request.searchRequestCounter
        results: result.data
    }
end function
