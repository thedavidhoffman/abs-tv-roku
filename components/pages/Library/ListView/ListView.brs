'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    initReferences()

    m.libraryItemsByRow = []
    m.libraryRows = []
    m.expandedSeriesIds = {}
    m.seriesItemsById = {}
    m.loadingSeriesId = invalid
    m.selectedItem = invalid
    m.playSelectedCounter = 0
    m.upFromFirstItemSelectedCounter = 0
    m.server = invalid
    m.token = invalid
    m.bookLibraryId = invalid

    initHandlers()
    initStyle()
    updatePlayButtonFocus(false)
    onLibraryItemsChanged()
end sub

'-------------------------------------------------------------------------------
' initReferences
'-------------------------------------------------------------------------------
sub initReferences()
    m.overviewBg = m.top.findNode("overviewBg")
    m.libraryList = m.top.findNode("libraryList")
    m.selectedPoster = m.top.findNode("selectedPoster")
    m.playButton = m.top.findNode("playButton")
    m.detailTitle = m.top.findNode("detailTitle")
    m.detailAuthor = m.top.findNode("detailAuthor")
    m.detailNarrators = m.top.findNode("detailNarrators")
    m.detailDescription = m.top.findNode("detailDescription")
    m.detailPublisher = m.top.findNode("detailPublisher")
    m.detailPublishDate = m.top.findNode("detailPublishDate")
    m.detailGenres = m.top.findNode("detailGenres")
    m.detailTags = m.top.findNode("detailTags")
    m.detailDuration = m.top.findNode("detailDuration")
    m.seriesApiTask = m.top.findNode("seriesApiTask")
end sub

'-------------------------------------------------------------------------------
' initHandlers
'-------------------------------------------------------------------------------
sub initHandlers()
    if m.libraryList <> invalid then
        m.libraryList.observeField("itemFocused", "onLibraryItemFocused")
        m.libraryList.observeField("itemSelected", "onLibraryItemSelected")
    end if

    if m.seriesApiTask <> invalid then
        m.seriesApiTask.observeField("response", "onSeriesApiResponse")
    end if
end sub

'-------------------------------------------------------------------------------
' initStyle
'-------------------------------------------------------------------------------
sub initStyle()
    palette = Color()
    if m.overviewBg <> invalid then m.overviewBg.color = palette.background.primary
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
end sub

'-------------------------------------------------------------------------------
' rebuildLibraryList
'-------------------------------------------------------------------------------
sub rebuildLibraryList(focusIndex as dynamic)
    if m.libraryList = invalid then return

    root = CreateObject("roSGNode", "ContentNode")
    items = m.top.libraryItems
    m.libraryItemsByRow = []
    m.libraryRows = []

    if items <> invalid then
        for each item in items
            if isDisplayableLibraryItem(item) then
                appendLibraryRow(root, createLibraryRow(item, false, invalid, invalid))

                seriesId = getCollapsedSeriesId(item)
                if isSeriesExpanded(seriesId) then
                    appendExpandedSeriesRows(root, seriesId, item)
                end if
            end if
        end for
    end if

    if root.getChildCount() = 0 then
        node = CreateObject("roSGNode", "ContentNode")
        node.title = "No titles found"
        root.appendChild(node)
    end if

    m.libraryList.content = root
    if m.libraryItemsByRow.Count() > 0 then
        selectedIndex = getValidRowIndex(focusIndex)
        m.libraryList.jumpToItem = selectedIndex
        showSelectedRow(getSelectedLibraryRow(selectedIndex))
        if m.top.visible then m.libraryList.setFocus(true)
    else
        showSelectedItem(invalid)
    end if
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
function createLibraryRow(item as dynamic, isChild as boolean, seriesId as dynamic, parentItem as dynamic) as object
    if seriesId = invalid then seriesId = getCollapsedSeriesId(item)

    rowType = getListRowType(item)
    if isChild then rowType = "book"

    return {
        type: rowType
        item: item
        seriesId: seriesId
        parentItem: parentItem
        child: isChild
    }
end function

'-------------------------------------------------------------------------------
' appendLibraryRow
'-------------------------------------------------------------------------------
sub appendLibraryRow(root as object, row as object)
    node = CreateObject("roSGNode", "ContentNode")
    node.title = getListRowTitle(row)
    root.appendChild(node)
    m.libraryItemsByRow.Push(row.item)
    m.libraryRows.Push(row)
end sub

