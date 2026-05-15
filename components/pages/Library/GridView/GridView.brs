'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.markupGrid = m.top.findNode("markupGrid")
    m.contextTitleLabel = m.top.findNode("contextTitleLabel")
    m.contextHintLabel = m.top.findNode("contextHintLabel")
    m.libraryItemsByIndex = []
    m.playSelectedCounter = 0
    m.seriesSelectedCounter = 0
    m.upFromFirstItemSelectedCounter = 0
    m.backFromFirstItemSelectedCounter = 0
    m.focusedItemNode = invalid
    m.allLibraryItemLookup = {}
    m.server = invalid
    m.token = invalid

    if m.markupGrid <> invalid then
        m.markupGrid.observeField("itemSelected", "onPosterSelected")
        m.markupGrid.observeField("itemFocused", "onItemFocused")
    end if

    onLibraryItemsChanged()
    onContextTitleChanged()
end sub

'-------------------------------------------------------------------------------
' onAllLibraryItemsChanged
'-------------------------------------------------------------------------------
sub onAllLibraryItemsChanged()
    m.allLibraryItemLookup = LibraryItemLookup_Build(m.top.allLibraryItems)
    onLibraryItemsChanged()
end sub

'-------------------------------------------------------------------------------
' onLoadRequestChanged
'-------------------------------------------------------------------------------
sub onLoadRequestChanged()
    request = m.top.loadRequest
    if request = invalid then return

    m.server = request.server
    m.token = request.token
    onLibraryItemsChanged()
end sub

'-------------------------------------------------------------------------------
' onLibraryItemsChanged
'-------------------------------------------------------------------------------
sub onLibraryItemsChanged()
    if m.markupGrid = invalid then return

    root = CreateObject("roSGNode", "ContentNode")
    items = m.top.libraryItems
    m.libraryItemsByIndex = []
    m.focusedItemNode = invalid

    if items <> invalid then
        for each item in items
            if item.mediaType = invalid or item.mediaType = "book" then
                metadata = getItemMetadata(item)
                node = CreateObject("roSGNode", "ContentNode")
                node.title = getLibraryItemTitle(item)
                node.HDPosterUrl = Cover_BuildUrl(m.server, m.token, item.id, 280)
                node.SDPosterUrl = node.HDPosterUrl
                progress = getPosterProgressData(item)
                node.AddFields({
                    author: getItemAuthor(metadata)
                    isSeriesItem: isSeriesItem(item)
                    collapsedSeries: item.collapsedSeries
                    seriesSequence: getSeriesSequence(item)
                    showSeriesSequence: shouldShowSeriesSequence()
                    progressPercent: progress.progress
                    progressCurrentTime: progress.currentTime
                    progressDuration: progress.duration
                    progressIsFinished: progress.isFinished
                    focused: false
                })
                root.appendChild(node)
                m.libraryItemsByIndex.Push(item)
            end if
        end for
    end if

    m.markupGrid.content = root
    setStatus("")

    if m.libraryItemsByIndex.Count() = 0 then
        if m.top.loading = true then
            setStatus("Loading...")
        else
            setStatus("No titles found")
        end if
    end if
end sub

'-------------------------------------------------------------------------------
' shouldShowSeriesSequence
'-------------------------------------------------------------------------------
function shouldShowSeriesSequence() as boolean
    return m.top.contextType = "series"
end function

'-------------------------------------------------------------------------------
' onPosterSelected
'-------------------------------------------------------------------------------
sub onPosterSelected()
    item = getSelectedLibraryItem(m.markupGrid.itemSelected)
    if item = invalid then
        setStatus("Select an audiobook to play.")
        return
    end if

    seriesId = getCollapsedSeriesId(item)
    if seriesId <> invalid then
        m.seriesSelectedCounter = m.seriesSelectedCounter + 1
        m.top.seriesSelected = {
            seriesId: seriesId
            title: getCollapsedSeriesTitle(item)
            libraryItemIds: getCollapsedSeriesLibraryItemIds(item)
            itemIndex: m.markupGrid.itemSelected
            counter: m.seriesSelectedCounter
        }
        return
    end if

    if item.id = invalid then
        setStatus("Select an audiobook to play.")
        return
    end if

    m.playSelectedCounter = m.playSelectedCounter + 1
    m.top.playSelected = {
        id: item.id
        title: getLibraryItemTitle(item)
        details: getPlaybackDetails(item)
        startPositionSeconds: getPlaybackStartPosition(item)
        counter: m.playSelectedCounter
    }
