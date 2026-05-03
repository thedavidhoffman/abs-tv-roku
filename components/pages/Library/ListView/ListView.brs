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
                node.title = LibraryItemMetadata_GetTitle(item)
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
    node.title = LibraryItemMetadata_GetTitle(item)
    node.HDPosterUrl = Cover_BuildUrl(m.server, m.token, item.id, 600)
    node.SDPosterUrl = node.HDPosterUrl
    node.AddFields({
        author: LibraryItemMetadata_GetAuthor(LibraryItemMetadata_GetMetadata(item))
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
    metadata = LibraryItemMetadata_GetMetadata(item)

    setLabelText(m.detailTitle, LibraryItemMetadata_GetTitle(item))
    setLabelText(m.detailAuthor, LibraryItemMetadata_GetAuthor(metadata))
    setLabelText(m.detailNarrators, LibraryItemMetadata_GetNarrators(metadata))
    setLabelText(m.detailPublishDate, LibraryItemMetadata_GetPublishYear(metadata))
    setLabelText(m.detailPublisher, FirstNonEmpty([metadata.publisher], "Unknown"))
    setLabelText(m.detailGenres, LibraryItemMetadata_GetGenres(metadata))
    setLabelText(m.detailTags, LibraryItemMetadata_GetTags(metadata))
    setLabelText(m.detailDuration, LibraryItemMetadata_GetDuration(item))
    if m.detailDescription <> invalid then m.detailDescription.title = LibraryItemMetadata_GetTitle(item)
    setLabelText(m.detailDescription, LibraryItemMetadata_GetDescription(metadata))
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
sub focusDescription()
    updatePlayButtonFocus(false)
    if m.detailDescription <> invalid then m.detailDescription.setFocus(true)
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
        title: LibraryItemMetadata_GetTitle(m.selectedItem)
        details: getPlaybackDetails(m.selectedItem)
        startPositionSeconds: getPlaybackStartPosition(m.selectedItem)
        counter: m.playSelectedCounter
    }
end sub

'-------------------------------------------------------------------------------
' getPlaybackDetails
'-------------------------------------------------------------------------------
function getPlaybackDetails(item as dynamic) as object
    metadata = LibraryItemMetadata_GetMetadata(item)
    return {
        authors: LibraryItemMetadata_GetAuthor(metadata)
        authorCount: LibraryItemMetadata_GetNameCount(metadata.authors, LibraryItemMetadata_GetAuthor(metadata))
        narrators: LibraryItemMetadata_GetNarrators(metadata)
        narratorCount: LibraryItemMetadata_GetNameCount(metadata.narrators, LibraryItemMetadata_GetNarrators(metadata))
        description: LibraryItemMetadata_GetDescription(metadata)
        publisher: FirstNonEmpty([metadata.publisher], "Unknown")
        publishDate: LibraryItemMetadata_GetPublishDate(metadata)
        category: LibraryItemMetadata_GetCategory(metadata)
        duration: LibraryItemMetadata_GetDuration(item)
        durationSeconds: LibraryItemMetadata_GetDurationSeconds(item)
    }
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

        if focusFirstLibraryItem() then return true
        if requestHeaderFocusFromFirstItem() then return true
    end if

    if m.playButton <> invalid and m.playButton.isInFocusChain() then
        if key = "left" then
            focusLibraryList()
            return true
        else if key = "down" then
            focusDescription()
            return true
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

