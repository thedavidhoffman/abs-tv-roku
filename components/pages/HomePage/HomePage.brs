'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()

    m.log = CreateLogger("HomePage", false)
    m.log.write("init")

    initReferences()
    initValues()
    initHandlers()
    applyGridLayout(m.top.displaySettings)
end sub

'-------------------------------------------------------------------------------
' initReferences
'-------------------------------------------------------------------------------
sub initReferences()
    m.homeRowList = m.top.findNode("homeRowList")
    m.focusRetryTimer = m.top.findNode("focusRetryTimer")
    m.personalizedApiTask = m.top.findNode("personalizedApiTask")
end sub

'-------------------------------------------------------------------------------
' initValues
'-------------------------------------------------------------------------------
sub initValues()
    m.shelfState = {
        itemsByRow: []
        focusedItemNode: invalid
    }
    m.focusState = {
        firstItemPending: false
        retryCount: 0
        retryMax: 12
    }
    m.loadRequest = invalid
    m.isLoading = false
    m.layoutState = {
        posterWidth: 280
        appliedGridColumns: invalid
    }
end sub

'-------------------------------------------------------------------------------
' initHandlers
'-------------------------------------------------------------------------------
sub initHandlers()
    m.homeRowList.observeField("itemSelected", "onItemSelected")
    m.homeRowList.observeField("rowItemFocused", "onRowItemFocused")
    m.personalizedApiTask.observeField("response", "onPersonalizedApiResponse")
    m.focusRetryTimer.observeField("fire", "onFocusRetryTimerFired")
end sub

'-------------------------------------------------------------------------------
' onDisplaySettingsChanged
'-------------------------------------------------------------------------------
sub onDisplaySettingsChanged()
    gridColumns = getGridColumnsSetting(m.top.displaySettings)
    if m.layoutState.appliedGridColumns = gridColumns then return

    applyGridLayout(m.top.displaySettings)
    renderPersonalizedShelves()
end sub

'-------------------------------------------------------------------------------
' applyGridLayout
'-------------------------------------------------------------------------------
sub applyGridLayout(settings as dynamic)
    if m.homeRowList = invalid then return

    columnCount = GridLayout_GetColumnCount(settings)
    posterWidth = GridLayout_GetPosterWidth(columnCount)
    itemHeight = GridLayout_GetItemHeight(posterWidth)
    rowHeight = GridLayout_GetRowHeight(itemHeight)
    gutter = GridLayout_GetHorizontalGutter()

    m.layoutState.posterWidth = posterWidth
    m.layoutState.appliedGridColumns = getGridColumnsSetting(settings)
    m.homeRowList.itemSize = [1792, rowHeight]
    m.homeRowList.rowItemSize = [[posterWidth, itemHeight], [posterWidth, itemHeight], [posterWidth, itemHeight]]
    m.homeRowList.rowItemSpacing = [[gutter, 0], [gutter, 0], [gutter, 0]]
end sub

'-------------------------------------------------------------------------------
' getGridColumnsSetting
'-------------------------------------------------------------------------------
function getGridColumnsSetting(settings as dynamic) as string
    keys = SettingsStore_Keys()
    return SettingsStore_GetSettingValue(settings, keys.gridColumns)
end function

'-------------------------------------------------------------------------------
' onLoadRequestChanged
'-------------------------------------------------------------------------------
sub onLoadRequestChanged()

    m.log.write("onLoadRequestChanged")

    m.loadRequest = m.top.loadRequest

    if m.loadRequest = invalid then THROW("[HomePage.onLoadRequestChanged()] loadRequest is invalid.")
    if m.loadRequest.server = invalid then THROW("[HomePage.onLoadRequestChanged()] loadRequest.server is invalid.")
    if m.loadRequest.token = invalid then THROW("[HomePage.onLoadRequestChanged()] loadRequest.token is invalid.")
    if m.loadRequest.bookLibraryId = invalid then THROW("[HomePage.onLoadRequestChanged()] loadRequest.bookLibraryId is invalid.")

    renderPersonalizedShelves()
    loadPersonalizedShelves()