'-------------------------------------------------------------------------------
' appendExpandedSeriesRows
'-------------------------------------------------------------------------------
sub appendExpandedSeriesRows(root as object, seriesId as dynamic, seriesItem as dynamic)
    if seriesId = invalid then return

    seriesItems = m.seriesItemsById[seriesId.ToStr()]
    if seriesItems = invalid then return

    for each childItem in seriesItems
        if isDisplayableLibraryItem(childItem) then
            appendLibraryRow(root, createLibraryRow(childItem, true, seriesId, seriesItem))
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
' onLibraryItemSelected
'-------------------------------------------------------------------------------
sub onLibraryItemSelected()
    showSelectedRow(getSelectedLibraryRow(m.libraryList.itemSelected))
end sub

'-------------------------------------------------------------------------------
' getSelectedLibraryItem
'-------------------------------------------------------------------------------
function getSelectedLibraryItem(index as dynamic) as dynamic
    if index = invalid then return invalid
    if m.libraryItemsByRow = invalid then return invalid
    if index < 0 or index >= m.libraryItemsByRow.Count() then return invalid
    return m.libraryItemsByRow[index]
end function

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
        showSelectedItem(invalid)
        return
    end if

    showSelectedItem(row.item)
end sub

'-------------------------------------------------------------------------------
' showSelectedItem
'-------------------------------------------------------------------------------
sub showSelectedItem(item as dynamic)
    m.selectedItem = item
    if m.selectedPoster <> invalid then m.selectedPoster.itemContent = getSelectedPosterContent(item)
    updateSelectedDetails(item)
    updatePrimaryAction(item)
end sub

'-------------------------------------------------------------------------------
' getSelectedPosterContent
'-------------------------------------------------------------------------------
function getSelectedPosterContent(item as dynamic) as dynamic
    if item = invalid then return invalid

    progress = getProgressData(item)
    node = CreateObject("roSGNode", "ContentNode")
    node.title = ItemMetadataParser_GetTitle(item)
    node.HDPosterUrl = Cover_BuildUrl(m.server, m.token, getCoverItemId(item), 600)
    node.SDPosterUrl = node.HDPosterUrl
    node.AddFields({
        author: ItemMetadataParser_GetAuthor(ItemMetadataParser_GetMetadata(item))
        progressPercent: progress.progress
        progressCurrentTime: progress.currentTime
        progressDuration: progress.duration
        progressIsFinished: progress.isFinished
        focused: false
    })
    return node
end function

'-------------------------------------------------------------------------------
' getProgressData
'-------------------------------------------------------------------------------
function getProgressData(item as dynamic) as object
    mappedProgress = getMappedProgressForItem(item)
    if mappedProgress <> invalid then
        return {
            progress: getNumberFromFields(mappedProgress, ["progress"])
            currentTime: getNumberFromFields(mappedProgress, ["currentTime"])
            duration: getNumberFromFields(mappedProgress, ["duration"])
            isFinished: getBooleanFromFields(mappedProgress, ["isFinished"])
        }
    end if

    progress = invalid

    if item <> invalid and item.userMediaProgress <> invalid then
        progress = item.userMediaProgress
    else if item <> invalid and item.mediaProgress <> invalid then
        progress = item.mediaProgress
    end if

    if progress = invalid then
        return {
            progress: getNumberFromFields(item, ["progress"])
            currentTime: getNumberFromFields(item, ["currentTime", "progressCurrentTime"])
            duration: getNumberFromFields(item, ["duration", "progressDuration"])
            isFinished: getBooleanFromFields(item, ["isFinished", "progressIsFinished"])
        }
    end if

    return {
        progress: getNumberFromFields(progress, ["progress"])
        currentTime: getNumberFromFields(progress, ["currentTime"])
        duration: getNumberFromFields(progress, ["duration"])
        isFinished: getBooleanFromFields(progress, ["isFinished"])
    }
end function

'-------------------------------------------------------------------------------
' getMappedProgressForItem
'-------------------------------------------------------------------------------
function getMappedProgressForItem(item as dynamic) as dynamic
    if item = invalid then return invalid
    if m.top.mediaProgress = invalid then return invalid

    candidateIds = getProgressCandidateIds(item)
    if candidateIds = invalid or candidateIds.Count() = 0 then return invalid

    for each progress in m.top.mediaProgress
        if progress <> invalid and progress.itemId <> invalid and candidateIds[progress.itemId.ToStr()] = true then
            return progress
        end if
    end for

    return invalid
end function

'-------------------------------------------------------------------------------
' getCoverItemId
'-------------------------------------------------------------------------------
function getCoverItemId(item as dynamic) as dynamic
    if item = invalid then return invalid
    if item.id <> invalid then return item.id
    if item.collapsedSeries <> invalid and item.collapsedSeries.libraryItemId <> invalid then return item.collapsedSeries.libraryItemId
    return invalid
