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
    collapseSeries = "0"

    if request.collapseSeries = invalid then
        log.error("Missing collapseSeries for library load request, defaulting to false/0.")
    else
        if request.collapseSeries = true then collapseSeries = "1"
    end if

    if bookLibraryId = invalid or bookLibraryId = "" then
        
        authorizeUrl = server + "/api/authorize"
        log.write(authorizeUrl)

        authResult = HttpClient_Request(authorizeUrl, "POST", token, "")
        
        if authResult.ok <> true then
            return __AttachLibraryItemsRequestMetadata(authResult, request)
        end if

        bookLibraryId = Session_ResolveBookLibraryId(authResult.data)
        
    end if

    if bookLibraryId = invalid or bookLibraryId = "" then
        return __AttachLibraryItemsRequestMetadata({ ok: false, errorMessage: "No book library was found for this account." }, request)
    end if

    allItems = []
    page = 0
    limit = 100
    keepLoading = true

    while keepLoading

        libraryUrl = server + "/api/libraries/" + bookLibraryId + "/items?limit=" + limit.ToStr() + "&page=" + page.ToStr() + "&sort=media.metadata.title&desc=0&minified=0&collapseseries=" + collapseSeries
        log.write(libraryUrl)

        libraryResult = HttpClient_Request(libraryUrl, "GET", token, invalid)
        
        if libraryResult.ok <> true then
            return __AttachLibraryItemsRequestMetadata(libraryResult, request)
        end if

        results = invalid
        if libraryResult.data <> invalid and libraryResult.data.results <> invalid then results = libraryResult.data.results

        if results = invalid or results.Count() = 0 then
            keepLoading = false
        else
            mappedItems = LibraryItemMapper_Map(results)
            for each item in mappedItems
                allItems.Push(item)
            end for

            page = page + 1
            keepLoading = (results.Count() = limit)
        end if
    end while

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
