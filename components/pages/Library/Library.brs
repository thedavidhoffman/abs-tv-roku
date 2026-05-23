'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()

    m.log = CreateLogger("Library", false)
    m.log.write("init")

    m.listView = m.top.findNode("listView")
    m.gridView = m.top.findNode("gridView")
    m.activeView = "list"
    m.syncingLibraryItems = false
    m.loadRequest = invalid
    m.syncedLoadRequestKey = ""
    m.allLibraryItems = []
    m.rootLibraryItems = []
    m.itemBackStack = []
    m.searchResults = []
    m.gridContextTitle = ""
    m.gridContextType = "root"
    m.searchRequestCounter = 0
    m.activeSearchRequestCounter = 0
    m.seriesItemsRequestCounter = 0
    m.itemsReloadedCounter = 0
    m.mainListRestoredCounter = 0
    m.appliedItemDisplay = invalid
    m.appliedGridColumns = invalid

    if m.listView <> invalid then
        m.listView.observeField("libraryItems", "onListViewLibraryItemsChanged")
        m.listView.observeField("playSelected", "onListViewPlaySelected")
        m.listView.observeField("upFromFirstItemSelected", "onListViewUpFromFirstItemSelected")
        m.listView.observeField("errorResponse", "onListViewError")
        m.listView.observeField("seriesItemsRequest", "onListViewSeriesItemsRequest")
        m.listView.observeField("statusMessage", "onListViewStatusMessageChanged")
    end if

    if m.gridView <> invalid then
        m.gridView.observeField("playSelected", "onGridViewPlaySelected")
        m.gridView.observeField("seriesSelected", "onGridViewSeriesSelected")
        m.gridView.observeField("upFromFirstItemSelected", "onGridViewUpFromFirstItemSelected")
        m.gridView.observeField("backFromFirstItemSelected", "onGridViewBackFromFirstItemSelected")
        m.gridView.observeField("errorResponse", "onGridViewError")
        m.gridView.observeField("statusMessage", "onGridViewStatusMessageChanged")
    end if

    applyDisplaySettings(m.top.displaySettings)
end sub

'-------------------------------------------------------------------------------
' onSearchRequestChanged
'-------------------------------------------------------------------------------
sub onSearchRequestChanged()
    request = m.top.searchRequest
    if request = invalid then return

    searchTerm = getText(request.searchTerm)
    m.searchRequestCounter = m.searchRequestCounter + 1
    m.activeSearchRequestCounter = m.searchRequestCounter

    navRequest = {
        action: "searchLibrary"
        searchTerm: searchTerm
        searchRequestCounter: m.activeSearchRequestCounter
    }
    m.top.controllerSearchRequest = navRequest
end sub

'-------------------------------------------------------------------------------
' onLoadRequestChanged
'-------------------------------------------------------------------------------
sub onLoadRequestChanged()

    m.log.write("onLoadRequestChanged")

    m.loadRequest = m.top.loadRequest
    syncLoadRequestToViews()
    onLibraryItemsChanged()
end sub

'-------------------------------------------------------------------------------
' syncLoadRequestToViews
'-------------------------------------------------------------------------------
sub syncLoadRequestToViews()
    loadRequestKey = getLoadRequestKey(m.loadRequest)
    if m.syncedLoadRequestKey = loadRequestKey then return

    m.syncedLoadRequestKey = loadRequestKey
    if m.listView <> invalid then m.listView.loadRequest = m.loadRequest
    if m.gridView <> invalid then m.gridView.loadRequest = m.loadRequest
end sub

'-------------------------------------------------------------------------------
' getLoadRequestKey
'-------------------------------------------------------------------------------
function getLoadRequestKey(request as dynamic) as string
    if request = invalid then return ""

    return getText(request.server) + "|" + getText(request.token) + "|" + getText(request.bookLibraryId)
end function

'-------------------------------------------------------------------------------
' onLoadingChanged
'-------------------------------------------------------------------------------
sub onLoadingChanged()
    syncLoadingToViews()
end sub

'-------------------------------------------------------------------------------
' syncLoadingToViews
'-------------------------------------------------------------------------------
sub syncLoadingToViews()
    if m.listView <> invalid then m.listView.loading = m.top.loading
    if m.gridView <> invalid then m.gridView.loading = m.top.loading
end sub

