'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()

    m.log = CreateLogger("LibraryController")

    m.allItemsTask = m.top.findNode("allItemsTask")
    m.collapsedItemsTask = m.top.findNode("collapsedItemsTask")
    m.loadRequest = invalid
    m.displaySettings = invalid
    m.appliedSeriesDisplay = invalid
    m.cache = []
    m.cacheKeys = {
        allTitles: "allTitles"
        collapsedSeries: "collapsedSeries"
    }
    m.requestGeneration = 0
    m.hasPublishedLibraryItems = false
    m.pendingSearchRequest = invalid
    m.pendingSeriesRowsRequest = invalid
    m.pendingSeriesItemsRequest = invalid

    if m.allItemsTask <> invalid then m.allItemsTask.observeField("response", "onAllItemsResponse")
    if m.collapsedItemsTask <> invalid then m.collapsedItemsTask.observeField("response", "onCollapsedItemsResponse")

    m.top.allLibraryItems = []
    m.top.libraryItems = []
    m.top.loading = false
end sub

'-------------------------------------------------------------------------------
' onSearchRequestChanged
'-------------------------------------------------------------------------------
sub onSearchRequestChanged()
    request = m.top.searchRequest
    if request = invalid then return

    if cacheHas(m.cacheKeys.allTitles) <> true then
        m.pendingSearchRequest = request
        return
    end if

    publishSearchResponse(request)
end sub

'-------------------------------------------------------------------------------
' publishSearchResponse
'-------------------------------------------------------------------------------
sub publishSearchResponse(request as object)
    if request = invalid then return

    searchTerm = SearchRules_NormalizeTerm(request.searchTerm)

    m.top.searchResponse = {
        ok: true
        action: "searchLibrary"
        searchTerm: searchTerm
        requestGeneration: m.requestGeneration
        libraryItems: getSearchItemsFromCache(searchTerm)
    }
end sub

'-------------------------------------------------------------------------------
' onSeriesRowsRequestChanged
'-------------------------------------------------------------------------------
sub onSeriesRowsRequestChanged()
    request = m.top.seriesRowsRequest
    if request <> "loadSeriesRows" then return

    if hasAllLibraryCaches() = false then
        m.pendingSeriesRowsRequest = request
        return
    end if

    publishSeriesRowsResponse(request)
end sub

'-------------------------------------------------------------------------------
' publishSeriesRowsResponse
'-------------------------------------------------------------------------------
sub publishSeriesRowsResponse(request as string)
    if request <> "loadSeriesRows" then return
    
    m.top.seriesRowsResponse = {
        ok: true
        action: "loadSeriesRows"
        requestGeneration: m.requestGeneration
        seriesRows: getSeriesRowsFromCache()
    }
end sub

'-------------------------------------------------------------------------------
' onSeriesItemsRequestChanged
'-------------------------------------------------------------------------------
sub onSeriesItemsRequestChanged()
    request = m.top.seriesItemsRequest
    if request = invalid then return

    if cacheHas(m.cacheKeys.allTitles) <> true then
        m.pendingSeriesItemsRequest = request
        return
    end if

    publishSeriesItemsResponse(request)
end sub

'-------------------------------------------------------------------------------
' publishSeriesItemsResponse
'-------------------------------------------------------------------------------
sub publishSeriesItemsResponse(request as object)
    if request = invalid then return

    seriesId = request.seriesId

    m.top.seriesItemsResponse = {
        ok: true
        action: "loadSeries"
        seriesId: seriesId
        title: request.title
        sourceItemIndex: request.sourceItemIndex
        sourceView: request.sourceView
        requestGeneration: m.requestGeneration
        libraryItems: getSeriesItemsFromCache(seriesId, request.libraryItemIds)
    }
end sub

'-------------------------------------------------------------------------------
' onLoadRequestChanged
'-------------------------------------------------------------------------------
sub onLoadRequestChanged()
    m.loadRequest = m.top.loadRequest
    reloadActiveLibrary()
end sub