end sub

'-------------------------------------------------------------------------------
' loadPersonalizedShelves
'-------------------------------------------------------------------------------
sub loadPersonalizedShelves()

    m.log.write("loadPersonalizedShelves")

    if m.top.visible = true then m.focusState.firstItemPending = true
    m.isLoading = true
    setStatus("Loading...")
    
    runPersonalizedApiRequest({
        action: "loadPersonalized"
        server: m.loadRequest.server
        token: m.loadRequest.token
        bookLibraryId: m.loadRequest.bookLibraryId
    })
end sub

'-------------------------------------------------------------------------------
' runPersonalizedApiRequest
'-------------------------------------------------------------------------------
sub runPersonalizedApiRequest(request as object)

    m.log.write("runPersonalizedApiRequest")

    if m.personalizedApiTask = invalid then return

    m.personalizedApiTask.request = request
    m.personalizedApiTask.control = "run"
end sub

'-------------------------------------------------------------------------------
' onPersonalizedApiResponse
'-------------------------------------------------------------------------------
sub onPersonalizedApiResponse()

    m.log.write("onPersonalizedApiResponse")

    response = m.personalizedApiTask.response
    if response = invalid then return

    m.isLoading = false

    if response.ok <> true then
        setStatus(SafeString(response.errorMessage, "Unable to load home shelves."))
        m.top.errorResponse = response
        return
    end if

    if response.bookLibraryId <> invalid and response.bookLibraryId <> "" and m.loadRequest <> invalid then
        m.loadRequest.bookLibraryId = response.bookLibraryId
    end if

    m.top.personalizedShelves = response.shelves
end sub

'-------------------------------------------------------------------------------
' onPersonalizedShelvesChanged
'-------------------------------------------------------------------------------
sub onPersonalizedShelvesChanged()

    m.log.write("onPersonalizedShelvesChanged")

    renderPersonalizedShelves()
end sub

'-------------------------------------------------------------------------------
' onMediaProgressChanged
'-------------------------------------------------------------------------------
sub onMediaProgressChanged()

    m.log.write("onMediaProgressChanged")

    if hasPersonalizedShelves() = false then return
    renderPersonalizedShelves()
end sub

'-------------------------------------------------------------------------------
' renderPersonalizedShelves
'-------------------------------------------------------------------------------
sub renderPersonalizedShelves()

    m.log.write("renderPersonalizedShelves")

    if m.homeRowList = invalid then return

    root = CreateObject("roSGNode", "ContentNode")
    m.shelfState.itemsByRow = []
    m.shelfState.focusedItemNode = invalid

    appendShelfRow(root, "continue-listening", "Continue Listening")
    appendShelfRow(root, "recently-added", "Recently Added")
    appendShelfRow(root, "listen-again", "Listen Again")

    m.homeRowList.content = root
    updateStatus(root.getChildCount())

    if m.focusState.firstItemPending = true and m.top.visible = true then
        if root.getChildCount() > 0 then
            requestFirstHomeItemFocus()
        else
            m.top.setFocus(true)
            finishFirstHomeItemFocus()
        end if
    end if
end sub

'-------------------------------------------------------------------------------
' hasPersonalizedShelves
'-------------------------------------------------------------------------------
function hasPersonalizedShelves() as boolean
    shelves = m.top.personalizedShelves
    if shelves = invalid then return false
    return shelves.Count() > 0
end function

