'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    initReferences()

    m.selectedItem = invalid
    m.playSelectedCounter = 0
    m.seriesActionSelectedCounter = 0
    m.leftRequestedCounter = 0
    m.server = invalid
    m.token = invalid

    initStyle()
    clearFocusVisual()
    onItemChanged()
end sub

'-------------------------------------------------------------------------------
' initReferences
'-------------------------------------------------------------------------------
sub initReferences()
    m.selectedPoster = m.top.findNode("selectedPoster")
    m.seriesPosterGroup = m.top.findNode("seriesPosterGroup")
    m.seriesPosterSlots = getSeriesPosterSlots()
    m.seriesSummaryLabel = m.top.findNode("seriesSummaryLabel")
    m.playButton = m.top.findNode("playButton")
    m.metadataGroup = m.top.findNode("metadataGroup")
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
' getSeriesPosterSlots
'-------------------------------------------------------------------------------
function getSeriesPosterSlots() as object
    slots = []

    for i = 1 to 6
        indexText = i.ToStr()
        slots.Push({
            poster: m.top.findNode("seriesPoster" + indexText)
            shadow: m.top.findNode("seriesPosterShadow" + indexText)
        })
    end for

    return slots
end function

'-------------------------------------------------------------------------------
' initStyle
'-------------------------------------------------------------------------------
sub initStyle()
    palette = Color()

end sub

'-------------------------------------------------------------------------------
' onLoadRequestChanged
'-------------------------------------------------------------------------------
sub onLoadRequestChanged()
    request = m.top.loadRequest
    if request = invalid then return

    m.server = request.server
    m.token = request.token
    onItemChanged()
end sub

'-------------------------------------------------------------------------------
' onItemChanged
'-------------------------------------------------------------------------------
sub onItemChanged()
    showSelectedItem(m.top.item)
end sub

'-------------------------------------------------------------------------------
' showSelectedItem
'-------------------------------------------------------------------------------
sub showSelectedItem(item as dynamic)
    m.selectedItem = item
    applyOverviewMode()

    if isSeriesMode() then
        renderSeriesPosters(item)
    else
        clearSeriesPosters()
        if m.selectedPoster <> invalid then m.selectedPoster.itemContent = getSelectedPosterContent(item)
    end if

    updateSelectedDetails(item)
end sub

'-------------------------------------------------------------------------------
' applyOverviewMode
'-------------------------------------------------------------------------------
sub applyOverviewMode()
    showDetails = (isSeriesMode() = false)

    if m.selectedPoster <> invalid then m.selectedPoster.visible = showDetails
    if m.seriesPosterGroup <> invalid then m.seriesPosterGroup.visible = (showDetails = false)
    if m.seriesSummaryLabel <> invalid then m.seriesSummaryLabel.visible = false
    if m.metadataGroup <> invalid then m.metadataGroup.visible = showDetails
    if m.playButton <> invalid then m.playButton.visible = showDetails
    if m.detailDescription <> invalid then m.detailDescription.visible = showDetails

    if showDetails = false then clearFocusVisual()
end sub

'-------------------------------------------------------------------------------
' renderSeriesPosters
'-------------------------------------------------------------------------------
sub renderSeriesPosters(item as dynamic)
    clearSeriesPosters()

    itemIds = getCollapsedSeriesLibraryItemIds(item)
    if itemIds = invalid then return

    updateSeriesSummary(itemIds.Count())

    posterCount = getSeriesPosterCount(itemIds)
    if posterCount <= 0 then return

    positionSeriesPosterSlots(posterCount)

    showShadows = (posterCount > 1)
    for i = 0 to posterCount - 1
        renderSeriesPosterSlot(m.seriesPosterSlots[i], getSeriesPosterUrl(itemIds[i]), showShadows)
    end for
end sub

'-------------------------------------------------------------------------------
' updateSeriesSummary
'-------------------------------------------------------------------------------
sub updateSeriesSummary(seriesCount as integer)
    if m.seriesSummaryLabel = invalid then return

    if seriesCount = 1 then
        m.seriesSummaryLabel.text = "Series with 1 book"
    else
        m.seriesSummaryLabel.text = "Series with " + seriesCount.ToStr() + " books"
    end if

    m.seriesSummaryLabel.visible = true
end sub

'-------------------------------------------------------------------------------
' positionSeriesPosterSlots
'-------------------------------------------------------------------------------
sub positionSeriesPosterSlots(posterCount as integer)
    if m.seriesPosterSlots = invalid then return

    for i = 0 to posterCount - 1
        positionSeriesPosterSlot(m.seriesPosterSlots[i], i, posterCount)
    end for
end sub

'-------------------------------------------------------------------------------
' positionSeriesPosterSlot
'-------------------------------------------------------------------------------
sub positionSeriesPosterSlot(slot as dynamic, index as integer, posterCount as integer)
    if slot = invalid then return

    posterX = getSeriesPosterX(index, posterCount)
    posterY = 241

    if slot.poster <> invalid then slot.poster.translation = [posterX, posterY]
    if slot.shadow <> invalid then slot.shadow.translation = [posterX - 16, posterY - 16]
end sub

'-------------------------------------------------------------------------------
' getSeriesPosterX
'-------------------------------------------------------------------------------
function getSeriesPosterX(index as integer, posterCount as integer) as integer
    leftX = 980
    rightX = 1920 - 64 - 420
    if posterCount <= 1 then return leftX

    spread = rightX - leftX
    return leftX + int(((spread * index) / (posterCount - 1)) + 0.5)
