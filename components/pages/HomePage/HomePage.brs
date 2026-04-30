'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.continueListeningGrid = m.top.findNode("continueListeningGrid")
    m.recentlyAddedGrid = m.top.findNode("recentlyAddedGrid")
    m.listenAgainGrid = m.top.findNode("listenAgainGrid")
    m.statusLabel = m.top.findNode("statusLabel")
    m.continueListeningTitle = m.top.findNode("continueListeningTitle")
    m.recentlyAddedTitle = m.top.findNode("recentlyAddedTitle")
    m.listenAgainTitle = m.top.findNode("listenAgainTitle")
    m.continueListeningItemsByIndex = []
    m.recentlyAddedItemsByIndex = []
    m.listenAgainItemsByIndex = []
    m.playSelectedCounter = 0
    m.focusRequested = false
    m.backSelectedCounter = 0

    if m.continueListeningGrid <> invalid then
        m.continueListeningGrid.observeField("itemSelected", "onContinueListeningItemSelected")
    end if

    if m.recentlyAddedGrid <> invalid then
        m.recentlyAddedGrid.observeField("itemSelected", "onRecentlyAddedItemSelected")
    end if

    if m.listenAgainGrid <> invalid then
        m.listenAgainGrid.observeField("itemSelected", "onListenAgainItemSelected")
    end if

    onPersonalizedShelvesChanged()
end sub

'-------------------------------------------------------------------------------
' onPersonalizedShelvesChanged
'-------------------------------------------------------------------------------
sub onPersonalizedShelvesChanged()
    if m.continueListeningGrid = invalid then return

    continueListeningCount = populateShelfGrid("continue-listening", m.continueListeningGrid, m.continueListeningItemsByIndex)
    recentlyAddedCount = populateShelfGrid("recently-added", m.recentlyAddedGrid, m.recentlyAddedItemsByIndex)
    listenAgainCount = populateShelfGrid("listen-again", m.listenAgainGrid, m.listenAgainItemsByIndex)
    updateStatus(continueListeningCount, recentlyAddedCount, listenAgainCount)

    if m.focusRequested = true and m.top.visible = true then focusHomePage()
end sub

'-------------------------------------------------------------------------------
' populateShelfGrid
'-------------------------------------------------------------------------------
function populateShelfGrid(shelfId as string, grid as dynamic, itemsByIndex as object) as integer
    if grid = invalid then return 0

    root = CreateObject("roSGNode", "ContentNode")
    itemsByIndex.Clear()

    shelf = getShelfById(m.top.personalizedShelves, shelfId)
    items = invalid
    if shelf <> invalid then items = shelf.entities

    if items <> invalid then
        for each item in items
            if item <> invalid and item.id <> invalid then
                node = CreateObject("roSGNode", "ContentNode")
                node.title = getLibraryItemTitle(item)
                node.HDPosterUrl = buildCoverPathUrl(item)
                node.SDPosterUrl = node.HDPosterUrl
                progress = getProgressData(item)
                node.AddFields({
                    progressPercent: progress.progress
                    progressCurrentTime: progress.currentTime
                    progressDuration: progress.duration
                })
                root.appendChild(node)
                itemsByIndex.Push(item)
            end if
        end for
    end if

    grid.content = root
    return root.getChildCount()
end function

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
sub updateStatus(continueListeningCount as integer, recentlyAddedCount as integer, listenAgainCount as integer)
    if m.statusLabel = invalid or m.continueListeningGrid = invalid then return

    hasContinueListeningItems = continueListeningCount > 0
    hasRecentlyAddedItems = recentlyAddedCount > 0
    hasListenAgainItems = listenAgainCount > 0
    hasItems = hasContinueListeningItems or hasRecentlyAddedItems or hasListenAgainItems

    m.statusLabel.visible = not hasItems
    if m.continueListeningTitle <> invalid then m.continueListeningTitle.visible = hasContinueListeningItems
    if m.recentlyAddedTitle <> invalid then m.recentlyAddedTitle.visible = hasRecentlyAddedItems
    if m.listenAgainTitle <> invalid then m.listenAgainTitle.visible = hasListenAgainItems
    m.continueListeningGrid.visible = hasContinueListeningItems
    if m.recentlyAddedGrid <> invalid then m.recentlyAddedGrid.visible = hasRecentlyAddedItems
    if m.listenAgainGrid <> invalid then m.listenAgainGrid.visible = hasListenAgainItems

    if hasItems then
        m.statusLabel.text = ""
    else
        m.statusLabel.text = "Nothing in progress"
    end if
end sub

'-------------------------------------------------------------------------------
' focusHomePage
'-------------------------------------------------------------------------------
function focusHomePage() as boolean
    m.focusRequested = true

    if m.continueListeningGrid <> invalid and m.continueListeningGrid.visible = true then
        m.continueListeningGrid.setFocus(true)
        return true
    end if

    if m.recentlyAddedGrid <> invalid and m.recentlyAddedGrid.visible = true then
        m.recentlyAddedGrid.setFocus(true)
        return true
    end if

    if m.listenAgainGrid <> invalid and m.listenAgainGrid.visible = true then
        m.listenAgainGrid.setFocus(true)
        return true
    end if

    m.top.setFocus(true)
    return true
end function

