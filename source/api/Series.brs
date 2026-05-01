'-------------------------------------------------------------------------------
' Series_Load
'-------------------------------------------------------------------------------
function Series_Load(request as object) as object

    log = Logger("(API) Series_Load")
    
    server = NormalizeServerUrl(request.server)
    token = request.token
    bookLibraryId = request.bookLibraryId
    seriesFilter = __GetSeriesFilterQuery(request.seriesId)

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

    while keepLoading
        libraryUrl = server + "/api/libraries/" + bookLibraryId + "/items?limit=" + limit.ToStr() + "&page=" + page.ToStr()
        if seriesFilter <> "" then libraryUrl = libraryUrl + seriesFilter

        libraryResult = HttpClient_Request(libraryUrl, "GET", token, invalid)
        log.add(libraryUrl)
        log.add("status = " + SafeString(libraryResult.status, "unknown"))

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

    log.flush()

    return {
        ok: true
        action: "loadSeries"
        bookLibraryId: bookLibraryId
        seriesId: request.seriesId
        sourceItemIndex: request.sourceItemIndex
        libraryItems: allItems
    }
end function

'-------------------------------------------------------------------------------
' __GetSeriesFilterQuery
'-------------------------------------------------------------------------------
function __GetSeriesFilterQuery(seriesId as dynamic) as string
    if seriesId = invalid then return ""

    seriesIdText = seriesId.ToStr()
    if seriesIdText = "" then return ""

    return "&filter=series." + Encode_Url(Encode_Base64(seriesIdText))
end function
