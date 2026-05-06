'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.listView = m.top.findNode("listView")
    m.gridView = m.top.findNode("gridView")
    m.libraryApiTask = m.top.findNode("libraryApiTask")
    m.activeView = "list"
    m.syncingLibraryItems = false
    m.loadRequest = invalid
    m.itemBackStack = []
    m.itemsReloadedCounter = 0

    if m.listView <> invalid then
        m.listView.observeField("libraryItems", "onListViewLibraryItemsChanged")
        m.listView.observeField("playSelected", "onListViewPlaySelected")
        m.listView.observeField("upFromFirstItemSelected", "onListViewUpFromFirstItemSelected")
        m.listView.observeField("errorResponse", "onListViewError")
    end if

    if m.gridView <> invalid then
        m.gridView.observeField("playSelected", "onGridViewPlaySelected")
        m.gridView.observeField("seriesSelected", "onGridViewSeriesSelected")
        m.gridView.observeField("upFromFirstItemSelected", "onGridViewUpFromFirstItemSelected")
        m.gridView.observeField("backFromFirstItemSelected", "onGridViewBackFromFirstItemSelected")
        m.gridView.observeField("errorResponse", "onGridViewError")
    end if

    if m.libraryApiTask <> invalid then
        m.libraryApiTask.observeField("response", "onLibraryApiResponse")
    end if

    applyDisplaySettings(SettingsStore_Load())
end sub

'-------------------------------------------------------------------------------
' onLoadRequestChanged
'-------------------------------------------------------------------------------
sub onLoadRequestChanged()
    m.loadRequest = m.top.loadRequest
    syncLoadRequestToViews()
    reloadItems()
end sub

'-------------------------------------------------------------------------------
' syncLoadRequestToViews
'-------------------------------------------------------------------------------
sub syncLoadRequestToViews()
    if m.listView <> invalid then m.listView.loadRequest = m.loadRequest
    if m.gridView <> invalid then m.gridView.loadRequest = m.loadRequest
end sub

'-------------------------------------------------------------------------------
' reloadItems
'-------------------------------------------------------------------------------
sub reloadItems()
    if hasValidLoadRequest() = false then return

    runLibraryApiRequest({
        action: "loadLibrary"
        server: m.loadRequest.server
        token: m.loadRequest.token
        bookLibraryId: m.loadRequest.bookLibraryId
    })
end sub

'-------------------------------------------------------------------------------
' hasValidLoadRequest
'-------------------------------------------------------------------------------
function hasValidLoadRequest() as boolean
    if m.loadRequest = invalid then return false
    if m.loadRequest.server = invalid or m.loadRequest.server = "" then return false
    if m.loadRequest.token = invalid or m.loadRequest.token = "" then return false
    if m.libraryApiTask = invalid then return false

    return true
end function

'-------------------------------------------------------------------------------
' runLibraryApiRequest
'-------------------------------------------------------------------------------
sub runLibraryApiRequest(request as object)
    if m.libraryApiTask = invalid then return

    m.libraryApiTask.request = request
    m.libraryApiTask.control = "run"
end sub

'-------------------------------------------------------------------------------
' onLibraryApiResponse
'-------------------------------------------------------------------------------
sub onLibraryApiResponse()
    response = m.libraryApiTask.response
    if response = invalid then return

    if response.ok <> true then
        m.top.errorResponse = response
    else if response.action = "loadSeries" then
        storeSeriesItems(response)
    else
        storeRootItems(response)
    end if
end sub

'-------------------------------------------------------------------------------
' storeRootItems
'-------------------------------------------------------------------------------
sub storeRootItems(response as object)
    m.itemBackStack = []
    m.top.libraryItems = getResponseLibraryItems(response)
    publishItemsReloaded()
end sub

'-------------------------------------------------------------------------------
' storeSeriesItems
'-------------------------------------------------------------------------------
sub storeSeriesItems(response as object)
    if m.top.libraryItems <> invalid then
        m.itemBackStack.Push({
            items: m.top.libraryItems
            focusIndex: response.sourceItemIndex
        })
    end if

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
    if itemDisplay = "grid" then
        updateActiveView("grid")
    else
        updateActiveView("list")
    end if
end sub

'-------------------------------------------------------------------------------
' getItemDisplaySetting
'-------------------------------------------------------------------------------
function getItemDisplaySetting(settings as object) as string
    if settings["item-display"] <> invalid then return settings["item-display"]
    if settings.itemDisplay <> invalid then return settings.itemDisplay
    return "list"
end function

'-------------------------------------------------------------------------------
' updateActiveView
'-------------------------------------------------------------------------------
sub updateActiveView(viewName as string)
    m.activeView = viewName
    if m.listView <> invalid then m.listView.visible = (viewName = "list")
    if m.gridView <> invalid then m.gridView.visible = (viewName = "grid")
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

    if m.listView <> invalid then m.listView.libraryItems = items
    if m.gridView <> invalid then m.gridView.libraryItems = items

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
    if hasValidLoadRequest() = false then return

    runLibraryApiRequest({
        action: "loadSeries"
        server: m.loadRequest.server
        token: m.loadRequest.token
        bookLibraryId: m.loadRequest.bookLibraryId
        seriesId: selectedSeries.seriesId
        sourceItemIndex: selectedSeries.itemIndex
    })
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
' onGridViewError
'-------------------------------------------------------------------------------
sub onGridViewError()
    if m.gridView <> invalid then m.top.errorResponse = m.gridView.errorResponse
end sub

'-------------------------------------------------------------------------------
' focusLibraryList
'-------------------------------------------------------------------------------
sub focusLibraryList()
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

    if hasBackStack() then
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
        m.top.libraryItems = rootState.items
    end if
end sub

'-------------------------------------------------------------------------------
' restorePreviousItems
'-------------------------------------------------------------------------------
function restorePreviousItems() as boolean
    if hasBackStack() = false then return false

    lastIndex = m.itemBackStack.Count() - 1
    previousState = m.itemBackStack[lastIndex]
    m.itemBackStack.Delete(lastIndex)

    m.top.libraryItems = previousState.items
    focusItemAtIndex(previousState.focusIndex)
    return true
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