end sub

'-------------------------------------------------------------------------------
' onContextTitleChanged
'-------------------------------------------------------------------------------
sub onContextTitleChanged()
    title = String_Trim(m.top.contextTitle)
    hasTitle = (title <> "")

    if m.contextTitleLabel <> invalid then
        m.contextTitleLabel.text = title
        m.contextTitleLabel.visible = hasTitle
    end if

    if m.contextHintLabel <> invalid then m.contextHintLabel.visible = hasTitle

    if m.markupGrid <> invalid then
        if hasTitle then
            m.markupGrid.translation = [64,240]
        else
            m.markupGrid.translation = [64,135]
        end if
    end if

end sub

'-------------------------------------------------------------------------------
' onItemFocused
'-------------------------------------------------------------------------------
sub onItemFocused()
    if m.focusedItemNode <> invalid then m.focusedItemNode.focused = false

    m.focusedItemNode = getFocusedItemNode()
    if m.focusedItemNode <> invalid then m.focusedItemNode.focused = true
end sub

'-------------------------------------------------------------------------------
' getFocusedItemNode
'-------------------------------------------------------------------------------
function getFocusedItemNode() as dynamic
    if m.markupGrid = invalid or m.markupGrid.content = invalid then return invalid

    itemIndex = m.markupGrid.itemFocused
    if itemIndex = invalid or itemIndex < 0 then return invalid
    if itemIndex >= m.markupGrid.content.getChildCount() then return invalid

    return m.markupGrid.content.getChild(itemIndex)
end function

'-------------------------------------------------------------------------------
' getSelectedLibraryItem
'-------------------------------------------------------------------------------
function getSelectedLibraryItem(index as dynamic) as dynamic
    if index = invalid then return invalid
    if m.libraryItemsByIndex = invalid then return invalid
    if index < 0 or index >= m.libraryItemsByIndex.Count() then return invalid
    return m.libraryItemsByIndex[index]
end function

'-------------------------------------------------------------------------------
' isSeriesItem
'-------------------------------------------------------------------------------
function isSeriesItem(item as dynamic) as boolean
    if item = invalid then return false
    return item.collapsedSeries <> invalid
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
' getCollapsedSeriesTitle
'-------------------------------------------------------------------------------
function getCollapsedSeriesTitle(item as dynamic) as string
    if item = invalid or item.collapsedSeries = invalid then return getLibraryItemTitle(item)

    collapsedSeries = item.collapsedSeries
    return FirstNonEmpty([
        collapsedSeries.nameIgnorePrefix
        collapsedSeries.name
        collapsedSeries.title
        getLibraryItemTitle(item)
    ], "Untitled")
end function

'-------------------------------------------------------------------------------
' getSeriesSequence
'-------------------------------------------------------------------------------
function getSeriesSequence(item as dynamic) as string
    if item = invalid then return ""

    metadata = getItemMetadata(item)
    if metadata.seriesSequence <> invalid then return metadata.seriesSequence.ToStr()
    if metadata.sequence <> invalid then return metadata.sequence.ToStr()
    if metadata.series <> invalid then
        sequence = getSequenceFromSeriesValue(metadata.series)
        if sequence <> "" then return sequence
    end if

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

    return ""
end function

'-------------------------------------------------------------------------------
' getPosterProgressData
'-------------------------------------------------------------------------------
function getPosterProgressData(item as dynamic) as object
    if isSeriesItem(item) then return SeriesProgress_GetProgress(item, m.allLibraryItemLookup, m.top.mediaProgress)
    return ProgressData_GetItemProgress(item, m.top.mediaProgress)
end function

'-------------------------------------------------------------------------------
' getPlaybackStartPosition
'-------------------------------------------------------------------------------
function getPlaybackStartPosition(item as dynamic) as integer
    return ProgressData_GetPlaybackStartPosition(item, m.top.mediaProgress)
end function

'-------------------------------------------------------------------------------
' focusLibraryList
'-------------------------------------------------------------------------------
sub focusLibraryList()
    if SafeString(m.top.statusMessage, "") <> "" then return
    if m.markupGrid <> invalid then m.markupGrid.setFocus(true)
end sub

'-------------------------------------------------------------------------------
' focusItemAtIndex
'-------------------------------------------------------------------------------
sub focusItemAtIndex(index as dynamic)
    if m.markupGrid = invalid then return

    itemIndex = getValidItemIndex(index)
    m.markupGrid.jumpToItem = itemIndex
    m.markupGrid.setFocus(true)
