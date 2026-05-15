'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    initReferences()

    m.libraryRows = []
    m.expandedSeriesIds = {}
    m.seriesItemsById = {}
    m.loadingSeriesId = invalid
    m.upFromFirstItemSelectedCounter = 0
    m.activeOverviewKey = ""
    m.server = invalid
    m.token = invalid
    m.bookLibraryId = invalid

    initHandlers()
    onLibraryItemsChanged()
    onContextTitleChanged()
end sub

'-------------------------------------------------------------------------------
' initReferences
'-------------------------------------------------------------------------------
sub initReferences()
    m.libraryList = m.top.findNode("libraryList")
    m.contextTitleLabel = m.top.findNode("contextTitleLabel")
    m.overview = m.top.findNode("overview")
end sub

'-------------------------------------------------------------------------------
' onContextTitleChanged
'-------------------------------------------------------------------------------
sub onContextTitleChanged()
    title = String_Trim(m.top.contextTitle)
    hasTitle = (title <> "" and m.top.contextType = "search")

    if m.contextTitleLabel <> invalid then
        m.contextTitleLabel.text = title
        m.contextTitleLabel.visible = hasTitle
    end if

    if m.libraryList <> invalid then
        if hasTitle then
            m.libraryList.translation = [64,200]
            m.libraryList.numRows = 14
        else
            m.libraryList.translation = [64,162]
            m.libraryList.numRows = 15
        end if
    end if
end sub

'-------------------------------------------------------------------------------
' initHandlers
'-------------------------------------------------------------------------------
sub initHandlers()
    if m.libraryList <> invalid then
        m.libraryList.observeField("itemFocused", "onLibraryItemFocused")
        m.libraryList.observeField("itemSelected", "onLibraryItemSelected")
    end if
    m.top.observeField("focusedChild", "onFocusChanged")

    if m.overview <> invalid then
        m.overview.observeField("playSelected", "onOverviewPlaySelected")
        m.overview.observeField("seriesActionSelected", "onOverviewSeriesActionSelected")
        m.overview.observeField("leftRequested", "onOverviewLeftRequested")
    end if
end sub

'-------------------------------------------------------------------------------
' onLoadRequestChanged
'-------------------------------------------------------------------------------
sub onLoadRequestChanged()
    request = m.top.loadRequest
    if request = invalid then return

    m.server = request.server
    m.token = request.token
    m.bookLibraryId = request.bookLibraryId
    syncLoadRequestToOverview()
end sub

'-------------------------------------------------------------------------------
' onMediaProgressChanged
'-------------------------------------------------------------------------------
sub onMediaProgressChanged()
    if m.overview <> invalid then m.overview.mediaProgress = m.top.mediaProgress
end sub

'-------------------------------------------------------------------------------
' syncLoadRequestToOverview
'-------------------------------------------------------------------------------
sub syncLoadRequestToOverview()
    if m.overview <> invalid then m.overview.loadRequest = m.top.loadRequest
end sub

'-------------------------------------------------------------------------------
' onLibraryItemsChanged
'-------------------------------------------------------------------------------
sub onLibraryItemsChanged()
    if m.libraryList = invalid then return

    resetSeriesExpansionState()
    rebuildLibraryList(0)
end sub

'-------------------------------------------------------------------------------
' resetSeriesExpansionState
'-------------------------------------------------------------------------------
sub resetSeriesExpansionState()
    m.expandedSeriesIds = {}
    m.seriesItemsById = {}
    m.loadingSeriesId = invalid
    m.activeOverviewKey = ""
end sub

