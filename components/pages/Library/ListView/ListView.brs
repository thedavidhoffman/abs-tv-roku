'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    initReferences()

    m.libraryItemsByRow = []
    m.selectedItem = invalid
    m.playSelectedCounter = 0
    m.upFromFirstItemSelectedCounter = 0
    m.server = invalid
    m.token = invalid

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
    m.libraryStatus = m.top.findNode("libraryStatus")
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
end sub

'-------------------------------------------------------------------------------
' initHandlers
'-------------------------------------------------------------------------------
sub initHandlers()
    if m.libraryList <> invalid then
        m.libraryList.observeField("itemFocused", "onLibraryItemFocused")
        m.libraryList.observeField("itemSelected", "onLibraryItemSelected")
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
end sub

'-------------------------------------------------------------------------------
' onLibraryItemsChanged
'-------------------------------------------------------------------------------
sub onLibraryItemsChanged()
    if m.libraryList = invalid then return

    root = CreateObject("roSGNode", "ContentNode")
    items = m.top.libraryItems
    m.libraryItemsByRow = []

    if items <> invalid then
        for each item in items
            if item.mediaType = invalid or item.mediaType = "book" then
                node = CreateObject("roSGNode", "ContentNode")
                node.title = getLibraryItemTitle(item)
                root.appendChild(node)
                m.libraryItemsByRow.Push(item)
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
        showSelectedItem(m.libraryItemsByRow[0])
        if m.top.visible then m.libraryList.setFocus(true)
    else
        showSelectedItem(invalid)
    end if
end sub

'-------------------------------------------------------------------------------
' onLibraryItemFocused
'-------------------------------------------------------------------------------
sub onLibraryItemFocused()
    showSelectedItem(getSelectedLibraryItem(m.libraryList.itemFocused))
end sub

'-------------------------------------------------------------------------------
' onLibraryItemSelected
'-------------------------------------------------------------------------------
sub onLibraryItemSelected()
    showSelectedItem(getSelectedLibraryItem(m.libraryList.itemSelected))
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
' showSelectedItem
'-------------------------------------------------------------------------------
sub showSelectedItem(item as dynamic)
    m.selectedItem = item
    if m.selectedPoster <> invalid then m.selectedPoster.itemContent = getSelectedPosterContent(item)
    updateSelectedDetails(item)
end sub

'-------------------------------------------------------------------------------
' getSelectedPosterContent
'-------------------------------------------------------------------------------
function getSelectedPosterContent(item as dynamic) as dynamic
    if item = invalid then return invalid

    progress = getProgressData(item)
    node = CreateObject("roSGNode", "ContentNode")
    node.title = getLibraryItemTitle(item)
    node.HDPosterUrl = Cover_BuildUrl(m.server, m.token, item.id, 600)
    node.SDPosterUrl = node.HDPosterUrl
    node.AddFields({
        author: getItemAuthor(getItemMetadata(item))
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
    metadata = getItemMetadata(item)

    setLabelText(m.detailTitle, getLibraryItemTitle(item))
    setLabelText(m.detailAuthor, getItemAuthor(metadata))
    setLabelText(m.detailNarrators, getItemNarrators(metadata))
    setLabelText(m.detailPublishDate, getItemPublishYear(metadata))
    setLabelText(m.detailPublisher, FirstNonEmpty([metadata.publisher], "Unknown"))
    setLabelText(m.detailGenres, getItemGenres(metadata))
    setLabelText(m.detailTags, getItemTags(metadata))
    setLabelText(m.detailDuration, getItemDuration(item))
    setLabelText(m.detailDescription, getItemDescription(metadata))
end sub

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
' getItemPublishDate
'-------------------------------------------------------------------------------
function getItemPublishDate(metadata as dynamic) as string
    return FirstNonEmpty([metadata.publishedYear, metadata.publishedDate, metadata.releaseDate], "Unknown")
end function

'-------------------------------------------------------------------------------
' getItemPublishYear
'-------------------------------------------------------------------------------
function getItemPublishYear(metadata as dynamic) as string
    year = FirstNonEmpty([metadata.publishedYear], "")
    if year <> "" then return year

    publishedDate = FirstNonEmpty([metadata.publishedDate, metadata.releaseDate], "")
    if Len(publishedDate) >= 4 then
        possibleYear = Left(publishedDate, 4)
        if isYearText(possibleYear) then return possibleYear
    end if

    return "Unknown"
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
' getItemGenres
'-------------------------------------------------------------------------------
function getItemGenres(metadata as dynamic) as string
    genres = getJoinedText(metadata.genres)
    if genres <> "" then return genres

    categories = getJoinedText(metadata.categories)
    if categories <> "" then return categories

    return FirstNonEmpty([metadata.genre, metadata.category], "Unknown")
end function

'-------------------------------------------------------------------------------
' getItemTags
'-------------------------------------------------------------------------------
function getItemTags(metadata as dynamic) as string
    tags = getJoinedText(metadata.tags)
    if tags <> "" then return tags
    return FirstNonEmpty([metadata.tag, metadata.keywords], "None")
end function

'-------------------------------------------------------------------------------
' isYearText
'-------------------------------------------------------------------------------
function isYearText(value as string) as boolean
    if Len(value) <> 4 then return false
    year = int(val(value))
    if year < 1000 or year > 9999 then return false
    return value = year.ToStr()
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
' onPlayPressed
'-------------------------------------------------------------------------------
sub onPlayPressed()
    if m.selectedItem = invalid or m.selectedItem.id = invalid then
        setStatus("Select an audiobook to play.")
        return
    end if

    m.playSelectedCounter = m.playSelectedCounter + 1
    m.top.playSelected = {
        id: m.selectedItem.id
        title: getLibraryItemTitle(m.selectedItem)
        details: getPlaybackDetails(m.selectedItem)
        startPositionSeconds: getPlaybackStartPosition(m.selectedItem)
        counter: m.playSelectedCounter
    }
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

        if focusFirstLibraryItem() then return true
        if requestHeaderFocusFromFirstItem() then return true
    end if

    if m.playButton <> invalid and m.playButton.isInFocusChain() then
        if key = "left" then
            focusLibraryList()
            return true
        else if key = "OK" or key = "select" then
            onPlayPressed()
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
            focusPlayButton()
            return true
        end if
    end if

    return false
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

'-------------------------------------------------------------------------------
' setStatus
'-------------------------------------------------------------------------------
sub setStatus(message as dynamic)
    if m.libraryStatus = invalid then return
    m.libraryStatus.text = SafeString(message, "")
end sub

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