'-------------------------------------------------------------------------------
' appendShelfRow
'-------------------------------------------------------------------------------
sub appendShelfRow(root as object, shelfId as string, title as string)
    shelf = getShelfById(m.top.personalizedShelves, shelfId)
    items = invalid
    if shelf <> invalid then items = shelf.entities
    if items = invalid then return

    row = CreateObject("roSGNode", "ContentNode")
    row.title = title
    itemsByIndex = []

    for each item in items
        if item <> invalid and item.id <> invalid then
            node = CreateObject("roSGNode", "ContentNode")
            node.title = getLibraryItemTitle(item)
            node.HDPosterUrl = Cover_BuildUrl(m.loadRequest.server, m.loadRequest.token, item.id, m.layoutState.posterWidth)
            node.SDPosterUrl = node.HDPosterUrl
            progress = ProgressData_GetItemProgress(item, m.top.mediaProgress)
            metadata = ItemMetadataParser_GetMetadata(item)
            node.AddFields({
                author: ItemMetadataParser_GetAuthor(metadata)
                posterWidth: m.layoutState.posterWidth
                useLargeText: GridLayout_ShouldUseLargePosterText(m.layoutState.appliedGridColumns)
                progressPercent: progress.progress
                progressCurrentTime: progress.currentTime
                progressDuration: progress.duration
                progressIsFinished: progress.isFinished
                focused: false
            })
            row.appendChild(node)
            itemsByIndex.Push(item)
        end if
    end for

    if row.getChildCount() = 0 then return

    root.appendChild(row)
    m.shelfState.itemsByRow.Push(itemsByIndex)
end sub

'-------------------------------------------------------------------------------
' getShelfById
'-------------------------------------------------------------------------------
function getShelfById(shelves as dynamic, shelfId as string) as dynamic
    if shelves = invalid then return invalid

    for each shelf in shelves
        if shelf <> invalid and shelf.id = shelfId then return shelf
    end for

    return invalid
end function

'-------------------------------------------------------------------------------
' updateStatus
'-------------------------------------------------------------------------------
sub updateStatus(rowCount as integer)
    if m.homeRowList = invalid then return

    hasItems = rowCount > 0
    m.homeRowList.visible = hasItems

    if hasItems then
        m.top.statusMessage = ""
    else if m.isLoading = true then
        m.top.statusMessage = "Loading..."
    else
        m.top.statusMessage = "No titles found"
    end if
end sub

'-------------------------------------------------------------------------------
' setStatus
'-------------------------------------------------------------------------------
sub setStatus(message as dynamic)
    if m.homeRowList = invalid then return

    text = SafeString(message, "")
    m.top.statusMessage = text
    m.homeRowList.visible = (text = "")

    if text <> "" and m.focusState.firstItemPending = true and m.top.visible = true then focusHomeStatus()
end sub

'-------------------------------------------------------------------------------
' focusHomePage
'-------------------------------------------------------------------------------
function focusHomePage() as boolean
    m.focusState.firstItemPending = true

    if m.homeRowList <> invalid and m.homeRowList.visible = true then
        requestFirstHomeItemFocus()
        return true
    end if

    focusHomeStatus()
    return true
end function

'-------------------------------------------------------------------------------
' focusHomeStatus
'-------------------------------------------------------------------------------
sub focusHomeStatus()
    m.top.setFocus(true)
end sub

'-------------------------------------------------------------------------------
' requestFirstHomeItemFocus
'-------------------------------------------------------------------------------
sub requestFirstHomeItemFocus()
    m.focusState.firstItemPending = true
    applyFirstHomeItemFocus()

    if m.focusRetryTimer = invalid then return
    m.focusState.retryCount = 0
    m.focusRetryTimer.control = "stop"
    m.focusRetryTimer.control = "start"
end sub

'-------------------------------------------------------------------------------
' onFocusRetryTimerFired
'-------------------------------------------------------------------------------
sub onFocusRetryTimerFired()
    if m.focusRetryTimer = invalid then return
    if m.focusState.firstItemPending <> true or m.top.visible <> true or m.homeRowList = invalid or m.homeRowList.visible <> true then
        finishFirstHomeItemFocus()
        return
    end if

    applyFirstHomeItemFocus()
    m.focusState.retryCount = m.focusState.retryCount + 1

    if isFocusedOnHomeItem(0, 0) and m.homeRowList.isInFocusChain() then
        finishFirstHomeItemFocus()
    else if m.focusState.retryCount >= m.focusState.retryMax then
        finishFirstHomeItemFocus()
    end if
