'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.listView = m.top.findNode("listView")
    m.gridView = m.top.findNode("gridView")
    m.collapsedGridView = m.top.findNode("collapsedGridView")
    m.activeView = "list"
    m.syncingLibraryItems = false

    if m.listView <> invalid then
        m.listView.observeField("libraryItems", "onListViewLibraryItemsChanged")
        m.listView.observeField("playSelected", "onListViewPlaySelected")
        m.listView.observeField("errorResponse", "onListViewError")
    end if

    if m.gridView <> invalid then
        m.gridView.observeField("playSelected", "onGridViewPlaySelected")
        m.gridView.observeField("errorResponse", "onGridViewError")
    end if

    if m.collapsedGridView <> invalid then
        m.collapsedGridView.observeField("playSelected", "onCollapsedGridViewPlaySelected")
        m.collapsedGridView.observeField("errorResponse", "onCollapsedGridViewError")
    end if

    applyDisplaySettings(SettingsStore_Load())
end sub

'-------------------------------------------------------------------------------
' onLoadRequestChanged
'-------------------------------------------------------------------------------
sub onLoadRequestChanged()
    if m.listView <> invalid then m.listView.loadRequest = m.top.loadRequest
    if m.gridView <> invalid then m.gridView.loadRequest = m.top.loadRequest
    if m.collapsedGridView <> invalid then m.collapsedGridView.loadRequest = m.top.loadRequest
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
        seriesDisplay = getSeriesDisplaySetting(settings)
        if seriesDisplay = "collapse" then
            updateActiveView("grid-collapsed")
        else
            updateActiveView("grid-expanded")
        end if
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
' getSeriesDisplaySetting
'-------------------------------------------------------------------------------
function getSeriesDisplaySetting(settings as object) as string
    if settings["series-display"] <> invalid then return settings["series-display"]
    if settings.seriesDisplay <> invalid then return settings.seriesDisplay
    return "collapse"
end function

'-------------------------------------------------------------------------------
' updateActiveView
'-------------------------------------------------------------------------------
sub updateActiveView(viewName as string)
    m.activeView = viewName
    if m.listView <> invalid then m.listView.visible = (viewName = "list")
    if m.gridView <> invalid then m.gridView.visible = (viewName = "grid-expanded")
    if m.collapsedGridView <> invalid then m.collapsedGridView.visible = (viewName = "grid-collapsed")
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
    if m.collapsedGridView <> invalid then m.collapsedGridView.libraryItems = items

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
' onCollapsedGridViewPlaySelected
'-------------------------------------------------------------------------------
sub onCollapsedGridViewPlaySelected()
    if m.collapsedGridView <> invalid then m.top.playSelected = m.collapsedGridView.playSelected
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
' onCollapsedGridViewError
'-------------------------------------------------------------------------------
sub onCollapsedGridViewError()
    if m.collapsedGridView <> invalid then m.top.errorResponse = m.collapsedGridView.errorResponse
end sub

'-------------------------------------------------------------------------------
' focusLibraryList
'-------------------------------------------------------------------------------
sub focusLibraryList()
    if m.activeView = "grid-expanded" then
        if m.gridView <> invalid then m.gridView.callFunc("focusLibraryList")
        return
    end if

    if m.activeView = "grid-collapsed" then
        if m.collapsedGridView <> invalid then m.collapsedGridView.callFunc("focusLibraryList")
        return
    end if

    if m.listView <> invalid then m.listView.callFunc("focusLibraryList")
end sub