'-------------------------------------------------------------------------------
' onKeyEvent
'-------------------------------------------------------------------------------
function onKeyEvent(key as string, press as boolean) as boolean
    if press = false then return false

    if key = "down" then
        if moveFocusDownFromGrid(m.continueListeningGrid, m.recentlyAddedGrid) then return true
        if moveFocusDownFromGrid(m.recentlyAddedGrid, m.listenAgainGrid) then return true
    end if

    if key = "up" then
        if moveFocusUpFromGrid(m.listenAgainGrid, m.recentlyAddedGrid) then return true
        if moveFocusUpFromGrid(m.recentlyAddedGrid, m.continueListeningGrid) then return true
    end if

    if key <> "back" then return false

    m.backSelectedCounter = m.backSelectedCounter + 1
    m.top.backSelected = m.backSelectedCounter
    return true
end function

'-------------------------------------------------------------------------------
' isNodeFocused
'-------------------------------------------------------------------------------
function isNodeFocused(node as dynamic) as boolean
    return node <> invalid and node.isInFocusChain()
end function

'-------------------------------------------------------------------------------
' moveFocusDownFromGrid
'-------------------------------------------------------------------------------
function moveFocusDownFromGrid(fromGrid as dynamic, toGrid as dynamic) as boolean
    if isNodeFocused(fromGrid) = false then return false
    if toGrid = invalid or toGrid.visible <> true then return false

    toGrid.setFocus(true)
    return true
end function

'-------------------------------------------------------------------------------
' moveFocusUpFromGrid
'-------------------------------------------------------------------------------
function moveFocusUpFromGrid(fromGrid as dynamic, toGrid as dynamic) as boolean
    if isNodeFocused(fromGrid) = false then return false
    if toGrid = invalid or toGrid.visible <> true then return false

    toGrid.setFocus(true)
    return true
end function

'-------------------------------------------------------------------------------
' onContinueListeningItemSelected
'-------------------------------------------------------------------------------
sub onContinueListeningItemSelected()
    item = getSelectedItem(m.continueListeningGrid.itemSelected)
    selectItem(item)
end sub

'-------------------------------------------------------------------------------
' onRecentlyAddedItemSelected
'-------------------------------------------------------------------------------
sub onRecentlyAddedItemSelected()
    item = getSelectedItemFromList(m.recentlyAddedGrid.itemSelected, m.recentlyAddedItemsByIndex)
    selectItem(item)
end sub

'-------------------------------------------------------------------------------
' onListenAgainItemSelected
'-------------------------------------------------------------------------------
sub onListenAgainItemSelected()
    item = getSelectedItemFromList(m.listenAgainGrid.itemSelected, m.listenAgainItemsByIndex)
    selectItem(item)
end sub

'-------------------------------------------------------------------------------
' selectItem
'-------------------------------------------------------------------------------
sub selectItem(item as dynamic)
    if item = invalid or item.id = invalid then return

    m.playSelectedCounter = m.playSelectedCounter + 1
    m.top.playSelected = {
        id: item.id
        title: getLibraryItemTitle(item)
        details: getPlaybackDetails(item)
        counter: m.playSelectedCounter
    }
end sub

'-------------------------------------------------------------------------------
' getSelectedItem
'-------------------------------------------------------------------------------
function getSelectedItem(index as dynamic) as dynamic
    return getSelectedItemFromList(index, m.continueListeningItemsByIndex)
end function

'-------------------------------------------------------------------------------
' getSelectedItemFromList
'-------------------------------------------------------------------------------
function getSelectedItemFromList(index as dynamic, itemsByIndex as object) as dynamic
    if index = invalid then return invalid
    if itemsByIndex = invalid then return invalid
    if index < 0 or index >= itemsByIndex.Count() then return invalid
    return itemsByIndex[index]
end function

'-------------------------------------------------------------------------------
' buildCoverUrl
'-------------------------------------------------------------------------------
function buildCoverUrl(itemId as dynamic) as string
    if itemId = invalid then return "pkg:/images/placeholder_cover.png"
    if m.top.server = invalid or m.top.server = "" then return "pkg:/images/placeholder_cover.png"

    url = m.top.server + "/api/items/" + itemId.ToStr() + "/cover?width=400"
    if m.top.token <> invalid and m.top.token <> "" then url = url + "&token=" + m.top.token
    return url
end function

'-------------------------------------------------------------------------------
' buildCoverPathUrl
'-------------------------------------------------------------------------------
function buildCoverPathUrl(item as dynamic) as string
    if item = invalid then return "pkg:/images/placeholder_cover.png"
    coverPath = SafeString(item.coverPath, "")
    if coverPath = "" then return buildCoverUrl(item.id)
    if Left(coverPath, 4) = "http" then return coverPath
    if m.top.server = invalid or m.top.server = "" then return "pkg:/images/placeholder_cover.png"

    path = coverPath
    if Left(path, 1) <> "/" then path = "/" + path

    url = m.top.server + path
    if m.top.token <> invalid and m.top.token <> "" then
        separator = "?"
        if Instr(1, url, "?") > 0 then separator = "&"
        url = url + separator + "token=" + m.top.token
    end if

    return url
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
        }
    end if

    return {
        progress: getNumberFromFields(progress, ["progress"])
        currentTime: getNumberFromFields(progress, ["currentTime"])
        duration: getNumberFromFields(progress, ["duration"])
    }
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
' getNumber
'-------------------------------------------------------------------------------
function getNumber(value as dynamic) as float
    if value = invalid then return 0
    return val(value.ToStr())
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