'-------------------------------------------------------------------------------
' reloadItems
'-------------------------------------------------------------------------------
sub reloadItems()

    m.log.write("reloadItems")

    restoreRootLibraryItems()
end sub

'-------------------------------------------------------------------------------
' onRootLibraryItemsChanged
'-------------------------------------------------------------------------------
sub onRootLibraryItemsChanged()

    m.log.write("onRootLibraryItemsChanged")

    if m.top.rootLibraryItems = invalid then
        m.rootLibraryItems = []
    else
        m.rootLibraryItems = m.top.rootLibraryItems
    end if

    if m.gridContextType = "root" then restoreRootLibraryItems()
end sub

'-------------------------------------------------------------------------------
' onAllLibraryItemsChanged
'-------------------------------------------------------------------------------
sub onAllLibraryItemsChanged()

    m.log.write("onAllLibraryItemsChanged")

    if m.top.allLibraryItems = invalid then
        m.allLibraryItems = []
    else
        m.allLibraryItems = m.top.allLibraryItems
    end if

    if m.gridView <> invalid then m.gridView.allLibraryItems = m.allLibraryItems
end sub

'-------------------------------------------------------------------------------
' restoreRootLibraryItems
'-------------------------------------------------------------------------------
sub restoreRootLibraryItems()
    m.itemBackStack = []
    m.searchResults = []
    m.top.searchResults = m.searchResults
    m.gridContextTitle = ""
    m.gridContextType = "root"
    syncGridContext()
    m.top.libraryItems = m.rootLibraryItems
    publishItemsReloaded()
end sub

'-------------------------------------------------------------------------------
' onSearchResponseChanged
'-------------------------------------------------------------------------------
sub onSearchResponseChanged()

    m.log.write("onSearchResponseChanged")

    response = m.top.searchResponse
    if response = invalid then return

    if response.ok <> true then
        m.top.errorResponse = response
        return
    end if

    storeSearchResults(response)
end sub

'-------------------------------------------------------------------------------
' storeSearchResults
'-------------------------------------------------------------------------------
sub storeSearchResults(response as object)
    if response.searchRequestCounter = invalid then return
    if response.searchRequestCounter <> m.activeSearchRequestCounter then return

    m.itemBackStack = []
    m.searchResults = getResponseLibraryItems(response)
    m.top.searchResults = m.searchResults
    m.gridContextTitle = SearchRules_BuildContextTitle(response.searchTerm)
    m.gridContextType = "search"
    syncGridContext()
    m.top.libraryItems = m.searchResults
end sub

'-------------------------------------------------------------------------------
' storeSeriesItems
'-------------------------------------------------------------------------------
sub storeSeriesItems(response as object)
    if m.top.libraryItems <> invalid then
        m.itemBackStack.Push({
            items: m.top.libraryItems
            focusIndex: response.sourceItemIndex
            contextTitle: m.gridContextTitle
            contextType: m.gridContextType
        })
    end if

    m.gridContextTitle = getText(response.title)
    m.gridContextType = "series"
    syncGridContext()
    m.top.libraryItems = getResponseLibraryItems(response)
end sub

'-------------------------------------------------------------------------------
' getResponseLibraryItems
'-------------------------------------------------------------------------------
function getResponseLibraryItems(response as dynamic) as object
    if response <> invalid and response.libraryItems <> invalid then return response.libraryItems
    return []
end function

'-------------------------------------------------------------------------------
' publishItemsReloaded
'-------------------------------------------------------------------------------
sub publishItemsReloaded()
    m.itemsReloadedCounter = m.itemsReloadedCounter + 1
    m.top.itemsReloaded = m.itemsReloadedCounter
end sub

'-------------------------------------------------------------------------------
' onDisplaySettingsChanged
'-------------------------------------------------------------------------------
sub onDisplaySettingsChanged()
    settings = m.top.displaySettings
    if settings = invalid then return

    applyDisplaySettings(settings)
end sub