end function

'-------------------------------------------------------------------------------
' getProgressCandidateIds
'-------------------------------------------------------------------------------
function getProgressCandidateIds(item as dynamic) as object
    ids = {}
    if item = invalid then return ids

    if item.id <> invalid then ids[item.id.ToStr()] = true
    if item.libraryItemId <> invalid then ids[item.libraryItemId.ToStr()] = true
    if item.mediaItemId <> invalid then ids[item.mediaItemId.ToStr()] = true
    if item.media <> invalid and item.media.id <> invalid then ids[item.media.id.ToStr()] = true

    return ids
end function

'-------------------------------------------------------------------------------
' getPlaybackStartPosition
'-------------------------------------------------------------------------------
function getPlaybackStartPosition(item as dynamic) as integer
    progress = getProgressData(item)
    if progress = invalid then return 0
    if progress.isFinished = true then return 0

    currentTime = int(val(progress.currentTime.ToStr()))
    if currentTime > 0 then return currentTime

    return getDerivedCurrentTime(progress.progress, progress.duration)
end function

'-------------------------------------------------------------------------------
' getDerivedCurrentTime
'-------------------------------------------------------------------------------
function getDerivedCurrentTime(progressValue as dynamic, durationValue as dynamic) as integer
    duration = val(durationValue.ToStr())
    if duration <= 0 then return 0

    progress = val(progressValue.ToStr())
    if progress <= 0 then return 0
    if progress > 1 then progress = progress / 100
    if progress > 1 then progress = 1

    return int(progress * duration)
end function

'-------------------------------------------------------------------------------
' getNumberFromFields
'-------------------------------------------------------------------------------
function getNumberFromFields(value as dynamic, fieldNames as object) as float
    if value = invalid then return 0

    for each fieldName in fieldNames
        fieldValue = value[fieldName]
        if fieldValue <> invalid then return getNumber(fieldValue)
    end for

    return 0
end function

'-------------------------------------------------------------------------------
' getBooleanFromFields
'-------------------------------------------------------------------------------
function getBooleanFromFields(value as dynamic, fieldNames as object) as boolean
    if value = invalid then return false

    for each fieldName in fieldNames
        fieldValue = value[fieldName]
        if fieldValue <> invalid then return getBoolean(fieldValue)
    end for

    return false
end function

'-------------------------------------------------------------------------------
' getNumber
'-------------------------------------------------------------------------------
function getNumber(value as dynamic) as float
    if value = invalid then return 0
    return val(value.ToStr())
end function

'-------------------------------------------------------------------------------
' getBoolean
'-------------------------------------------------------------------------------
function getBoolean(value as dynamic) as boolean
    if value = invalid then return false
    if Type(value) = "Boolean" or Type(value) = "roBoolean" then return value

    text = LCase(value.ToStr())
    return text = "true" or text = "1"
end function

'-------------------------------------------------------------------------------
' updateSelectedDetails
'-------------------------------------------------------------------------------
sub updateSelectedDetails(item as dynamic)
    metadata = ItemMetadataParser_GetMetadata(item)

    setLabelText(m.detailTitle, ItemMetadataParser_GetTitle(item))
    setLabelText(m.detailAuthor, ItemMetadataParser_GetAuthor(metadata))
    setLabelText(m.detailNarrators, ItemMetadataParser_GetNarrators(metadata))
    setLabelText(m.detailPublishDate, ItemMetadataParser_GetPublishYear(metadata))
    setLabelText(m.detailPublisher, FirstNonEmpty([metadata.publisher], "Unknown"))
    setLabelText(m.detailGenres, ItemMetadataParser_GetGenres(metadata))
    setLabelText(m.detailTags, ItemMetadataParser_GetTags(metadata))
    setLabelText(m.detailDuration, ItemMetadataParser_GetDuration(item))
    if m.detailDescription <> invalid then m.detailDescription.title = ItemMetadataParser_GetTitle(item)
    setLabelText(m.detailDescription, ItemMetadataParser_GetDescription(metadata))
end sub

'-------------------------------------------------------------------------------
' updatePrimaryAction
'-------------------------------------------------------------------------------
sub updatePrimaryAction(item as dynamic)
    if m.playButton = invalid then return

    seriesId = getCollapsedSeriesId(item)
    if seriesId <> invalid then
        if isSeriesExpanded(seriesId) then
            m.playButton.text = "Collapse"
        else if m.loadingSeriesId <> invalid and m.loadingSeriesId.ToStr() = seriesId.ToStr() then
            m.playButton.text = "Loading"
        else
            m.playButton.text = "Expand"
        end if
        m.playButton.iconUri = ""
        return
    end if

    m.playButton.text = "Play"
    m.playButton.iconUri = "pkg:/images/icons/dark/play_dark.png"
