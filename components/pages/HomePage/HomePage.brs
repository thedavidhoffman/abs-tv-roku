'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.homeRowList = m.top.findNode("homeRowList")
    m.focusRetryTimer = m.top.findNode("focusRetryTimer")
    m.personalizedApiTask = m.top.findNode("personalizedApiTask")
    m.shelfItemsByRow = []
    m.playSelectedCounter = 0
    m.firstItemFocusPending = false
    m.focusRetryCount = 0
    m.focusRetryMax = 12
    m.backSelectedCounter = 0
    m.upFromFirstRowSelectedCounter = 0
    m.focusedItemNode = invalid
    m.loadRequest = invalid
    m.server = invalid
    m.token = invalid

    if m.homeRowList <> invalid then
        m.homeRowList.observeField("itemSelected", "onItemSelected")
        m.homeRowList.observeField("rowItemFocused", "onRowItemFocused")
    end if

    if m.personalizedApiTask <> invalid then
        m.personalizedApiTask.observeField("response", "onPersonalizedApiResponse")
    end if
    if m.focusRetryTimer <> invalid then m.focusRetryTimer.observeField("fire", "onFocusRetryTimerFired")

    onPersonalizedShelvesChanged()
end sub

'-------------------------------------------------------------------------------
' onLoadRequestChanged
'-------------------------------------------------------------------------------
sub onLoadRequestChanged()
    m.loadRequest = m.top.loadRequest
    if m.loadRequest <> invalid then
        m.server = m.loadRequest.server
        m.token = m.loadRequest.token
    end if

    reloadPersonalizedShelves()
end sub

'-------------------------------------------------------------------------------
' reloadPersonalizedShelves
'-------------------------------------------------------------------------------
sub reloadPersonalizedShelves()
    if hasValidLoadRequest() = false then return

    if m.top.visible = true then m.firstItemFocusPending = true
    setStatus("Loading...")
    runPersonalizedApiRequest({
        action: "loadPersonalized"
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
    if m.personalizedApiTask = invalid then return false

    return true
end function

'-------------------------------------------------------------------------------
' runPersonalizedApiRequest
'-------------------------------------------------------------------------------
sub runPersonalizedApiRequest(request as object)
    if m.personalizedApiTask = invalid then return

    m.personalizedApiTask.request = request
    m.personalizedApiTask.control = "run"
end sub

'-------------------------------------------------------------------------------
' onPersonalizedApiResponse
'-------------------------------------------------------------------------------
sub onPersonalizedApiResponse()
    response = m.personalizedApiTask.response
    if response = invalid then return

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
    if m.homeRowList = invalid then return

    root = CreateObject("roSGNode", "ContentNode")
    m.shelfItemsByRow = []
    m.focusedItemNode = invalid

    appendShelfRow(root, "continue-listening", "Continue Listening")
    appendShelfRow(root, "recently-added", "Recently Added")
    appendShelfRow(root, "listen-again", "Listen Again")

    m.homeRowList.content = root
    updateStatus(root.getChildCount())

    if m.firstItemFocusPending = true and m.top.visible = true then requestFirstHomeItemFocus()
end sub

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
            node.HDPosterUrl = Cover_BuildUrl(m.server, m.token, item.id, 280)
            node.SDPosterUrl = node.HDPosterUrl
            progress = getProgressData(item)
            metadata = getItemMetadata(item)
            node.AddFields({
                author: getItemAuthor(metadata)
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
    m.shelfItemsByRow.Push(itemsByIndex)
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
    else
        m.top.statusMessage = "Loading..."
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
end sub

'-------------------------------------------------------------------------------
' focusHomePage
'-------------------------------------------------------------------------------
function focusHomePage() as boolean
    m.firstItemFocusPending = true

    if m.homeRowList <> invalid and m.homeRowList.visible = true then
        requestFirstHomeItemFocus()
        return true
    end if

    m.top.setFocus(true)
    return true
end function

'-------------------------------------------------------------------------------
' requestFirstHomeItemFocus
'-------------------------------------------------------------------------------
sub requestFirstHomeItemFocus()
    m.firstItemFocusPending = true
    applyFirstHomeItemFocus()

    if m.focusRetryTimer = invalid then return
    m.focusRetryCount = 0
    m.focusRetryTimer.control = "stop"
    m.focusRetryTimer.control = "start"
end sub

'-------------------------------------------------------------------------------
' onFocusRetryTimerFired
'-------------------------------------------------------------------------------
sub onFocusRetryTimerFired()
    if m.focusRetryTimer = invalid then return
    if m.firstItemFocusPending <> true or m.top.visible <> true or m.homeRowList = invalid or m.homeRowList.visible <> true then
        finishFirstHomeItemFocus()
        return
    end if

    applyFirstHomeItemFocus()
    m.focusRetryCount = m.focusRetryCount + 1

    if isFocusedOnHomeItem(0, 0) and m.homeRowList.isInFocusChain() then
        finishFirstHomeItemFocus()
    else if m.focusRetryCount >= m.focusRetryMax then
        finishFirstHomeItemFocus()
    end if
end sub

'-------------------------------------------------------------------------------
' finishFirstHomeItemFocus
'-------------------------------------------------------------------------------
sub finishFirstHomeItemFocus()
    m.firstItemFocusPending = false
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

    if key = "up" and isFocusedOnFirstRow() then
        finishFirstHomeItemFocus()
        m.upFromFirstRowSelectedCounter = m.upFromFirstRowSelectedCounter + 1
        m.top.upFromFirstRowSelected = m.upFromFirstRowSelectedCounter
        return true
    end if

    if key <> "back" then return false

    finishFirstHomeItemFocus()
    m.backSelectedCounter = m.backSelectedCounter + 1
    m.top.backSelected = m.backSelectedCounter
    return true
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
' onRowItemFocused
'-------------------------------------------------------------------------------
sub onRowItemFocused()
    setFocusedItemNode(getFocusedItemNode())
end sub

'-------------------------------------------------------------------------------
' setFocusedItemNode
'-------------------------------------------------------------------------------
sub setFocusedItemNode(itemNode as dynamic)
    if m.focusedItemNode <> invalid then m.focusedItemNode.focused = false

    m.focusedItemNode = itemNode
    if m.focusedItemNode <> invalid then m.focusedItemNode.focused = true
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
    if m.shelfItemsByRow = invalid then return invalid

    selected = m.homeRowList.rowItemSelected
    if selected = invalid or selected.Count() < 2 then return invalid

    rowIndex = selected[0]
    itemIndex = selected[1]
    if rowIndex = invalid or itemIndex = invalid then return invalid
    if rowIndex < 0 or rowIndex >= m.shelfItemsByRow.Count() then return invalid

    itemsByIndex = m.shelfItemsByRow[rowIndex]
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