'-------------------------------------------------------------------------------
' applyDisplaySettings
'-------------------------------------------------------------------------------
sub applyDisplaySettings(settings as object)
    if settings = invalid then return

    itemDisplay = getItemDisplaySetting(settings)
    gridColumns = getGridColumnsSetting(settings)
    itemDisplayChanged = (m.appliedItemDisplay <> itemDisplay)
    gridColumnsChanged = (m.appliedGridColumns <> gridColumns)

    if itemDisplayChanged = false and gridColumnsChanged = false then return

    if gridColumnsChanged and m.gridView <> invalid then m.gridView.displaySettings = settings

    if itemDisplayChanged then
        if itemDisplay = "grid" then
            updateActiveView("grid")
        else
            updateActiveView("list")
        end if
    end if

    m.appliedItemDisplay = itemDisplay
    m.appliedGridColumns = gridColumns
end sub

'-------------------------------------------------------------------------------
' getItemDisplaySetting
'-------------------------------------------------------------------------------
function getItemDisplaySetting(settings as object) as string
    keys = SettingsStore_Keys()
    return SettingsStore_GetSettingValue(settings, keys.itemDisplay)
end function

'-------------------------------------------------------------------------------
' getGridColumnsSetting
'-------------------------------------------------------------------------------
function getGridColumnsSetting(settings as object) as string
    keys = SettingsStore_Keys()
    return SettingsStore_GetSettingValue(settings, keys.gridColumns)
end function

'-------------------------------------------------------------------------------
' updateActiveView
'-------------------------------------------------------------------------------
sub updateActiveView(viewName as string)
    m.activeView = viewName
    if m.listView <> invalid then m.listView.visible = (viewName = "list")
    if m.gridView <> invalid then m.gridView.visible = (viewName = "grid")
    syncGridContext()
    syncStatusMessage()
end sub

'-------------------------------------------------------------------------------
' onListViewLibraryItemsChanged
'-------------------------------------------------------------------------------
sub onListViewLibraryItemsChanged()
    if m.syncingLibraryItems = true then return
    if m.listView <> invalid then m.top.libraryItems = m.listView.libraryItems
end sub

'-------------------------------------------------------------------------------
' onLibraryItemsChanged
'-------------------------------------------------------------------------------
sub onLibraryItemsChanged()
    if m.syncingLibraryItems = true then return

    m.syncingLibraryItems = true
    items = m.top.libraryItems

    syncLoadRequestToViews()
    if m.listView <> invalid then m.listView.libraryItems = items
    if m.gridView <> invalid then
        m.gridView.libraryItems = items
    end if
    syncLoadingToViews()

    m.syncingLibraryItems = false
    focusLibraryList()
end sub

'-------------------------------------------------------------------------------
' onListViewPlaySelected
'-------------------------------------------------------------------------------
sub onListViewPlaySelected()
    if m.listView <> invalid then m.top.playSelected = m.listView.playSelected
end sub

'-------------------------------------------------------------------------------
' onGridViewPlaySelected
'-------------------------------------------------------------------------------
sub onGridViewPlaySelected()
    if m.gridView <> invalid then m.top.playSelected = m.gridView.playSelected
end sub

'-------------------------------------------------------------------------------
' onGridViewSeriesSelected
'-------------------------------------------------------------------------------
sub onGridViewSeriesSelected()
    if m.gridView = invalid then return

    selectedSeries = m.gridView.seriesSelected
    if selectedSeries = invalid or selectedSeries.seriesId = invalid then return

    requestSeriesItems({
        sourceView: "grid"
        action: "loadSeries"
        seriesId: selectedSeries.seriesId
        libraryItemIds: selectedSeries.libraryItemIds
        sourceItemIndex: selectedSeries.itemIndex
        title: selectedSeries.title
    })
end sub

'-------------------------------------------------------------------------------
' onListViewSeriesItemsRequest
'-------------------------------------------------------------------------------
sub onListViewSeriesItemsRequest()
    if m.listView = invalid then return

    request = m.listView.seriesItemsRequest
    if request = invalid then return

    requestSeriesItems(request)
end sub

'-------------------------------------------------------------------------------
' requestSeriesItems
'-------------------------------------------------------------------------------
sub requestSeriesItems(request as object)
    if request = invalid then return

    m.seriesItemsRequestCounter = m.seriesItemsRequestCounter + 1
    request.counter = m.seriesItemsRequestCounter
    m.top.seriesItemsRequest = request
end sub

'-------------------------------------------------------------------------------
' onSeriesItemsResponseChanged
'-------------------------------------------------------------------------------
sub onSeriesItemsResponseChanged()
    response = m.top.seriesItemsResponse
    if response = invalid then return

    if response.ok <> true then
        m.top.errorResponse = response
        return
    end if

    if response.sourceView = "list" then
        if m.listView <> invalid then m.listView.seriesItemsResponse = response
        return
    end if

    storeSeriesItems(response)