end sub

'-------------------------------------------------------------------------------
' moveFocusToFirstItem
'-------------------------------------------------------------------------------
function moveFocusToFirstItem() as boolean
    if m.markupGrid = invalid then return false
    if m.markupGrid.isInFocusChain() = false then return false

    currentIndex = getValidItemIndex(m.markupGrid.itemFocused)
    if currentIndex <= 0 then return false

    m.markupGrid.jumpToItem = 0
    m.markupGrid.setFocus(true)
    return true
end function

'-------------------------------------------------------------------------------
' getValidItemIndex
'-------------------------------------------------------------------------------
function getValidItemIndex(index as dynamic) as integer
    if index = invalid or index < 0 then return 0
    if m.libraryItemsByIndex = invalid or m.libraryItemsByIndex.Count() = 0 then return 0
    if index >= m.libraryItemsByIndex.Count() then return m.libraryItemsByIndex.Count() - 1
    return index
end function

'-------------------------------------------------------------------------------
' onKeyEvent
'-------------------------------------------------------------------------------
function onKeyEvent(key as string, press as boolean) as boolean
    if press = false then return false
    if key <> "up" and key <> "back" then return false
    if m.markupGrid = invalid then return false
    if m.markupGrid.isInFocusChain() = false then return false

    itemIndex = getValidItemIndex(m.markupGrid.itemFocused)

    if key = "back" then
        if itemIndex > 0 then
            m.markupGrid.jumpToItem = 0
            m.markupGrid.setFocus(true)
            return true
        end if

        m.backFromFirstItemSelectedCounter = m.backFromFirstItemSelectedCounter + 1
        m.top.backFromFirstItemSelected = m.backFromFirstItemSelectedCounter
        return true
    end if

    if isIndexInFirstRow(itemIndex) = false then return false

    m.upFromFirstItemSelectedCounter = m.upFromFirstItemSelectedCounter + 1
    m.top.upFromFirstItemSelected = m.upFromFirstItemSelectedCounter
    return true
end function

'-------------------------------------------------------------------------------
' isIndexInFirstRow
'-------------------------------------------------------------------------------
function isIndexInFirstRow(index as integer) as boolean
    columnCount = 1
    if m.markupGrid <> invalid and m.markupGrid.numColumns <> invalid and m.markupGrid.numColumns > 0 then
        columnCount = m.markupGrid.numColumns
    end if

    return index >= 0 and index < columnCount
end function

'-------------------------------------------------------------------------------
' setStatus
'-------------------------------------------------------------------------------
sub setStatus(message as dynamic)
    m.top.statusMessage = SafeString(message, "")
end sub

'-------------------------------------------------------------------------------
' getPlaybackDetails
'-------------------------------------------------------------------------------
function getPlaybackDetails(item as dynamic) as object
    metadata = getItemMetadata(item)
    return {
        authors: getItemAuthor(metadata)
        authorCount: getNameCount(metadata.authors, getItemAuthor(metadata))
        narrators: getItemNarrators(metadata)
        narratorCount: getNameCount(metadata.narrators, getItemNarrators(metadata))
        description: getItemDescription(metadata)
        publisher: FirstNonEmpty([metadata.publisher], "Unknown")
        publishDate: getItemPublishDate(metadata)
        category: getItemCategory(metadata)
        duration: getItemDuration(item)
        durationSeconds: getItemDurationSeconds(item)
    }
end function

'-------------------------------------------------------------------------------
' getItemMetadata
'-------------------------------------------------------------------------------
function getItemMetadata(item as dynamic) as dynamic
    if item <> invalid and item.media <> invalid and item.media.metadata <> invalid then
        return item.media.metadata
    end if

    return {}
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
' getItemAuthor
'-------------------------------------------------------------------------------
function getItemAuthor(metadata as dynamic) as string
    return FirstNonEmpty([metadata.authorName, metadata.author], "Unknown")
end function

'-------------------------------------------------------------------------------
' getItemNarrators
'-------------------------------------------------------------------------------
function getItemNarrators(metadata as dynamic) as string
    return FirstNonEmpty([metadata.narratorName, metadata.narrator], "Unknown")
end function

'-------------------------------------------------------------------------------
' getItemDescription
'-------------------------------------------------------------------------------
function getItemDescription(metadata as dynamic) as string
    return StripHtmlMarkup(FirstNonEmpty([metadata.description, metadata.subtitle], "No description available."))