'-------------------------------------------------------------------------------
' onDisplaySettingsChanged
'-------------------------------------------------------------------------------
sub onDisplaySettingsChanged()
    settings = m.top.displaySettings
    if settings = invalid then return

    seriesDisplay = getSeriesDisplaySetting(settings)
    previousSeriesDisplay = m.appliedSeriesDisplay
    m.displaySettings = settings
    m.appliedSeriesDisplay = seriesDisplay

    if previousSeriesDisplay = invalid then
        if hasAllLibraryCaches() then publishCurrentRootLibraryItems()
        return
    end if

    if previousSeriesDisplay <> seriesDisplay then publishCurrentRootLibraryItems()
end sub

'-------------------------------------------------------------------------------
' reloadActiveLibrary
'-------------------------------------------------------------------------------
function reloadActiveLibrary() as boolean
    if hasValidLoadRequest() = false then return false

    m.top.loading = true
    beginNewCacheGeneration()

    runLibraryItemsRequest(m.allItemsTask, m.cacheKeys.allTitles, false)
    runLibraryItemsRequest(m.collapsedItemsTask, m.cacheKeys.collapsedSeries, true)
    return true
end function

'-------------------------------------------------------------------------------
' clearCache
'-------------------------------------------------------------------------------
function clearCache() as boolean
    beginNewCacheGeneration()
    m.top.loading = false
    return true
end function

'-------------------------------------------------------------------------------
' beginNewCacheGeneration
'-------------------------------------------------------------------------------
sub beginNewCacheGeneration()
    ' Each library reload starts a new request generation. Library item loads run
    ' in parallel, so late responses from older generations must be ignored.
    m.requestGeneration = m.requestGeneration + 1
    cacheClear()
    if m.hasPublishedLibraryItems then m.top.allLibraryItems = []
    m.pendingSearchRequest = invalid
    m.pendingSeriesRowsRequest = invalid
    m.pendingSeriesItemsRequest = invalid
    m.top.errorResponse = invalid
    if m.hasPublishedLibraryItems then publishItems([])
end sub

'-------------------------------------------------------------------------------
' hasValidLoadRequest
'-------------------------------------------------------------------------------
function hasValidLoadRequest() as boolean
    if m.loadRequest = invalid then return false
    if m.loadRequest.server = invalid or m.loadRequest.server = "" then return false
    if m.loadRequest.token = invalid or m.loadRequest.token = "" then return false
    if m.loadRequest.bookLibraryId = invalid or m.loadRequest.bookLibraryId = "" then return false

    return true
end function

'-------------------------------------------------------------------------------
' runLibraryItemsRequest
'-------------------------------------------------------------------------------
sub runLibraryItemsRequest(task as dynamic, cacheKey as string, collapseSeries as boolean)
    if task = invalid then return

    task.request = {
        action: "loadLibrary"
        server: m.loadRequest.server
        token: m.loadRequest.token
        bookLibraryId: m.loadRequest.bookLibraryId
        cacheKey: cacheKey
        collapseSeries: collapseSeries
        requestGeneration: m.requestGeneration
    }
    task.control = "run"
end sub

'-------------------------------------------------------------------------------
' onAllItemsResponse
'-------------------------------------------------------------------------------
sub onAllItemsResponse()
    if m.allItemsTask = invalid then return
    handleLibraryItemsResponse(m.allItemsTask.response)
end sub

'-------------------------------------------------------------------------------
' onCollapsedItemsResponse
'-------------------------------------------------------------------------------
sub onCollapsedItemsResponse()
    if m.collapsedItemsTask = invalid then return
    handleLibraryItemsResponse(m.collapsedItemsTask.response)
end sub

'-------------------------------------------------------------------------------
' handleLibraryItemsResponse
'-------------------------------------------------------------------------------
sub handleLibraryItemsResponse(response as dynamic)

    if response = invalid then return
    
    ' Ignore stale task responses from a previous library reload.
    if response.requestGeneration <> m.requestGeneration then
        log.write("requestGeneration mismatch, ignoring response.")
        log.write("...response.requestGeneration = " + response.requestGeneration)
        log.write("...m.requestGeneration = " + m.requestGeneration)
        return
    end if

    shouldPublishPendingCacheRequests = false

    if response.ok <> true then
        m.top.loading = false
        m.top.errorResponse = response
        return
    end if

    if response.cacheKey = m.cacheKeys.collapsedSeries then
        items = getResponseLibraryItems(response)
        cacheSet(m.cacheKeys.collapsedSeries, sortCollapsedSeriesItems(items))
    else if response.cacheKey = m.cacheKeys.allTitles then
        items = getResponseLibraryItems(response)
        cacheSet(m.cacheKeys.allTitles, items)
        shouldPublishPendingCacheRequests = true
    else
        return
    end if

    m.top.loading = (hasAllLibraryCaches() = false)
    if hasAllLibraryCaches() then publishCurrentLibraryItems()

    if shouldPublishPendingCacheRequests then publishPendingSearchResponse()
    if shouldPublishPendingCacheRequests then publishPendingSeriesItemsResponse()
    if hasAllLibraryCaches() then publishPendingSeriesRowsResponse()
