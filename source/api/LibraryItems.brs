'-------------------------------------------------------------------------------
' Library Items API
'-------------------------------------------------------------------------------
' Loads audiobook items from a selected Audiobookshelf library. Top-level library
' discovery lives in Libraries.brs; this module loads the items within a library.

'-------------------------------------------------------------------------------
' LibraryItems_Load
'-------------------------------------------------------------------------------
function LibraryItems_Load(request as Object) as Object
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

    allItems = []
    page = 0
    limit = 100
    keepLoading = true
    collapseSeries = __GetCollapseSeriesQueryValue()

    while keepLoading
        libraryUrl = server + "/api/libraries/" + bookLibraryId + "/items?limit=" + limit.ToStr() + "&page=" + page.ToStr() + "&sort=media.metadata.title&desc=0&minified=0&collapseseries=" + collapseSeries
        libraryResult = HttpClient_Request(libraryUrl, "GET", token, invalid)
        if libraryResult.ok <> true then return libraryResult

        results = invalid
        if libraryResult.data <> invalid and libraryResult.data.results <> invalid then results = libraryResult.data.results

        if results = invalid or results.Count() = 0 then
            keepLoading = false
        else
            for each item in results
                allItems.Push(item)
            end for

            page = page + 1
            keepLoading = (results.Count() = limit)
        end if
    end while

    return {
        ok: true
        action: "loadLibrary"
        bookLibraryId: bookLibraryId
        libraryItems: allItems
    }
end function

'-------------------------------------------------------------------------------
' __GetCollapseSeriesQueryValue
'-------------------------------------------------------------------------------
function __GetCollapseSeriesQueryValue() as string
    settings = SettingsStore_Load()
    if settings <> invalid and settings["series-display"] = "collapse" then return "1"
    return "0"
end function