'-------------------------------------------------------------------------------
' rebuildLibraryList
'-------------------------------------------------------------------------------
sub rebuildLibraryList(focusIndex as dynamic)
    if m.libraryList = invalid then return

    root = CreateObject("roSGNode", "ContentNode")
    items = m.top.libraryItems
    m.libraryRows = []

    if items <> invalid then
        for each item in items
            if isDisplayableLibraryItem(item) then
                appendLibraryRow(root, createLibraryRow(item, false, invalid))

                seriesId = getCollapsedSeriesId(item)
                if isSeriesExpanded(seriesId) then
                    appendExpandedSeriesRows(root, seriesId)
                end if
            end if
        end for
    end if

    setStatus("")
    if root.getChildCount() = 0 then
        if m.top.loading = true then
            setStatus("Loading...")
        else
            setStatus("No titles found")
        end if
    end if

    m.libraryList.content = root
    if m.libraryRows.Count() > 0 then
        selectedIndex = getValidRowIndex(focusIndex)
        m.libraryList.jumpToItem = selectedIndex
        showSelectedRow(getSelectedLibraryRow(selectedIndex))
        if m.top.visible then
            m.libraryList.setFocus(true)
            updateLibraryListFocusState()
        end if
    else
        showSelectedItem(invalid, false)
    end if
end sub

'-------------------------------------------------------------------------------
' setStatus
'-------------------------------------------------------------------------------
sub setStatus(message as dynamic)
    text = SafeString(message, "")
    m.top.statusMessage = text
    setContentVisible(text = "")
end sub

'-------------------------------------------------------------------------------
' setContentVisible
'-------------------------------------------------------------------------------
sub setContentVisible(isVisible as boolean)
    if m.libraryList <> invalid then m.libraryList.visible = isVisible
    if m.overview <> invalid then m.overview.visible = isVisible
end sub

'-------------------------------------------------------------------------------
' isDisplayableLibraryItem
'-------------------------------------------------------------------------------
function isDisplayableLibraryItem(item as dynamic) as boolean
    if item = invalid then return false
    return item.mediaType = invalid or item.mediaType = "book"
end function

'-------------------------------------------------------------------------------
' createLibraryRow
'-------------------------------------------------------------------------------
function createLibraryRow(item as dynamic, isChild as boolean, seriesId as dynamic) as object
    if seriesId = invalid then seriesId = getCollapsedSeriesId(item)

    rowType = getListRowType(item)
    if isChild then rowType = "book"

    return {
        type: rowType
        item: item
        seriesId: seriesId
        child: isChild
    }
end function

'-------------------------------------------------------------------------------
' appendLibraryRow
'-------------------------------------------------------------------------------
sub appendLibraryRow(root as object, row as object)
    node = CreateObject("roSGNode", "ContentNode")
    node.title = getListRowTitle(row)
    node.addFields({
        isSeries: row.type = "series"
        isExpanded: row.type = "series" and isSeriesExpanded(row.seriesId)
        listHasFocus: false
    })
    root.appendChild(node)
    m.libraryRows.Push(row)
end sub

'-------------------------------------------------------------------------------
' appendExpandedSeriesRows
'-------------------------------------------------------------------------------
sub appendExpandedSeriesRows(root as object, seriesId as dynamic)
    if seriesId = invalid then return

    seriesItems = m.seriesItemsById[getSeriesIdText(seriesId)]
    if seriesItems = invalid then return

    for each childItem in seriesItems
        if isDisplayableLibraryItem(childItem) then
            appendLibraryRow(root, createLibraryRow(childItem, true, seriesId))
        end if
    end for
end sub

'-------------------------------------------------------------------------------
' onLibraryItemFocused
'-------------------------------------------------------------------------------
sub onLibraryItemFocused()
    showSelectedRow(getSelectedLibraryRow(m.libraryList.itemFocused))
end sub

'-------------------------------------------------------------------------------
' onFocusChanged
'-------------------------------------------------------------------------------
sub onFocusChanged()
    updateLibraryListFocusState()
end sub