end sub

'-------------------------------------------------------------------------------
' finishFirstHomeItemFocus
'-------------------------------------------------------------------------------
sub finishFirstHomeItemFocus()
    m.focusState.firstItemPending = false
    if m.focusRetryTimer <> invalid then m.focusRetryTimer.control = "stop"
end sub

'-------------------------------------------------------------------------------
' applyFirstHomeItemFocus
'-------------------------------------------------------------------------------
sub applyFirstHomeItemFocus()
    if m.homeRowList = invalid then return
    if m.homeRowList.content = invalid then return
    if m.homeRowList.content.getChildCount() <= 0 then return

    firstRow = m.homeRowList.content.getChild(0)
    if firstRow = invalid or firstRow.getChildCount() <= 0 then return

    m.homeRowList.setFocus(true)
    m.homeRowList.jumpToRowItem = [0, 0]
    setFocusedItemNode(firstRow.getChild(0))
end sub

'-------------------------------------------------------------------------------
' isFocusedOnHomeItem
'-------------------------------------------------------------------------------
function isFocusedOnHomeItem(rowIndex as integer, itemIndex as integer) as boolean
    if m.homeRowList = invalid then return false

    focused = m.homeRowList.rowItemFocused
    if focused = invalid or focused.Count() < 2 then return false
    return focused[0] = rowIndex and focused[1] = itemIndex
end function

'-------------------------------------------------------------------------------
' onKeyEvent
'-------------------------------------------------------------------------------
function onKeyEvent(key as string, press as boolean) as boolean
    if press = false then return false

    if key = "up" and (isFocusedOnFirstRow() or isStatusFocused()) then
        finishFirstHomeItemFocus()
        m.top.upFromFirstRowSelected = true
        return true
    end if

    if key <> "back" then return false

    finishFirstHomeItemFocus()
    m.top.backSelected = true
    return true
end function

'-------------------------------------------------------------------------------
' isStatusFocused
'-------------------------------------------------------------------------------
function isStatusFocused() as boolean
    if SafeString(m.top.statusMessage, "") = "" then return false
    return m.top.isInFocusChain()
end function

'-------------------------------------------------------------------------------
' isFocusedOnFirstRow
'-------------------------------------------------------------------------------
function isFocusedOnFirstRow() as boolean
    if m.homeRowList = invalid then return false
    if m.homeRowList.visible <> true then return false
    if m.homeRowList.isInFocusChain() <> true then return false

    focused = m.homeRowList.rowItemFocused
    if focused = invalid then focused = m.homeRowList.rowItemSelected
    if focused = invalid or focused.Count() < 1 then return true

    rowIndex = focused[0]
    if rowIndex = invalid then return true

    return rowIndex = 0
end function

'-------------------------------------------------------------------------------
' onItemSelected
'-------------------------------------------------------------------------------
sub onItemSelected()
    item = getSelectedItem()
    if item = invalid or item.id = invalid then return

    m.top.playSelected = {
        id: item.id
        title: getLibraryItemTitle(item)
        details: getPlaybackDetails(item)
        startPositionSeconds: getPlaybackStartPosition(item)
    }
end sub

'-------------------------------------------------------------------------------
' onRowItemFocused
'-------------------------------------------------------------------------------
sub onRowItemFocused()
    setFocusedItemNode(getFocusedItemNode())
end sub