end sub

'-------------------------------------------------------------------------------
' onGridViewUpFromFirstItemSelected
'-------------------------------------------------------------------------------
sub onGridViewUpFromFirstItemSelected()
    if m.gridView <> invalid then m.top.upFromFirstItemSelected = m.gridView.upFromFirstItemSelected
end sub

'-------------------------------------------------------------------------------
' onMediaProgressChanged
'-------------------------------------------------------------------------------
sub onMediaProgressChanged()
    if m.listView <> invalid then m.listView.mediaProgress = m.top.mediaProgress
    if m.gridView <> invalid then m.gridView.mediaProgress = m.top.mediaProgress
end sub

'-------------------------------------------------------------------------------
' onGridViewBackFromFirstItemSelected
'-------------------------------------------------------------------------------
sub onGridViewBackFromFirstItemSelected()
    if handleBackNavigation() then return
    if m.gridView <> invalid then m.top.backFromFirstItemSelected = m.gridView.backFromFirstItemSelected
end sub

'-------------------------------------------------------------------------------
' onListViewUpFromFirstItemSelected
'-------------------------------------------------------------------------------
sub onListViewUpFromFirstItemSelected()
    if m.listView <> invalid then m.top.upFromFirstItemSelected = m.listView.upFromFirstItemSelected
end sub

'-------------------------------------------------------------------------------
' onListViewError
'-------------------------------------------------------------------------------
sub onListViewError()
    if m.listView <> invalid then m.top.errorResponse = m.listView.errorResponse
end sub

'-------------------------------------------------------------------------------
' onListViewStatusMessageChanged
'-------------------------------------------------------------------------------
sub onListViewStatusMessageChanged()
    syncStatusMessage()
end sub

'-------------------------------------------------------------------------------
' onGridViewError
'-------------------------------------------------------------------------------
sub onGridViewError()
    if m.gridView <> invalid then m.top.errorResponse = m.gridView.errorResponse
end sub

'-------------------------------------------------------------------------------
' onGridViewStatusMessageChanged
'-------------------------------------------------------------------------------
sub onGridViewStatusMessageChanged()
    syncStatusMessage()
end sub

'-------------------------------------------------------------------------------
' syncStatusMessage
'-------------------------------------------------------------------------------
sub syncStatusMessage()
    m.top.statusMessage = getActiveViewStatusMessage()
end sub

'-------------------------------------------------------------------------------
' getActiveViewStatusMessage
'-------------------------------------------------------------------------------
function getActiveViewStatusMessage() as string
    if m.activeView = "grid" and m.gridView <> invalid then return getText(m.gridView.statusMessage)
    if m.activeView = "list" and m.listView <> invalid then return getText(m.listView.statusMessage)
    return ""
end function

'-------------------------------------------------------------------------------
' hasStatusMessage
'-------------------------------------------------------------------------------
function hasStatusMessage() as boolean
    return getText(m.top.statusMessage) <> ""
end function

'-------------------------------------------------------------------------------
' focusLibraryList
'-------------------------------------------------------------------------------
sub focusLibraryList()
    if hasStatusMessage() then
        m.top.setFocus(true)
        return
    end if

    if m.activeView = "grid" then
        if m.gridView <> invalid then m.gridView.callFunc("focusLibraryList")
        return
    end if

    if m.listView <> invalid then m.listView.callFunc("focusLibraryList")
end sub

'-------------------------------------------------------------------------------
' focusItemAtIndex
'-------------------------------------------------------------------------------
sub focusItemAtIndex(index as dynamic)
    if m.activeView = "grid" and m.gridView <> invalid then
        m.gridView.callFunc("focusItemAtIndex", index)
        return
    end if

    focusLibraryList()
end sub

'-------------------------------------------------------------------------------
' handleBackNavigation
'-------------------------------------------------------------------------------
function handleBackNavigation() as boolean
    if m.top.visible <> true then return false

    if isShowingSearchResults() then
        return false
    end if

    if hasBackStack() then
        if m.activeView = "list" then return false
        if moveFocusToFirstGridItem() then return true
        if restorePreviousItems() then return true
    end if

    if moveFocusToFirstGridItem() then return true
    return false