'-------------------------------------------------------------------------------
' updateLibraryListFocusState
'-------------------------------------------------------------------------------
sub updateLibraryListFocusState()
    if m.libraryList = invalid then return
    if m.libraryList.content = invalid then return

    hasFocus = m.libraryList.isInFocusChain() = true
    content = m.libraryList.content
    for i = 0 to content.getChildCount() - 1
        node = content.getChild(i)
        if node <> invalid and node.listHasFocus <> invalid then node.listHasFocus = hasFocus
    end for
end sub

'-------------------------------------------------------------------------------
' onLibraryItemSelected
'-------------------------------------------------------------------------------
sub onLibraryItemSelected()
    showSelectedRow(getSelectedLibraryRow(m.libraryList.itemSelected))
end sub

'-------------------------------------------------------------------------------
' getSelectedLibraryRow
'-------------------------------------------------------------------------------
function getSelectedLibraryRow(index as dynamic) as dynamic
    if index = invalid then return invalid
    if m.libraryRows = invalid then return invalid
    if index < 0 or index >= m.libraryRows.Count() then return invalid
    return m.libraryRows[index]
end function

'-------------------------------------------------------------------------------
' showSelectedRow
'-------------------------------------------------------------------------------
sub showSelectedRow(row as dynamic)
    if row = invalid then
        showSelectedItem(invalid, false)
        return
    end if

    showSelectedItem(row.item, row.type = "series")
end sub

'-------------------------------------------------------------------------------
' showSelectedItem
'-------------------------------------------------------------------------------
sub showSelectedItem(item as dynamic, isSeries as boolean)
    if m.overview = invalid then return

    overviewKey = getOverviewKey(item, isSeries)

    ' Rebuilding the MarkupList for expand/collapse can reselect the same logical row.
    ' Avoid resending that item to Overview so poster stacks do not clear and reload.
    if overviewKey <> "" and overviewKey = m.activeOverviewKey then return

    m.activeOverviewKey = overviewKey
    m.overview.isSeries = isSeries
    m.overview.item = item
end sub

'-------------------------------------------------------------------------------
' getOverviewKey
'-------------------------------------------------------------------------------
function getOverviewKey(item as dynamic, isSeries as boolean) as string
    if item = invalid then return "none"
    if isSeries then
        seriesIdText = getSeriesIdText(getCollapsedSeriesId(item))
        if seriesIdText <> "" then return "series:" + seriesIdText
    end if

    itemId = getLibraryItemIdText(item)
    if itemId <> "" then return "book:" + itemId

    return "book-title:" + ItemMetadataParser_GetTitle(item)
end function

'-------------------------------------------------------------------------------
' getLibraryItemIdText
'-------------------------------------------------------------------------------
function getLibraryItemIdText(item as dynamic) as string
    if item = invalid then return ""
    if item.id <> invalid then return item.id.ToStr()
    if item.libraryItemId <> invalid then return item.libraryItemId.ToStr()
    if item.mediaItemId <> invalid then return item.mediaItemId.ToStr()
    if item.media <> invalid and item.media.id <> invalid then return item.media.id.ToStr()
    return ""
end function

'-------------------------------------------------------------------------------
' onOverviewPlaySelected
'-------------------------------------------------------------------------------
sub onOverviewPlaySelected()
    if m.overview <> invalid then m.top.playSelected = m.overview.playSelected
end sub

'-------------------------------------------------------------------------------
' onOverviewSeriesActionSelected
'-------------------------------------------------------------------------------
sub onOverviewSeriesActionSelected()
    toggleSeriesAtCurrentIndex()
end sub

'-------------------------------------------------------------------------------
' onOverviewLeftRequested
'-------------------------------------------------------------------------------
sub onOverviewLeftRequested()
    focusLibraryList()
end sub

'-------------------------------------------------------------------------------
' focusLibraryList
'-------------------------------------------------------------------------------
sub focusLibraryList()
    if SafeString(m.top.statusMessage, "") <> "" then return
    if m.libraryList = invalid or m.libraryList.visible <> true then return

    clearOverviewFocus()
    if m.libraryList <> invalid then
        m.libraryList.setFocus(true)
        updateLibraryListFocusState()
    end if