end sub

'-------------------------------------------------------------------------------
' hasAllLibraryCaches
'-------------------------------------------------------------------------------
function hasAllLibraryCaches() as boolean
    return cacheHas(m.cacheKeys.allTitles) = true and cacheHas(m.cacheKeys.collapsedSeries) = true
end function

'-------------------------------------------------------------------------------
' publishPendingSearchResponse
'-------------------------------------------------------------------------------
sub publishPendingSearchResponse()
    if m.pendingSearchRequest = invalid then return

    request = m.pendingSearchRequest
    m.pendingSearchRequest = invalid
    publishSearchResponse(request)
end sub

'-------------------------------------------------------------------------------
' publishPendingSeriesRowsResponse
'-------------------------------------------------------------------------------
sub publishPendingSeriesRowsResponse()
    if m.pendingSeriesRowsRequest = invalid then return

    request = m.pendingSeriesRowsRequest
    m.pendingSeriesRowsRequest = invalid
    publishSeriesRowsResponse(request)
end sub

'-------------------------------------------------------------------------------
' publishPendingSeriesItemsResponse
'-------------------------------------------------------------------------------
sub publishPendingSeriesItemsResponse()
    if m.pendingSeriesItemsRequest = invalid then return

    request = m.pendingSeriesItemsRequest
    m.pendingSeriesItemsRequest = invalid
    publishSeriesItemsResponse(request)
end sub

'-------------------------------------------------------------------------------
' publishCurrentLibraryItems
'-------------------------------------------------------------------------------
sub publishCurrentLibraryItems()
    m.top.allLibraryItems = cacheGetItems(m.cacheKeys.allTitles)
    publishCurrentRootLibraryItems()
end sub

'-------------------------------------------------------------------------------
' publishCurrentRootLibraryItems
'-------------------------------------------------------------------------------
sub publishCurrentRootLibraryItems()
    if shouldUseCollapsedSeriesItems() then
        publishItems(cacheGetItems(m.cacheKeys.collapsedSeries))
    else
        publishItems(cacheGetItems(m.cacheKeys.allTitles))
    end if
end sub

'-------------------------------------------------------------------------------
' publishItems
'-------------------------------------------------------------------------------
sub publishItems(items as object)
    if items = invalid then items = []

    m.top.libraryItems = items
    m.hasPublishedLibraryItems = true
    m.top.libraryItemsChanged = true
end sub

'-------------------------------------------------------------------------------
' shouldUseCollapsedSeriesItems
'-------------------------------------------------------------------------------
function shouldUseCollapsedSeriesItems() as boolean
    return getSeriesDisplaySetting(m.displaySettings) = "collapse"
end function

'-------------------------------------------------------------------------------
' getSeriesDisplaySetting
'-------------------------------------------------------------------------------
function getSeriesDisplaySetting(settings as dynamic) as string
    keys = SettingsStore_Keys()
    return SettingsStore_GetSettingValue(settings, keys.seriesDisplay)
end function

'-------------------------------------------------------------------------------
' getResponseLibraryItems
'-------------------------------------------------------------------------------
function getResponseLibraryItems(response as dynamic) as object
    if response <> invalid and response.libraryItems <> invalid then return response.libraryItems
    return []
end function

'-------------------------------------------------------------------------------
' sortCollapsedSeriesItems
'-------------------------------------------------------------------------------
function sortCollapsedSeriesItems(items as object) as object
    sortedItems = []
    if items = invalid then return sortedItems

    for each item in items
        sortedItems = insertCollapsedSeriesItem(sortedItems, item)
    end for

    return sortedItems
end function

