'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.allItemsTask = m.top.findNode("allItemsTask")
    m.collapsedItemsTask = m.top.findNode("collapsedItemsTask")
    m.loadRequest = invalid
    m.displaySettings = SettingsStore_Load()
    m.allTitleItems = []
    m.collapsedSeriesItems = []
    m.hasAllTitleItems = false
    m.hasCollapsedSeriesItems = false
    m.requestGeneration = 0
    m.libraryItemsChangedCounter = 0

    if m.allItemsTask <> invalid then m.allItemsTask.observeField("response", "onAllItemsResponse")
    if m.collapsedItemsTask <> invalid then m.collapsedItemsTask.observeField("response", "onCollapsedItemsResponse")

    m.top.libraryItems = []
    m.top.loading = false
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

    m.displaySettings = settings
    publishCurrentLibraryItems()
end sub

'-------------------------------------------------------------------------------
' reloadActiveLibrary
'-------------------------------------------------------------------------------
function reloadActiveLibrary() as boolean
    if hasValidLoadRequest() = false then return false

    beginNewCacheGeneration()
    m.top.loading = true

    runLibraryItemsRequest(m.allItemsTask, "allTitles", false)
    runLibraryItemsRequest(m.collapsedItemsTask, "collapsedSeries", true)
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
    m.requestGeneration = m.requestGeneration + 1
    m.allTitleItems = []
    m.collapsedSeriesItems = []
    m.hasAllTitleItems = false
    m.hasCollapsedSeriesItems = false
    m.top.errorResponse = invalid
    publishItems([])
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
    if response.requestGeneration <> m.requestGeneration then return

    if response.ok <> true then
        m.top.loading = false
        m.top.errorResponse = response
        return
    end if

    if response.cacheKey = "collapsedSeries" then
        m.collapsedSeriesItems = getResponseLibraryItems(response)
        m.hasCollapsedSeriesItems = true
    else if response.cacheKey = "allTitles" then
        m.allTitleItems = getResponseLibraryItems(response)
        m.hasAllTitleItems = true
    end if

    publishCurrentLibraryItems()
    m.top.loading = (m.hasAllTitleItems = false or m.hasCollapsedSeriesItems = false)
end sub

'-------------------------------------------------------------------------------
' publishCurrentLibraryItems
'-------------------------------------------------------------------------------
sub publishCurrentLibraryItems()
    if shouldUseCollapsedSeriesItems() then
        publishItems(m.collapsedSeriesItems)
    else
        publishItems(m.allTitleItems)
    end if
end sub

'-------------------------------------------------------------------------------
' publishItems
'-------------------------------------------------------------------------------
sub publishItems(items as object)
    if items = invalid then items = []

    m.top.libraryItems = items
    m.libraryItemsChangedCounter = m.libraryItemsChangedCounter + 1
    m.top.libraryItemsChanged = m.libraryItemsChangedCounter
end sub

'-------------------------------------------------------------------------------
' shouldUseCollapsedSeriesItems
'-------------------------------------------------------------------------------
function shouldUseCollapsedSeriesItems() as boolean
    settings = m.displaySettings
    if settings = invalid then return true

    if settings["series-display"] <> invalid then return settings["series-display"] = "collapse"
    if settings.seriesDisplay <> invalid then return settings.seriesDisplay = "collapse"

    return true
end function

'-------------------------------------------------------------------------------
' getResponseLibraryItems
'-------------------------------------------------------------------------------
function getResponseLibraryItems(response as dynamic) as object
    if response <> invalid and response.libraryItems <> invalid then return response.libraryItems
    return []
end function