end sub

'-------------------------------------------------------------------------------
' focusPlayButton
'-------------------------------------------------------------------------------
sub focusPlayButton()
    if m.overview <> invalid then
        m.overview.callFunc("focusPlayButton")
        updateLibraryListFocusState()
    end if
end sub

'-------------------------------------------------------------------------------
' getListRowType
'-------------------------------------------------------------------------------
function getListRowType(item as dynamic) as string
    if getCollapsedSeriesId(item) <> invalid then return "series"
    return "book"
end function

'-------------------------------------------------------------------------------
' getListRowTitle
'-------------------------------------------------------------------------------
function getListRowTitle(row as object) as string
    item = row.item
    if getCollapsedSeriesId(item) <> invalid then
        return getSeriesListTitle(item)
    end if

    if row.child = true then return "    " + getBookListTitle(item, row.seriesId)
    return ItemMetadataParser_GetTitle(item)
end function

'-------------------------------------------------------------------------------
' getSeriesListTitle
'-------------------------------------------------------------------------------
function getSeriesListTitle(item as dynamic) as string
    title = getCollapsedSeriesTitle(item)

    return title
end function

'-------------------------------------------------------------------------------
' getCollapsedSeriesTitle
'-------------------------------------------------------------------------------
function getCollapsedSeriesTitle(item as dynamic) as string
    if item = invalid or item.collapsedSeries = invalid then return ItemMetadataParser_GetTitle(item)

    collapsedSeries = item.collapsedSeries
    return FirstNonEmpty([
        collapsedSeries.nameIgnorePrefix
        collapsedSeries.name
        collapsedSeries.title
        ItemMetadataParser_GetTitle(item)
    ], "Untitled")
end function

'-------------------------------------------------------------------------------
' getBookListTitle
'-------------------------------------------------------------------------------
function getBookListTitle(item as dynamic, seriesId as dynamic) as string
    title = ItemMetadataParser_GetTitle(item)
    if seriesId = invalid then return title

    sequence = getSeriesSequence(item, seriesId)
    if sequence <> "" then return "#" + sequence + "  " + title
    return title
end function

'-------------------------------------------------------------------------------
' getCollapsedSeriesCountText
'-------------------------------------------------------------------------------
function getCollapsedSeriesCountText(item as dynamic) as string
    count = getCollapsedSeriesBookCount(item)
    if count <= 0 then return ""
    if count = 1 then return "(1 book)"
    return "(" + count.ToStr() + " books)"
end function

'-------------------------------------------------------------------------------
' getCollapsedSeriesBookCount
'-------------------------------------------------------------------------------
function getCollapsedSeriesBookCount(item as dynamic) as integer
    if item = invalid or item.collapsedSeries = invalid then return 0

    collapsedSeries = item.collapsedSeries
    countValue = invalid
    if collapsedSeries.numBooks <> invalid then countValue = collapsedSeries.numBooks
    if countValue = invalid and collapsedSeries.bookCount <> invalid then countValue = collapsedSeries.bookCount
    if countValue = invalid and collapsedSeries.count <> invalid then countValue = collapsedSeries.count
    if countValue = invalid and collapsedSeries.numItems <> invalid then countValue = collapsedSeries.numItems
    if countValue = invalid then return 0

    return int(val(countValue.ToStr()))
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
' getCollapsedSeriesLibraryItemIds
'-------------------------------------------------------------------------------
function getCollapsedSeriesLibraryItemIds(item as dynamic) as dynamic
    if item = invalid then return invalid
    if item.collapsedSeries = invalid then return invalid
    if item.collapsedSeries.libraryItemIds = invalid then return invalid
    return item.collapsedSeries.libraryItemIds
end function