'-------------------------------------------------------------------------------
' insertCollapsedSeriesItem
'-------------------------------------------------------------------------------
function insertCollapsedSeriesItem(items as object, item as dynamic) as object
    result = []
    inserted = false
    title = getCollapsedSeriesSortTitle(item)

    for each existingItem in items
        if inserted = false then
            existingTitle = getCollapsedSeriesSortTitle(existingItem)
            if String_NaturalCompare(title, existingTitle) < 0 then
                result.Push(item)
                inserted = true
            end if
        end if

        result.Push(existingItem)
    end for

    if inserted = false then result.Push(item)
    return result
end function

'-------------------------------------------------------------------------------
' getCollapsedSeriesSortTitle
'-------------------------------------------------------------------------------
function getCollapsedSeriesSortTitle(item as dynamic) as string
    if item <> invalid and item.collapsedSeries <> invalid then return getCollapsedSeriesTitle(item)
    metadata = getItemMetadata(item)
    return FirstNonEmpty([
        metadata.title
        item.title
        item.name
    ], "")
end function

'-------------------------------------------------------------------------------
' cacheSet
'-------------------------------------------------------------------------------
sub cacheSet(cacheKey as string, value as dynamic)
    if m.cache = invalid then m.cache = []

    for i = 0 to m.cache.Count() - 1
        cacheEntry = m.cache[i]
        if cacheEntry <> invalid and cacheEntry.key = cacheKey then
            cacheEntry.value = value
            logCache()
            return
        end if
    end for

    m.cache.Push({
        key: cacheKey
        value: value
    })
    logCache()
end sub

'-------------------------------------------------------------------------------
' cacheGet
'-------------------------------------------------------------------------------
function cacheGet(cacheKey as string) as dynamic
    if m.cache = invalid then return invalid

    for each cacheEntry in m.cache
        if cacheEntry <> invalid and cacheEntry.key = cacheKey then return cacheEntry.value
    end for

    return invalid
end function

'-------------------------------------------------------------------------------
' cacheHas
'-------------------------------------------------------------------------------
function cacheHas(cacheKey as string) as boolean
    if m.cache = invalid then return false

    for each cacheEntry in m.cache
        if cacheEntry <> invalid and cacheEntry.key = cacheKey then return true
    end for

    return false
end function

'-------------------------------------------------------------------------------
' cacheClear
'-------------------------------------------------------------------------------
sub cacheClear()
    m.cache = []
    logCache()
end sub

'-------------------------------------------------------------------------------
' cacheGetItems
'-------------------------------------------------------------------------------
function cacheGetItems(cacheKey as string) as object
    items = cacheGet(cacheKey)
    if items = invalid then return []
    return items
end function

'-------------------------------------------------------------------------------
' logCache
'-------------------------------------------------------------------------------
sub logCache()

    m.log.write("cache")
    if m.cache = invalid or m.cache.Count() = 0 then
        m.log.write("(empty)")
    else
        for each cacheEntry in m.cache
            if cacheEntry <> invalid then
                itemCount = Array_GetCount(cacheEntry.value)
                bytes = getJsonByteSize(cacheEntry.value)
                m.log.write("..." + SafeString(cacheEntry.key) + " [" + itemCount.ToStr() + " items] [" + formatCacheSize(bytes) + "]")
            end if
        end for
    end if

end sub

'-------------------------------------------------------------------------------
' getCacheInfo
'-------------------------------------------------------------------------------
function getCacheInfo() as object
    cacheInfo = []
    if m.cache = invalid then return cacheInfo

    for each cacheEntry in m.cache
        if cacheEntry <> invalid then
            bytes = getJsonByteSize(cacheEntry.value)
            cacheInfo.Push({
                key: SafeString(cacheEntry.key, "")
                itemCount: Array_GetCount(cacheEntry.value)
                bytes: bytes
                size: formatCacheSize(bytes)
            })
        end if
    end for

    return cacheInfo
end function

'-------------------------------------------------------------------------------
' getJsonByteSize
'-------------------------------------------------------------------------------
function getJsonByteSize(value as dynamic) as integer
    json = FormatJson(value)
    if json = invalid then return 0
    return Len(json)
end function