end sub

' setLabelText
'-------------------------------------------------------------------------------
sub setLabelText(label as dynamic, text as string)
    if label <> invalid then label.text = text
end sub

'-------------------------------------------------------------------------------
' updatePlayButtonFocus
'-------------------------------------------------------------------------------
sub updatePlayButtonFocus(hasFocus as boolean)
    if m.playButton <> invalid then m.playButton.hasFocusVisual = hasFocus
end sub

'-------------------------------------------------------------------------------
' focusLibraryList
'-------------------------------------------------------------------------------
sub focusLibraryList()
    updatePlayButtonFocus(false)
    if m.libraryList <> invalid then m.libraryList.setFocus(true)
end sub

'-------------------------------------------------------------------------------
' focusPlayButton
'-------------------------------------------------------------------------------
sub focusPlayButton()
    updatePlayButtonFocus(true)
    if m.playButton <> invalid then m.playButton.setFocus(true)
end sub

'-------------------------------------------------------------------------------
' focusDescription
'-------------------------------------------------------------------------------
function focusDescription() as boolean
    if m.detailDescription = invalid then return false
    if m.detailDescription.canAcceptFocus <> true then return false

    updatePlayButtonFocus(false)
    m.detailDescription.setFocus(true)
    return true
end function

'-------------------------------------------------------------------------------
' onPlayPressed
'-------------------------------------------------------------------------------
sub onPlayPressed()
    if getCollapsedSeriesId(m.selectedItem) <> invalid then
        toggleSeriesAtCurrentIndex()
        return
    end if

    if m.selectedItem = invalid or m.selectedItem.id = invalid then
        return
    end if

    m.playSelectedCounter = m.playSelectedCounter + 1
    m.top.playSelected = {
        id: m.selectedItem.id
        title: ItemMetadataParser_GetTitle(m.selectedItem)
        details: getPlaybackDetails(m.selectedItem)
        startPositionSeconds: getPlaybackStartPosition(m.selectedItem)
        counter: m.playSelectedCounter
    }
end sub

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

    title = getBookListTitle(item)
    if row.child = true then return "    " + title
    return title
end function

'-------------------------------------------------------------------------------
' getSeriesListTitle
'-------------------------------------------------------------------------------
function getSeriesListTitle(item as dynamic) as string
    title = getCollapsedSeriesTitle(item)
    seriesId = getCollapsedSeriesId(item)

    marker = "[+]"
    if isSeriesExpanded(seriesId) then marker = "[-]"
    if m.loadingSeriesId <> invalid and seriesId <> invalid and m.loadingSeriesId.ToStr() = seriesId.ToStr() then marker = "[...]"

    countText = getCollapsedSeriesCountText(item)
    if countText <> "" then return marker + " " + title + "  " + countText
    return marker + " " + title
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
function getBookListTitle(item as dynamic) as string
    sequence = getSeriesSequence(item)
    title = ItemMetadataParser_GetTitle(item)
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
' getSeriesSequence
'-------------------------------------------------------------------------------
function getSeriesSequence(item as dynamic) as string
    if item = invalid then return ""

    metadata = ItemMetadataParser_GetMetadata(item)
    if metadata.seriesSequence <> invalid then return metadata.seriesSequence.ToStr()
    if metadata.sequence <> invalid then return metadata.sequence.ToStr()
    if metadata.series <> invalid then return getSequenceFromSeriesValue(metadata.series)

    if item.seriesSequence <> invalid then return item.seriesSequence.ToStr()
    if item.sequence <> invalid then return item.sequence.ToStr()

    return ""
end function

'-------------------------------------------------------------------------------
' getSequenceFromSeriesValue
'-------------------------------------------------------------------------------
function getSequenceFromSeriesValue(series as dynamic) as string
    if series = invalid then return ""

    seriesType = Type(series)
    if seriesType = "roArray" then
        if series.Count() = 0 then return ""

        firstSeries = series[0]
        if firstSeries <> invalid then
            if firstSeries.sequence <> invalid then return firstSeries.sequence.ToStr()
            if firstSeries.seriesSequence <> invalid then return firstSeries.seriesSequence.ToStr()
        end if
    else if seriesType = "roAssociativeArray" then
        if series.sequence <> invalid then return series.sequence.ToStr()
        if series.seriesSequence <> invalid then return series.seriesSequence.ToStr()
    end if

    if series.sequence <> invalid then return series.sequence.ToStr()
    if series.seriesSequence <> invalid then return series.seriesSequence.ToStr()

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
    if m.libraryList = invalid then return 0

    currentIndex = m.libraryList.itemFocused
    if currentIndex = invalid or currentIndex < 0 then currentIndex = m.libraryList.itemSelected
    return getValidRowIndex(currentIndex)
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

    loadSeriesRows(seriesId, index)
    return true
