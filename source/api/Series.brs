'-------------------------------------------------------------------------------
' Series_Load
'-------------------------------------------------------------------------------
function Series_Load(request as object) as object

    log = CreateLogger("(API) Series_Load")

    server = request.server
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
    displayIndex = 1
    keepLoading = true

    while keepLoading
        libraryUrl = server + "/api/libraries/" + bookLibraryId + "/items?limit=" + limit.ToStr() + "&page=" + page.ToStr() + "&sort=sequence&desc=0&minified=0"
        if seriesFilter <> "" then libraryUrl = libraryUrl + seriesFilter

        libraryResult = HttpClient_Request(libraryUrl, "GET", token, invalid)
        log.write(libraryUrl)
        log.write("status = " + SafeString(libraryResult.status, "unknown"))

        if libraryResult.ok <> true then return libraryResult

        results = invalid
        if libraryResult.data <> invalid and libraryResult.data.results <> invalid then results = libraryResult.data.results

        if results = invalid or results.Count() = 0 then
            keepLoading = false
        else
            for each item in results
                if __IsDisplayableSeriesItem(item) then
                    __ApplyFallbackSeriesSequence(item, displayIndex)
                    displayIndex = displayIndex + 1
                end if

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
        title: request.title
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

'-------------------------------------------------------------------------------
' __ApplyFallbackSeriesSequence
'-------------------------------------------------------------------------------
sub __ApplyFallbackSeriesSequence(item as dynamic, displayIndex as integer)
    if item = invalid then return
    if __GetSeriesSequence(item) <> "" then return

    sequence = displayIndex.ToStr()
    item.seriesSequence = sequence

    if item.media <> invalid and item.media.metadata <> invalid then
        item.media.metadata.seriesSequence = sequence
    end if
end sub

'-------------------------------------------------------------------------------
' __IsDisplayableSeriesItem
'-------------------------------------------------------------------------------
function __IsDisplayableSeriesItem(item as dynamic) as boolean
    if item = invalid then return false
    return item.mediaType = invalid or item.mediaType = "book"
end function

'-------------------------------------------------------------------------------
' __GetSeriesSequence
'-------------------------------------------------------------------------------
function __GetSeriesSequence(item as dynamic) as string
    if item = invalid then return ""

    metadata = {}
    if item.media <> invalid and item.media.metadata <> invalid then metadata = item.media.metadata

    if metadata.seriesSequence <> invalid then return metadata.seriesSequence.ToStr()
    if metadata.sequence <> invalid then return metadata.sequence.ToStr()
    if metadata.series <> invalid then return __GetSequenceFromSeriesValue(metadata.series)

    if item.seriesSequence <> invalid then return item.seriesSequence.ToStr()
    if item.sequence <> invalid then return item.sequence.ToStr()

    return ""
end function

'-------------------------------------------------------------------------------
' __GetSequenceFromSeriesValue
'-------------------------------------------------------------------------------
function __GetSequenceFromSeriesValue(series as dynamic) as string
    if series = invalid then return ""

    seriesType = Type(series)
    if seriesType = "roArray" then
        if series.Count() = 0 then return ""

        for each seriesEntry in series
            sequence = __GetSeriesEntrySequence(seriesEntry)
            if sequence <> "" then return sequence
        end for
    else if seriesType = "roAssociativeArray" then
        return __GetSeriesEntrySequence(series)
    end if

    return ""
end function

'-------------------------------------------------------------------------------
' __GetSeriesEntrySequence
'-------------------------------------------------------------------------------
function __GetSeriesEntrySequence(seriesEntry as dynamic) as string
    if seriesEntry = invalid then return ""
    if Type(seriesEntry) <> "roAssociativeArray" then return ""
    if seriesEntry.sequence <> invalid then return seriesEntry.sequence.ToStr()
    if seriesEntry.seriesSequence <> invalid then return seriesEntry.seriesSequence.ToStr()
    return ""
end function