'-------------------------------------------------------------------------------
' getSeriesSequence
'-------------------------------------------------------------------------------
function getSeriesSequence(item as dynamic, seriesId as dynamic) as string
    if item = invalid then return ""

    metadata = ItemMetadataParser_GetMetadata(item)
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
            if isMatchingSeriesEntry(seriesEntry, seriesId) then
                sequence = getSeriesEntrySequence(seriesEntry)
                if sequence <> "" then return sequence
            end if
        end for

        for each seriesEntry in series
            sequence = getSeriesEntrySequence(seriesEntry)
            if sequence <> "" then return sequence
        end for
    else if seriesType = "roAssociativeArray" then
        sequence = getSeriesEntrySequence(series)
        if sequence <> "" then return sequence
    end if

    sequence = getSeriesEntrySequence(series)
    if sequence <> "" then return sequence

    return ""
end function

'-------------------------------------------------------------------------------
' isMatchingSeriesEntry
'-------------------------------------------------------------------------------
function isMatchingSeriesEntry(seriesEntry as dynamic, seriesId as dynamic) as boolean
    seriesIdText = getSeriesIdText(seriesId)
    if seriesIdText = "" then return false

    return getSeriesEntryIdText(seriesEntry) = seriesIdText
end function

'-------------------------------------------------------------------------------
' getSeriesEntryIdText
'-------------------------------------------------------------------------------
function getSeriesEntryIdText(seriesEntry as dynamic) as string
    if seriesEntry = invalid then return ""
    if Type(seriesEntry) <> "roAssociativeArray" then return ""
    if seriesEntry.id = invalid then return ""
    return seriesEntry.id.ToStr()
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
' isSeriesExpanded
'-------------------------------------------------------------------------------
function isSeriesExpanded(seriesId as dynamic) as boolean
    seriesIdText = getSeriesIdText(seriesId)
    if seriesIdText = "" then return false
    return m.expandedSeriesIds <> invalid and m.expandedSeriesIds[seriesIdText] = true
end function

'-------------------------------------------------------------------------------
' setSeriesExpanded
'-------------------------------------------------------------------------------
sub setSeriesExpanded(seriesId as dynamic, isExpanded as boolean)
    seriesIdText = getSeriesIdText(seriesId)
    if seriesIdText = "" then return

    if isExpanded then
        m.expandedSeriesIds[seriesIdText] = true
    else
        m.expandedSeriesIds.Delete(seriesIdText)
    end if
end sub

'-------------------------------------------------------------------------------
' getSeriesIdText
'-------------------------------------------------------------------------------
function getSeriesIdText(seriesId as dynamic) as string
    if seriesId = invalid then return ""
    return seriesId.ToStr()
end function

'-------------------------------------------------------------------------------
' getValidRowIndex
'-------------------------------------------------------------------------------
function getValidRowIndex(index as dynamic) as integer
    if index = invalid or index < 0 then return 0
    if m.libraryRows = invalid or m.libraryRows.Count() = 0 then return 0
    if index >= m.libraryRows.Count() then return m.libraryRows.Count() - 1
    return index
end function

'-------------------------------------------------------------------------------
' getCurrentLibraryRowIndex
'-------------------------------------------------------------------------------
function getCurrentLibraryRowIndex() as integer
    return getValidRowIndex(getFocusedLibraryIndex())
end function

'-------------------------------------------------------------------------------
' getFocusedLibraryIndex
'-------------------------------------------------------------------------------
function getFocusedLibraryIndex() as dynamic
    if m.libraryList = invalid then return 0

    currentIndex = m.libraryList.itemFocused
    if currentIndex = invalid or currentIndex < 0 then currentIndex = m.libraryList.itemSelected
    if currentIndex = invalid then currentIndex = 0
    return currentIndex
end function

