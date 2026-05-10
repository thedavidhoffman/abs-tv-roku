'-------------------------------------------------------------------------------
' Library Items API
'-------------------------------------------------------------------------------
' Loads audiobook items from a selected Audiobookshelf library. Top-level library
' discovery lives in Libraries.brs; this module loads the items within a library.

'-------------------------------------------------------------------------------
' LibraryItems_Load
'-------------------------------------------------------------------------------
function LibraryItems_Load(request as object) as object

    log = CreateLogger("(API) LibraryItems_Load")

    server = request.server
    token = request.token
    bookLibraryId = request.bookLibraryId

    if bookLibraryId = invalid or bookLibraryId = "" then
        authorizeUrl = server + "/api/authorize"
        authResult = HttpClient_Request(authorizeUrl, "POST", token, "")
        log.write(authorizeUrl)
        log.write("status = " + SafeString(authResult.status, ""))
        if authResult.ok <> true then
            log.flush()
            return __AttachLibraryItemsRequestMetadata(authResult, request)
        end if
        bookLibraryId = ResolveBookLibraryId(authResult.data)
    end if

    if bookLibraryId = invalid or bookLibraryId = "" then
        log.flush()
        return __AttachLibraryItemsRequestMetadata({ ok: false, errorMessage: "No book library was found for this account." }, request)
    end if

    allItems = []
    page = 0
    limit = 100
    keepLoading = true
    collapseSeries = __GetCollapseSeriesQueryValue(request)

    while keepLoading
        libraryUrl = server + "/api/libraries/" + bookLibraryId + "/items?limit=" + limit.ToStr() + "&page=" + page.ToStr() + "&sort=media.metadata.title&desc=0&minified=0&collapseseries=" + collapseSeries
        libraryResult = HttpClient_Request(libraryUrl, "GET", token, invalid)
        log.write(libraryUrl)
        log.write("status = " + SafeString(libraryResult.status, ""))
        if libraryResult.ok <> true then
            log.flush()
            return __AttachLibraryItemsRequestMetadata(libraryResult, request)
        end if

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

    log.flush()

    return __AttachLibraryItemsRequestMetadata({
        ok: true
        action: "loadLibrary"
        bookLibraryId: bookLibraryId
        libraryItems: allItems
    }, request)
end function

'-------------------------------------------------------------------------------
' __AttachLibraryItemsRequestMetadata
'-------------------------------------------------------------------------------
function __AttachLibraryItemsRequestMetadata(response as object, request as object) as object
    if response = invalid then response = {}
    response.action = "loadLibrary"
    response.cacheKey = request.cacheKey
    response.requestGeneration = request.requestGeneration
    return response
end function

'-------------------------------------------------------------------------------
' __GetCollapseSeriesQueryValue
'-------------------------------------------------------------------------------
function __GetCollapseSeriesQueryValue(request as object) as string
    if request <> invalid and request.collapseSeries <> invalid then
        if request.collapseSeries = true then return "1"
        return "0"
    end if

    settings = SettingsStore_Load()
    if settings <> invalid and settings["series-display"] = "collapse" then return "1"
    return "0"
end function