' formatCacheSize
'-------------------------------------------------------------------------------
function formatCacheSize(bytes as integer) as string
    formattedBytes = FormatWithCommas(bytes)
    if bytes < 1048576 then return formattedBytes + " bytes"

    mb = bytes / 1048576
    return FormatWithCommas(mb) + " MB (" + formattedBytes + " bytes)"
end function

'-------------------------------------------------------------------------------
' getSeriesRowsFromCache
'-------------------------------------------------------------------------------
function getSeriesRowsFromCache() as object
    rows = []
    collapsedSeriesItems = cacheGetItems(m.cacheKeys.collapsedSeries)

    itemLookup = buildLibraryItemLookup()
    for each seriesItem in collapsedSeriesItems
        if seriesItem <> invalid and seriesItem.collapsedSeries <> invalid then
            libraryItems = getSeriesItemsByIdsFromLookup(seriesItem.collapsedSeries.libraryItemIds, itemLookup)
            if libraryItems.Count() > 0 then
                applyFallbackSeriesSequences(libraryItems)
                rows.Push({
                    title: getCollapsedSeriesTitle(seriesItem)
                    seriesId: getCollapsedSeriesId(seriesItem)
                    libraryItems: libraryItems
                })
            end if
        end if
    end for

    return rows
end function

'-------------------------------------------------------------------------------
' getCollapsedSeriesId
'-------------------------------------------------------------------------------
function getCollapsedSeriesId(item as dynamic) as dynamic
    if item = invalid then return invalid
    if item.collapsedSeries = invalid then return invalid
    if item.collapsedSeries.id = invalid then return invalid
    return item.collapsedSeries.id
end function

'-------------------------------------------------------------------------------
' getCollapsedSeriesTitle
'-------------------------------------------------------------------------------
function getCollapsedSeriesTitle(item as dynamic) as string
    if item = invalid or item.collapsedSeries = invalid then return "Series"

    collapsedSeries = item.collapsedSeries
    return FirstNonEmpty([
        collapsedSeries.nameIgnorePrefix
        collapsedSeries.name
        collapsedSeries.title
    ], "Series")
end function

'-------------------------------------------------------------------------------
' getSearchItemsFromCache
'-------------------------------------------------------------------------------
function getSearchItemsFromCache(searchTerm as dynamic) as object
    items = []
    normalizedSearchTerm = LCase(SearchRules_NormalizeTerm(searchTerm))
    if normalizedSearchTerm = "" then return items

    for each item in cacheGetItems(m.cacheKeys.allTitles)
        if isDisplayableLibraryItem(item) and itemMatchesSearch(item, normalizedSearchTerm) then
            items.Push(item)
        end if
    end for

    return items
end function

'-------------------------------------------------------------------------------
' itemMatchesSearch
'-------------------------------------------------------------------------------
function itemMatchesSearch(item as dynamic, normalizedSearchTerm as string) as boolean
    metadata = getItemMetadata(item)
    if textIncludesSearchTerm(metadata.title, normalizedSearchTerm) then return true
    if textIncludesSearchTerm(metadata.authorName, normalizedSearchTerm) then return true

    return false
end function

'-------------------------------------------------------------------------------
' textIncludesSearchTerm
'-------------------------------------------------------------------------------
function textIncludesSearchTerm(value as dynamic, normalizedSearchTerm as string) as boolean
    if normalizedSearchTerm = "" then return false

    text = LCase(SafeString(value, ""))
    return Instr(1, text, normalizedSearchTerm) > 0
end function

'-------------------------------------------------------------------------------
' getSeriesItemsFromCache
'-------------------------------------------------------------------------------
function getSeriesItemsFromCache(seriesId as dynamic, libraryItemIds as dynamic) as object
    items = getSeriesItemsByIds(libraryItemIds)
    if items.Count() > 0 then
        applyFallbackSeriesSequences(items)
        return items
    end if

    items = []
    if seriesId = invalid then return items

    for each item in cacheGetItems(m.cacheKeys.allTitles)
        if isDisplayableLibraryItem(item) and itemMatchesSeries(item, seriesId) then
            items = insertSeriesItem(items, item, getSeriesSequenceSortValue(item, seriesId), seriesId)
        end if
    end for

    applyFallbackSeriesSequences(items)
    return items
end function