'-------------------------------------------------------------------------------
' toggleSeriesAtCurrentIndex
'-------------------------------------------------------------------------------
function toggleSeriesAtCurrentIndex() as boolean
    if m.libraryList = invalid then return false

    return toggleSeriesAtIndex(getCurrentLibraryRowIndex())
end function

'-------------------------------------------------------------------------------
' toggleSeriesAtIndex
'-------------------------------------------------------------------------------
function toggleSeriesAtIndex(index as dynamic) as boolean
    row = getSelectedLibraryRow(index)
    if row = invalid or row.type <> "series" then return false

    seriesId = row.seriesId
    if seriesId = invalid then return false
    if m.loadingSeriesId <> invalid then return true

    if isSeriesExpanded(seriesId) then
        setSeriesExpanded(seriesId, false)
        rebuildLibraryList(index)
        return true
    end if

    seriesIdText = getSeriesIdText(seriesId)
    if m.seriesItemsById[seriesIdText] <> invalid then
        setSeriesExpanded(seriesId, true)
        rebuildLibraryList(index)
        return true
    end if

    loadSeriesRows(seriesId, index, row.item)
    return true
end function

'-------------------------------------------------------------------------------
' loadSeriesRows
'-------------------------------------------------------------------------------
sub loadSeriesRows(seriesId as dynamic, sourceIndex as dynamic, seriesItem as dynamic)
    if seriesId = invalid then return

    m.loadingSeriesId = seriesId
    rebuildLibraryList(sourceIndex)

    m.top.seriesItemsRequest = {
        action: "loadSeries"
        sourceView: "list"
        seriesId: seriesId
        libraryItemIds: getCollapsedSeriesLibraryItemIds(seriesItem)
        sourceItemIndex: sourceIndex
    }
end sub

'-------------------------------------------------------------------------------
' onSeriesItemsResponseChanged
'-------------------------------------------------------------------------------
sub onSeriesItemsResponseChanged()
    response = m.top.seriesItemsResponse
    if response = invalid then return

    sourceIndex = getValidRowIndex(response.sourceItemIndex)
    m.loadingSeriesId = invalid

    if response.ok <> true then
        rebuildLibraryList(sourceIndex)
        m.top.errorResponse = response
        return
    end if

    if response.action <> "loadSeries" or response.seriesId = invalid then return

    seriesIdText = getSeriesIdText(response.seriesId)
    m.seriesItemsById[seriesIdText] = getResponseLibraryItems(response)
    setSeriesExpanded(response.seriesId, true)
    rebuildLibraryList(sourceIndex)
end sub

'-------------------------------------------------------------------------------
' getResponseLibraryItems
'-------------------------------------------------------------------------------
function getResponseLibraryItems(response as dynamic) as object
    if response <> invalid and response.libraryItems <> invalid then return response.libraryItems
    return []
end function

' focusSelectedLibraryItem
'-------------------------------------------------------------------------------
function focusSelectedLibraryItem() as boolean
    if m.libraryList = invalid then return false
    if m.libraryRows = invalid or m.libraryRows.Count() = 0 then return false

    currentIndex = getValidRowIndex(getFocusedLibraryIndex())

    lastIndex = m.libraryRows.Count() - 1
    if currentIndex > lastIndex then currentIndex = lastIndex

    clearOverviewFocus()
    m.libraryList.jumpToItem = currentIndex
    showSelectedRow(getSelectedLibraryRow(currentIndex))
    m.libraryList.setFocus(true)
    updateLibraryListFocusState()

    return true
end function

'-------------------------------------------------------------------------------
' focusFirstLibraryItem
'-------------------------------------------------------------------------------
function focusFirstLibraryItem() as boolean
    if m.libraryList = invalid then return false
    if m.libraryRows = invalid or m.libraryRows.Count() = 0 then return false

    currentIndex = getFocusedLibraryIndex()
    if currentIndex = invalid or currentIndex <= 0 then return false

    clearOverviewFocus()
    m.libraryList.jumpToItem = 0
    showSelectedRow(getSelectedLibraryRow(0))
    m.libraryList.setFocus(true)
    updateLibraryListFocusState()

    return true