end function

'-------------------------------------------------------------------------------
' loadSeriesRows
'-------------------------------------------------------------------------------
sub loadSeriesRows(seriesId as dynamic, sourceIndex as dynamic)
    if seriesId = invalid then return
    if m.seriesApiTask = invalid then return

    m.loadingSeriesId = seriesId
    rebuildLibraryList(sourceIndex)

    m.seriesApiTask.request = {
        action: "loadSeries"
        server: m.server
        token: m.token
        bookLibraryId: m.bookLibraryId
        seriesId: seriesId
        sourceItemIndex: sourceIndex
    }
    m.seriesApiTask.control = "run"
end sub

'-------------------------------------------------------------------------------
' onSeriesApiResponse
'-------------------------------------------------------------------------------
sub onSeriesApiResponse()
    if m.seriesApiTask = invalid then return

    response = m.seriesApiTask.response
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
    if m.libraryItemsByRow = invalid or m.libraryItemsByRow.Count() = 0 then return false

    currentIndex = m.libraryList.itemFocused
    if currentIndex = invalid or currentIndex < 0 then currentIndex = m.libraryList.itemSelected
    if currentIndex = invalid or currentIndex < 0 then currentIndex = 0

    lastIndex = m.libraryItemsByRow.Count() - 1
    if currentIndex > lastIndex then currentIndex = lastIndex

    updatePlayButtonFocus(false)
    m.libraryList.jumpToItem = currentIndex
    showSelectedItem(getSelectedLibraryItem(currentIndex))
    m.libraryList.setFocus(true)

    return true
end function

'-------------------------------------------------------------------------------
' focusFirstLibraryItem
'-------------------------------------------------------------------------------
function focusFirstLibraryItem() as boolean
    if m.libraryList = invalid then return false
    if m.libraryItemsByRow = invalid or m.libraryItemsByRow.Count() = 0 then return false

    currentIndex = m.libraryList.itemFocused
    if currentIndex = invalid or currentIndex < 0 then currentIndex = m.libraryList.itemSelected
    if currentIndex = invalid or currentIndex <= 0 then return false

    updatePlayButtonFocus(false)
    m.libraryList.jumpToItem = 0
    showSelectedItem(getSelectedLibraryItem(0))
    m.libraryList.setFocus(true)

    return true
end function

'-------------------------------------------------------------------------------
' onKeyEvent
'-------------------------------------------------------------------------------
function onKeyEvent(key as string, press as boolean) as boolean
    if press = false then return false

    if key = "back" then
        if m.playButton <> invalid and m.playButton.isInFocusChain() then
            return focusSelectedLibraryItem()
        end if

        if collapseCurrentSeries() then return true
        if focusFirstLibraryItem() then return true
        if requestHeaderFocusFromFirstItem() then return true
    end if

    if m.playButton <> invalid and m.playButton.isInFocusChain() then
        if key = "left" then
            focusLibraryList()
            return true
        else if key = "down" then
            return focusDescription()
        else if key = "OK" or key = "select" then
            onPlayPressed()
            return true
        end if
    end if

    if m.detailDescription <> invalid and m.detailDescription.isInFocusChain() then
        if key = "up" then
            focusPlayButton()
            return true
        end if
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
    for i = currentIndex to 0 step -1
        candidate = getSelectedLibraryRow(i)
        if candidate <> invalid and candidate.type = "series" and candidate.seriesId <> invalid and candidate.seriesId.ToStr() = seriesId.ToStr() then
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

    currentIndex = m.libraryList.itemFocused
    if currentIndex = invalid or currentIndex < 0 then currentIndex = m.libraryList.itemSelected
    if currentIndex = invalid then currentIndex = 0
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
    if m.libraryItemsByRow = invalid or m.libraryItemsByRow.Count() = 0 then return

    currentIndex = m.libraryList.itemFocused
    if currentIndex = invalid or currentIndex < 0 then currentIndex = 0

    nextIndex = currentIndex + offset
    if nextIndex < 0 then nextIndex = 0
    lastIndex = m.libraryItemsByRow.Count() - 1
    if nextIndex > lastIndex then nextIndex = lastIndex

    m.libraryList.jumpToItem = nextIndex
    showSelectedItem(getSelectedLibraryItem(nextIndex))
end sub