'-------------------------------------------------------------------------------
' getSeriesItemsByIds
'-------------------------------------------------------------------------------
function getSeriesItemsByIds(libraryItemIds as dynamic) as object
    return getSeriesItemsByIdsFromLookup(libraryItemIds, buildLibraryItemLookup())
end function

'-------------------------------------------------------------------------------
' getSeriesItemsByIdsFromLookup
'-------------------------------------------------------------------------------
function getSeriesItemsByIdsFromLookup(libraryItemIds as dynamic, itemLookup as object) as object
    items = []
    ids = getLibraryItemIdList(libraryItemIds)
    if ids.Count() = 0 then return items
    if itemLookup = invalid then return items

    for each id in ids
        item = itemLookup[id]
        if isDisplayableLibraryItem(item) then items.Push(item)
    end for

    return items
end function

'-------------------------------------------------------------------------------
' getLibraryItemIdList
'-------------------------------------------------------------------------------
function getLibraryItemIdList(libraryItemIds as dynamic) as object
    ids = []
    if libraryItemIds = invalid then return ids

    idsType = Type(libraryItemIds)
    if idsType = "roArray" then
        for each id in libraryItemIds
            idText = getText(id)
            if idText <> "" then ids.Push(idText)
        end for
    else
        idText = getText(libraryItemIds)
        if idText <> "" then ids.Push(idText)
    end if

    return ids
end function

'-------------------------------------------------------------------------------
' buildLibraryItemLookup
'-------------------------------------------------------------------------------
function buildLibraryItemLookup() as object
    lookup = {}

    for each item in cacheGetItems(m.cacheKeys.allTitles)
        if item <> invalid then
            addLibraryItemLookupCandidate(lookup, item, item.id)
            addLibraryItemLookupCandidate(lookup, item, item.libraryItemId)
            if item.media <> invalid then addLibraryItemLookupCandidate(lookup, item, item.media.libraryItemId)
        end if
    end for

    return lookup
end function

'-------------------------------------------------------------------------------
' addLibraryItemLookupCandidate
'-------------------------------------------------------------------------------
sub addLibraryItemLookupCandidate(lookup as object, item as dynamic, id as dynamic)
    idText = getText(id)
    if idText = "" then return
    if lookup[idText] = invalid then lookup[idText] = item
end sub

'-------------------------------------------------------------------------------
' insertSeriesItem
'-------------------------------------------------------------------------------
function insertSeriesItem(items as object, item as dynamic, sortValue as float, seriesId as dynamic) as object
    result = []
    inserted = false

    if sortValue > 0 then
        for each existingItem in items
            existingSortValue = getSeriesSequenceSortValue(existingItem, seriesId)
            if inserted = false and (existingSortValue <= 0 or sortValue < existingSortValue) then
                result.Push(item)
                inserted = true
            end if
            result.Push(existingItem)
        end for
    end if

    if inserted = false then result.Push(item)
    return result
end function

'-------------------------------------------------------------------------------
' isDisplayableLibraryItem
'-------------------------------------------------------------------------------
function isDisplayableLibraryItem(item as dynamic) as boolean
    if item = invalid then return false
    return item.mediaType = invalid or item.mediaType = "book"
end function

'-------------------------------------------------------------------------------
' itemMatchesSeries
'-------------------------------------------------------------------------------
function itemMatchesSeries(item as dynamic, seriesId as dynamic) as boolean
    seriesIdText = getText(seriesId)
    if seriesIdText = "" then return false

    metadata = getItemMetadata(item)
    if seriesValueMatchesSeries(metadata.series, seriesIdText) then return true
    if seriesValueMatchesSeries(item.series, seriesIdText) then return true
    if item.media <> invalid and seriesValueMatchesSeries(item.media.series, seriesIdText) then return true

    if getText(metadata.seriesId) = seriesIdText then return true
    if getText(item.seriesId) = seriesIdText then return true
    if item.media <> invalid and getText(item.media.seriesId) = seriesIdText then return true
    if item.collapsedSeries <> invalid and getText(item.collapsedSeries.id) = seriesIdText then return true

    return false
end function