end function

'-------------------------------------------------------------------------------
' getItemPublishDate
'-------------------------------------------------------------------------------
function getItemPublishDate(metadata as dynamic) as string
    return FirstNonEmpty([metadata.publishedYear, metadata.publishedDate, metadata.releaseDate], "Unknown")
end function

'-------------------------------------------------------------------------------
' getItemCategory
'-------------------------------------------------------------------------------
function getItemCategory(metadata as dynamic) as string
    category = String_GetJoinedText(metadata.genres)
    if category <> "" then return category

    category = String_GetJoinedText(metadata.categories)
    if category <> "" then return category

    return FirstNonEmpty([metadata.genre, metadata.category], "")
end function

'-------------------------------------------------------------------------------
' getItemDuration
'-------------------------------------------------------------------------------
function getItemDuration(item as dynamic) as string
    totalSeconds = getItemDurationSeconds(item)
    if totalSeconds <= 0 then return "Unknown"

    hours = int(totalSeconds / 3600)
    minutes = int((totalSeconds mod 3600) / 60)

    if hours > 0 and minutes > 0 then return hours.ToStr() + " hr " + minutes.ToStr() + " min"
    if hours > 0 then return hours.ToStr() + " hr"
    if minutes > 0 then return minutes.ToStr() + " min"
    return "Less than 1 min"
end function

'-------------------------------------------------------------------------------
' getItemDurationSeconds
'-------------------------------------------------------------------------------
function getItemDurationSeconds(item as dynamic) as integer
    duration = invalid
    if item <> invalid and item.media <> invalid then duration = item.media.duration
    if duration = invalid and item <> invalid then duration = item.duration
    if duration = invalid then return 0

    return int(val(duration.ToStr()))
end function

'-------------------------------------------------------------------------------
' getNameCount
'-------------------------------------------------------------------------------
function getNameCount(values as dynamic, fallbackText as string) as integer
    if values <> invalid then
        if Type(values) = "roArray" then return values.Count()
        if Type(values) = "roAssociativeArray" then return values.Count()
    end if

    text = String_Trim(fallbackText)
    if text = "" or text = "Unknown" then return 0
    if Instr(1, text, ",") > 0 or Instr(1, text, " and ") > 0 or Instr(1, text, " & ") > 0 then return 2
    return 1
end function

'-------------------------------------------------------------------------------
' StripHtmlMarkup
'-------------------------------------------------------------------------------
function StripHtmlMarkup(value as dynamic) as string
    text = SafeString(value, "")
    text = ReplaceText(text, "</p> <p>", Chr(10))
    text = ReplaceText(text, "</p><p>", Chr(10))
    result = ""
    insideTag = false

    for i = 1 to Len(text)
        char = Mid(text, i, 1)
        if char = "<" then
            insideTag = true
        else if char = ">" then
            insideTag = false
            result = result + " "
        else if insideTag = false then
            result = result + char
        end if
    end for

    result = ReplaceText(result, "&nbsp;", " ")
    result = ReplaceText(result, "&amp;", "&")
    result = ReplaceText(result, "&quot;", Chr(34))
    result = ReplaceText(result, "&#39;", "'")
    result = ReplaceText(result, "&apos;", "'")
    result = ReplaceText(result, "&lt;", "<")
    result = ReplaceText(result, "&gt;", ">")

    return CollapseWhitespace(result)
end function

'-------------------------------------------------------------------------------
' ReplaceText
'-------------------------------------------------------------------------------
function ReplaceText(value as string, oldValue as string, newValue as string) as string
    result = ""
    remaining = value
    index = Instr(1, remaining, oldValue)

    while index > 0
        result = result + Left(remaining, index - 1) + newValue
        remaining = Mid(remaining, index + Len(oldValue))
        index = Instr(1, remaining, oldValue)
    end while

    return result + remaining
end function

'-------------------------------------------------------------------------------
' CollapseWhitespace
'-------------------------------------------------------------------------------
function CollapseWhitespace(value as string) as string
    result = ""
    previousWasSpace = false

    for i = 1 to Len(value)
        char = Mid(value, i, 1)
        isSpace = (char = " " or char = Chr(10) or char = Chr(13) or char = Chr(9))

        if isSpace then
            if previousWasSpace = false then result = result + " "
            previousWasSpace = true
        else
            result = result + char
            previousWasSpace = false
        end if
    end for

    return String_Trim(result)
end function