end function

'-------------------------------------------------------------------------------
' renderSeriesPosterSlot
'-------------------------------------------------------------------------------
sub renderSeriesPosterSlot(slot as dynamic, posterUrl as string, showShadow as boolean)
    if slot = invalid then return

    if slot.poster <> invalid then
        slot.poster.uri = posterUrl
        slot.poster.visible = (posterUrl <> "")
    end if

    if slot.shadow <> invalid then slot.shadow.visible = showShadow
end sub

'-------------------------------------------------------------------------------
' clearSeriesPosters
'-------------------------------------------------------------------------------
sub clearSeriesPosters()
    if m.seriesPosterSlots = invalid then return

    for each slot in m.seriesPosterSlots
        if slot <> invalid then
            if slot.poster <> invalid then
                slot.poster.uri = ""
                slot.poster.visible = false
            end if

            if slot.shadow <> invalid then slot.shadow.visible = false
        end if
    end for
end sub

'-------------------------------------------------------------------------------
' getSeriesPosterCount
'-------------------------------------------------------------------------------
function getSeriesPosterCount(itemIds as dynamic) as integer
    if itemIds = invalid then return 0
    count = itemIds.Count()
    if count > 6 then return 6
    return count
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
' getSeriesPosterUrl
'-------------------------------------------------------------------------------
function getSeriesPosterUrl(itemId as dynamic) as string
    if itemId = invalid then return ""
    return Cover_BuildUrl(m.server, m.token, itemId, 600)
end function

'-------------------------------------------------------------------------------
' getSelectedPosterContent
'-------------------------------------------------------------------------------
function getSelectedPosterContent(item as dynamic) as dynamic
    if item = invalid then return invalid

    progress = getProgressData(item)
    node = CreateObject("roSGNode", "ContentNode")
    node.title = getOverviewTitle(item)
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
' getCoverItemId
'-------------------------------------------------------------------------------
function getCoverItemId(item as dynamic) as dynamic
    if item = invalid then return invalid
    if item.id <> invalid then return item.id
    if item.collapsedSeries <> invalid and item.collapsedSeries.libraryItemId <> invalid then return item.collapsedSeries.libraryItemId
    return invalid
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
' updateSelectedDetails
'-------------------------------------------------------------------------------
sub updateSelectedDetails(item as dynamic)
    if isSeriesMode() then
        setLabelText(m.detailTitle, getOverviewTitle(item))
        return
    end if

    metadata = ItemMetadataParser_GetMetadata(item)

    setLabelText(m.detailTitle, getOverviewTitle(item))
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
' getOverviewTitle
'-------------------------------------------------------------------------------
function getOverviewTitle(item as dynamic) as string
    if isSeriesMode() then return getCollapsedSeriesTitle(item)
    return ItemMetadataParser_GetTitle(item)
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
' isSeriesMode
'-------------------------------------------------------------------------------
function isSeriesMode() as boolean
    return m.top.isSeries = true
end function

'-------------------------------------------------------------------------------
' setLabelText
'-------------------------------------------------------------------------------
sub setLabelText(label as dynamic, text as string)
    if label <> invalid then label.text = text
end sub

'-------------------------------------------------------------------------------
' clearFocusVisual
'-------------------------------------------------------------------------------
sub clearFocusVisual()
    if m.playButton <> invalid then m.playButton.hasFocusVisual = false
end sub

'-------------------------------------------------------------------------------
' focusPlayButton
'-------------------------------------------------------------------------------
sub focusPlayButton()
    if isSeriesMode() then return
    if m.playButton = invalid then return

    m.playButton.hasFocusVisual = true
    m.playButton.setFocus(true)
end sub

'-------------------------------------------------------------------------------
' focusDescription
'-------------------------------------------------------------------------------
function focusDescription() as boolean
    if isSeriesMode() then return false
    if m.detailDescription = invalid then return false
    if m.detailDescription.canAcceptFocus <> true then return false

    clearFocusVisual()
    m.detailDescription.setFocus(true)
    return true
end function

'-------------------------------------------------------------------------------
' isInFocusChain
'-------------------------------------------------------------------------------
function isInFocusChain() as boolean
    if isSeriesMode() then return false
    if m.playButton <> invalid and m.playButton.isInFocusChain() then return true
    if m.detailDescription <> invalid and m.detailDescription.isInFocusChain() then return true
    return false
end function

'-------------------------------------------------------------------------------
' onPlayPressed
'-------------------------------------------------------------------------------
sub onPlayPressed()
    if isSeriesMode() then
        m.seriesActionSelectedCounter = m.seriesActionSelectedCounter + 1
        m.top.seriesActionSelected = {
            counter: m.seriesActionSelectedCounter
        }
        return
    end if

    if m.selectedItem = invalid or m.selectedItem.id = invalid then return

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
' getCollapsedSeriesId
'-------------------------------------------------------------------------------
function getCollapsedSeriesId(item as dynamic) as dynamic
    if item = invalid then return invalid
    if item.collapsedSeries = invalid then return invalid
    if item.collapsedSeries.id = invalid then return invalid
    return item.collapsedSeries.id
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
' onKeyEvent
'-------------------------------------------------------------------------------
function onKeyEvent(key as string, press as boolean) as boolean
    if press = false then return false

    if m.playButton <> invalid and m.playButton.isInFocusChain() then
        if key = "left" then
            clearFocusVisual()
            m.leftRequestedCounter = m.leftRequestedCounter + 1
            m.top.leftRequested = m.leftRequestedCounter
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

    return false
end function