end function

'-------------------------------------------------------------------------------
' resetDrilldown
'-------------------------------------------------------------------------------
sub resetDrilldown()
    if hasBackStack() = false then return

    rootState = m.itemBackStack[0]
    m.itemBackStack = []

    if rootState <> invalid and rootState.items <> invalid then
        m.gridContextTitle = ""
        m.gridContextType = "root"
        syncGridContext()
        m.top.libraryItems = rootState.items
    end if
end sub

'-------------------------------------------------------------------------------
' resetNavigationState
'-------------------------------------------------------------------------------
sub resetNavigationState()
    m.activeSearchRequestCounter = m.activeSearchRequestCounter + 1
    m.itemBackStack = []
    m.searchResults = []
    m.top.searchResults = m.searchResults
    m.gridContextTitle = ""
    m.gridContextType = "root"
    syncGridContext()
    m.top.libraryItems = []
end sub

'-------------------------------------------------------------------------------
' resetSearchResults
'-------------------------------------------------------------------------------
function resetSearchResults() as boolean
    if hasSearchContext() = false then return false

    clearSearchResults(false)
    reloadItems()
    return true
end function

'-------------------------------------------------------------------------------
' restorePreviousItems
'-------------------------------------------------------------------------------
function restorePreviousItems() as boolean
    if hasBackStack() = false then return false

    lastIndex = m.itemBackStack.Count() - 1
    previousState = m.itemBackStack[lastIndex]
    m.itemBackStack.Delete(lastIndex)

    m.top.libraryItems = previousState.items
    m.gridContextTitle = getText(previousState.contextTitle)
    m.gridContextType = getText(previousState.contextType)
    if m.gridContextType = "" then m.gridContextType = "root"
    syncGridContext()
    focusItemAtIndex(previousState.focusIndex)
    return true
end function

'-------------------------------------------------------------------------------
' syncGridContext
'-------------------------------------------------------------------------------
sub syncGridContext()
    if m.listView <> invalid then
        m.listView.contextTitle = m.gridContextTitle
        m.listView.contextType = m.gridContextType
    end if

    if m.gridView = invalid then return

    m.gridView.contextTitle = m.gridContextTitle
    m.gridView.contextType = m.gridContextType
end sub

'-------------------------------------------------------------------------------
' getText
'-------------------------------------------------------------------------------
function getText(value as dynamic) as string
    if value = invalid then return ""
    return value.ToStr()
end function

'-------------------------------------------------------------------------------
' hasBackStack
'-------------------------------------------------------------------------------
function hasBackStack() as boolean
    return m.itemBackStack <> invalid and m.itemBackStack.Count() > 0
end function

'-------------------------------------------------------------------------------
' moveFocusToFirstGridItem
'-------------------------------------------------------------------------------
function moveFocusToFirstGridItem() as boolean
    if m.activeView <> "grid" then return false
    if m.gridView = invalid then return false

    handled = m.gridView.callFunc("moveFocusToFirstItem")
    return handled = true
end function

'-------------------------------------------------------------------------------
' isShowingSearchResults
'-------------------------------------------------------------------------------
function isShowingSearchResults() as boolean
    return m.gridContextType = "search"
end function

'-------------------------------------------------------------------------------
' hasSearchContext
'-------------------------------------------------------------------------------
function hasSearchContext() as boolean
    if m.gridContextType = "search" then return true
    if m.itemBackStack = invalid then return false

    for each state in m.itemBackStack
        if state <> invalid and state.contextType = "search" then return true
    end for

    return false
end function

'-------------------------------------------------------------------------------
' restoreRootItemsFromSearch
'-------------------------------------------------------------------------------
sub restoreRootItemsFromSearch()
    clearSearchResults(true)
    reloadItems()
end sub

'-------------------------------------------------------------------------------
' clearSearchResults
'-------------------------------------------------------------------------------
sub clearSearchResults(shouldPublishMainListRestored as boolean)
    resetNavigationState()
    if shouldPublishMainListRestored then publishMainListRestored()
end sub

'-------------------------------------------------------------------------------
' publishMainListRestored
'-------------------------------------------------------------------------------
sub publishMainListRestored()
    m.mainListRestoredCounter = m.mainListRestoredCounter + 1
    m.top.mainListRestored = m.mainListRestoredCounter
end sub