end function

'-------------------------------------------------------------------------------
' onKeyEvent
'-------------------------------------------------------------------------------
function onKeyEvent(key as string, press as boolean) as boolean
    if press = false then return false

    if key = "back" then
        if isOverviewFocused() then
            return focusSelectedLibraryItem()
        end if

        if collapseCurrentSeries() then return true
        if focusFirstLibraryItem() then return true
        if requestHeaderFocusFromFirstItem() then return true
    end if

    if m.libraryList <> invalid and m.libraryList.isInFocusChain() then
        if key = "up" then return requestHeaderFocusFromFirstItem()
        if key = "right" then
            moveLibraryListFocus(10)
            return true
        else if key = "left" then
            moveLibraryListFocus(-10)
            return true
        else if key = "OK" or key = "select" then
            if toggleSeriesAtCurrentIndex() then return true
            focusPlayButton()
            return true
        end if
    end if

    return false
end function

'-------------------------------------------------------------------------------
' isOverviewFocused
'-------------------------------------------------------------------------------
function isOverviewFocused() as boolean
    if m.overview = invalid then return false

    isFocused = m.overview.callFunc("isInFocusChain")
    return isFocused = true
end function

'-------------------------------------------------------------------------------
' clearOverviewFocus
'-------------------------------------------------------------------------------
sub clearOverviewFocus()
    if m.overview <> invalid then m.overview.callFunc("clearFocusVisual")
end sub

'-------------------------------------------------------------------------------
' collapseCurrentSeries
'-------------------------------------------------------------------------------
function collapseCurrentSeries() as boolean
    if m.libraryList = invalid then return false
    if m.libraryList.isInFocusChain() = false then return false

    currentIndex = getCurrentLibraryRowIndex()
    row = getSelectedLibraryRow(currentIndex)
    if row = invalid then return false

    seriesId = row.seriesId
    if seriesId = invalid then return false
    if isSeriesExpanded(seriesId) = false then return false

    headerIndex = currentIndex
    seriesIdText = getSeriesIdText(seriesId)
    for i = currentIndex to 0 step -1
        candidate = getSelectedLibraryRow(i)
        if candidate <> invalid and candidate.type = "series" and getSeriesIdText(candidate.seriesId) = seriesIdText then
            headerIndex = i
            exit for
        end if
    end for

    setSeriesExpanded(seriesId, false)
    rebuildLibraryList(headerIndex)
    return true
end function

'-------------------------------------------------------------------------------
' requestHeaderFocusFromFirstItem
'-------------------------------------------------------------------------------
function requestHeaderFocusFromFirstItem() as boolean
    if m.libraryList = invalid then return false
    if m.libraryList.isInFocusChain() = false then return false

    currentIndex = getFocusedLibraryIndex()
    if currentIndex > 0 then return false

    m.upFromFirstItemSelectedCounter = m.upFromFirstItemSelectedCounter + 1
    m.top.upFromFirstItemSelected = m.upFromFirstItemSelectedCounter
    return true
end function

'-------------------------------------------------------------------------------
' moveLibraryListFocus
'-------------------------------------------------------------------------------
sub moveLibraryListFocus(offset as integer)
    if m.libraryList = invalid then return
    if m.libraryRows = invalid or m.libraryRows.Count() = 0 then return

    currentIndex = m.libraryList.itemFocused
    if currentIndex = invalid or currentIndex < 0 then currentIndex = 0

    nextIndex = currentIndex + offset
    if nextIndex < 0 then nextIndex = 0
    lastIndex = m.libraryRows.Count() - 1
    if nextIndex > lastIndex then nextIndex = lastIndex

    m.libraryList.jumpToItem = nextIndex
    showSelectedRow(getSelectedLibraryRow(nextIndex))
end sub