'-------------------------------------------------------------------------------
' setFocusedItemNode
'-------------------------------------------------------------------------------
sub setFocusedItemNode(itemNode as dynamic)
    if m.shelfState.focusedItemNode <> invalid then m.shelfState.focusedItemNode.focused = false

    m.shelfState.focusedItemNode = itemNode
    if m.shelfState.focusedItemNode <> invalid then m.shelfState.focusedItemNode.focused = true
end sub

'-------------------------------------------------------------------------------
' getFocusedItemNode
'-------------------------------------------------------------------------------
function getFocusedItemNode() as dynamic
    if m.homeRowList = invalid or m.homeRowList.content = invalid then return invalid

    focused = m.homeRowList.rowItemFocused
    if focused = invalid or focused.Count() < 2 then return invalid

    rowIndex = focused[0]
    itemIndex = focused[1]
    if rowIndex = invalid or itemIndex = invalid then return invalid
    if rowIndex < 0 or rowIndex >= m.homeRowList.content.getChildCount() then return invalid

    row = m.homeRowList.content.getChild(rowIndex)
    if row = invalid then return invalid
    if itemIndex < 0 or itemIndex >= row.getChildCount() then return invalid

    return row.getChild(itemIndex)
end function

'-------------------------------------------------------------------------------
' getSelectedItem
'-------------------------------------------------------------------------------
function getSelectedItem() as dynamic
    if m.homeRowList = invalid then return invalid
    return getShelfItemAtPosition(m.homeRowList.rowItemSelected)
end function

'-------------------------------------------------------------------------------
' getShelfItemAtPosition
'-------------------------------------------------------------------------------
function getShelfItemAtPosition(position as dynamic) as dynamic
    if m.shelfState.itemsByRow = invalid then return invalid
    if position = invalid or position.Count() < 2 then return invalid

    rowIndex = position[0]
    itemIndex = position[1]
    if rowIndex = invalid or itemIndex = invalid then return invalid
    if rowIndex < 0 or rowIndex >= m.shelfState.itemsByRow.Count() then return invalid

    itemsByIndex = m.shelfState.itemsByRow[rowIndex]
    if itemsByIndex = invalid then return invalid
    if itemIndex < 0 or itemIndex >= itemsByIndex.Count() then return invalid

    return itemsByIndex[itemIndex]
end function

'-------------------------------------------------------------------------------
' getLibraryItemTitle
'-------------------------------------------------------------------------------
function getLibraryItemTitle(item as dynamic) as string
    title = "Untitled"

    if item <> invalid and item.media <> invalid and item.media.metadata <> invalid then
        title = FirstNonEmpty([item.media.metadata.title], title)
    else if item <> invalid and item.title <> invalid then
        title = SafeString(item.title, title)
    end if

    return title
end function

'-------------------------------------------------------------------------------
' getPlaybackStartPosition
'-------------------------------------------------------------------------------
function getPlaybackStartPosition(item as dynamic) as integer
    return ProgressData_GetPlaybackStartPosition(item, m.top.mediaProgress)
end function

'-------------------------------------------------------------------------------
' getPlaybackDetails
'-------------------------------------------------------------------------------
function getPlaybackDetails(item as dynamic) as object
    metadata = ItemMetadataParser_GetMetadata(item)
    return {
        authors: ItemMetadataParser_GetAuthor(metadata)
        authorCount: ItemMetadataParser_GetNameCount(metadata.authors, ItemMetadataParser_GetAuthor(metadata))
        narrators: ItemMetadataParser_GetNarrators(metadata)
        narratorCount: ItemMetadataParser_GetNameCount(metadata.narrators, ItemMetadataParser_GetNarrators(metadata))
        description: ItemMetadataParser_GetDescription(metadata)
        publisher: FirstNonEmpty([metadata.publisher], "Unknown")
        publishDate: ItemMetadataParser_GetPublishDate(metadata)
        category: ItemMetadataParser_GetCategory(metadata)
        duration: ItemMetadataParser_GetDuration(item)
        durationSeconds: ItemMetadataParser_GetDurationSeconds(item)
    }
end function