'-------------------------------------------------------------------------------
' seriesValueMatchesSeries
'-------------------------------------------------------------------------------
function seriesValueMatchesSeries(series as dynamic, seriesIdText as string) as boolean
    if series = invalid then return false

    seriesType = Type(series)
    if seriesType = "roArray" then
        for each seriesEntry in series
            if seriesEntryMatchesSeries(seriesEntry, seriesIdText) then return true
        end for
    else if seriesType = "roAssociativeArray" then
        return seriesEntryMatchesSeries(series, seriesIdText)
    end if

    return false
end function

'-------------------------------------------------------------------------------
' seriesEntryMatchesSeries
'-------------------------------------------------------------------------------
function seriesEntryMatchesSeries(seriesEntry as dynamic, seriesIdText as string) as boolean
    if seriesEntry = invalid then return false
    if Type(seriesEntry) <> "roAssociativeArray" then return false
    return getText(seriesEntry.id) = seriesIdText
end function

'-------------------------------------------------------------------------------
' applyFallbackSeriesSequences
'-------------------------------------------------------------------------------
sub applyFallbackSeriesSequences(items as object)
    if items = invalid then return

    displayIndex = 1
    for each item in items
        if getSeriesSequence(item, invalid) = "" then
            sequence = displayIndex.ToStr()
            item.seriesSequence = sequence
            if item.media <> invalid and item.media.metadata <> invalid then item.media.metadata.seriesSequence = sequence
        end if
        displayIndex = displayIndex + 1
    end for
end sub

'-------------------------------------------------------------------------------
' getSeriesSequenceSortValue
'-------------------------------------------------------------------------------
function getSeriesSequenceSortValue(item as dynamic, seriesId as dynamic) as float
    sequence = getSeriesSequence(item, seriesId)
    if sequence = "" then return 0
    return val(sequence)
end function

'-------------------------------------------------------------------------------
' getSeriesSequence
'-------------------------------------------------------------------------------
function getSeriesSequence(item as dynamic, seriesId as dynamic) as string
    if item = invalid then return ""

    metadata = getItemMetadata(item)
    if metadata.seriesSequence <> invalid then return metadata.seriesSequence.ToStr()
    if metadata.sequence <> invalid then return metadata.sequence.ToStr()
    if metadata.series <> invalid then
        sequence = getSequenceFromSeriesValue(metadata.series, seriesId)
        if sequence <> "" then return sequence
    end if

    if item.seriesSequence <> invalid then return item.seriesSequence.ToStr()
    if item.sequence <> invalid then return item.sequence.ToStr()

    return ""
end function

'-------------------------------------------------------------------------------
' getSequenceFromSeriesValue
'-------------------------------------------------------------------------------
function getSequenceFromSeriesValue(series as dynamic, seriesId as dynamic) as string
    if series = invalid then return ""

    seriesType = Type(series)
    if seriesType = "roArray" then
        if series.Count() = 0 then return ""

        for each seriesEntry in series
            if seriesId <> invalid and seriesEntryMatchesSeries(seriesEntry, getText(seriesId)) then
                sequence = getSeriesEntrySequence(seriesEntry)
                if sequence <> "" then return sequence
            end if
        end for

        for each seriesEntry in series
            sequence = getSeriesEntrySequence(seriesEntry)
            if sequence <> "" then return sequence
        end for
    else if seriesType = "roAssociativeArray" then
        return getSeriesEntrySequence(series)
    end if

    return ""
end function

'-------------------------------------------------------------------------------
' getSeriesEntrySequence
'-------------------------------------------------------------------------------
function getSeriesEntrySequence(seriesEntry as dynamic) as string
    if seriesEntry = invalid then return ""
    if Type(seriesEntry) <> "roAssociativeArray" then return ""
    if seriesEntry.sequence <> invalid then return seriesEntry.sequence.ToStr()
    if seriesEntry.seriesSequence <> invalid then return seriesEntry.seriesSequence.ToStr()
    return ""
end function

'-------------------------------------------------------------------------------
' getItemMetadata
'-------------------------------------------------------------------------------
function getItemMetadata(item as dynamic) as dynamic
    if item <> invalid and item.media <> invalid and item.media.metadata <> invalid then return item.media.metadata
    return {}
end function

'-------------------------------------------------------------------------------
' getText
'-------------------------------------------------------------------------------
function getText(value as dynamic) as string
    if value = invalid then return ""
    return value.ToStr()
end function
