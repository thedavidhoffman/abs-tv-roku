'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.markupGrid = m.top.findNode("markupGrid")
    m.gridStatus = m.top.findNode("gridStatus")
    m.libraryItemsByIndex = []
    m.playSelectedCounter = 0
    m.seriesSelectedCounter = 0
    m.upFromFirstItemSelectedCounter = 0
    m.backFromFirstItemSelectedCounter = 0
    m.focusedItemNode = invalid
    m.server = invalid
    m.token = invalid

    if m.markupGrid <> invalid then
        m.markupGrid.observeField("itemSelected", "onPosterSelected")
        m.markupGrid.observeField("itemFocused", "onItemFocused")
    end if

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
                progress = getProgressData(item)
                node.AddFields({
                    author: getItemAuthor(metadata)
                    isSeriesItem: isSeriesItem(item)
                    collapsedSeries: item.collapsedSeries
                    seriesSequence: getSeriesSequence(item)
                    showProgressBar: not isSeriesItem(item)
                    progressPercent: progress.progress
                    progressCurrentTime: progress.currentTime
                    progressDuration: progress.duration
                    progressIsFinished: progress.isFinished
                })
                root.appendChild(node)
                m.libraryItemsByIndex.Push(item)
            end if
        end for
    end if

    m.markupGrid.content = root
    setStatus("")

    if m.libraryItemsByIndex.Count() = 0 then
        setStatus("No titles found")
    end if
end sub

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
            title: getLibraryItemTitle(item)
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
        counter: m.playSelectedCounter
    }
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
' getSeriesSequence
'-------------------------------------------------------------------------------
function getSeriesSequence(item as dynamic) as string
    if item = invalid then return ""

    metadata = getItemMetadata(item)
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
    if item = invalid or item.id = invalid then return invalid
    if m.top.mediaProgress = invalid then return invalid

    itemId = item.id.ToStr()
    for each progress in m.top.mediaProgress
        if progress <> invalid and progress.itemId <> invalid and progress.itemId.ToStr() = itemId then
            return progress
        end if
    end for

    return invalid
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
' focusLibraryList
'-------------------------------------------------------------------------------
sub focusLibraryList()
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
    if getValidItemIndex(m.markupGrid.itemFocused) > 0 then return false

    if key = "back" then
        m.backFromFirstItemSelectedCounter = m.backFromFirstItemSelectedCounter + 1
        m.top.backFromFirstItemSelected = m.backFromFirstItemSelectedCounter
        return true
    end if

    m.upFromFirstItemSelectedCounter = m.upFromFirstItemSelectedCounter + 1
    m.top.upFromFirstItemSelected = m.upFromFirstItemSelectedCounter
    return true
end function

'-------------------------------------------------------------------------------
' setStatus
'-------------------------------------------------------------------------------
sub setStatus(message as dynamic)
    if m.gridStatus = invalid then return
    text = SafeString(message, "")
    m.gridStatus.text = text
    m.gridStatus.visible = (text <> "")
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
    category = getJoinedText(metadata.genres)
    if category <> "" then return category

    category = getJoinedText(metadata.categories)
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

    text = TrimString(fallbackText)
    if text = "" or text = "Unknown" then return 0
    if Instr(1, text, ",") > 0 or Instr(1, text, " and ") > 0 or Instr(1, text, " & ") > 0 then return 2
    return 1
end function

'-------------------------------------------------------------------------------
' getJoinedText
'-------------------------------------------------------------------------------
function getJoinedText(values as dynamic) as string
    if values = invalid then return ""

    if Type(values) <> "roArray" and Type(values) <> "roAssociativeArray" then
        return TrimString(values.ToStr())
    end if

    result = ""
    for each value in values
        text = TrimString(value.ToStr())
        if text <> "" then
            if result <> "" then result = result + ", "
            result = result + text
        end if
    end for

    return result
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

    return TrimString(result)
end function
