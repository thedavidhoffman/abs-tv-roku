'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.log = CreateLogger("LibraryItemsTask")
    m.log.write("init")
    m.top.functionName = "executeRequest"
end sub

'-------------------------------------------------------------------------------
' executeRequest
'-------------------------------------------------------------------------------
sub executeRequest()
    request = m.top.request
    if request = invalid then
        m.top.response = { ok: false, errorMessage: "Invalid library items request." }
        return
    end if

    m.top.response = fetchAllLibraryItems(request)
end sub

'-------------------------------------------------------------------------------
' fetchAllLibraryItems
'-------------------------------------------------------------------------------
function fetchAllLibraryItems(request as object) as object

    log = CreateLogger("(API) fetchAllLibraryItems")

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
        return {
            ok: false
            action: "loadLibrary"
            errorMessage: "No book library was found for this account."
            cacheKey: request.cacheKey
            requestGeneration: request.requestGeneration
        }
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
            libraryResult.action = "loadLibrary"
            libraryResult.cacheKey = request.cacheKey
            libraryResult.requestGeneration = request.requestGeneration
            return libraryResult
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

    return {
        ok: true
        action: "loadLibrary"
        bookLibraryId: bookLibraryId
        libraryItems: allItems
        cacheKey: request.cacheKey
        requestGeneration: request.requestGeneration
    }
end function

