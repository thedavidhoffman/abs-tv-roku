'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.libraryStatus = m.top.findNode("libraryStatus")
    m.libraryList = m.top.findNode("libraryList")
    m.selectedPoster = m.top.findNode("selectedPoster")
    m.playButton = m.top.findNode("playButton")
    m.detailTitle = m.top.findNode("detailTitle")
    m.detailAuthor = m.top.findNode("detailAuthor")
    m.detailDescription = m.top.findNode("detailDescription")
    m.detailPublisher = m.top.findNode("detailPublisher")
    m.detailPublishDate = m.top.findNode("detailPublishDate")
    m.detailDuration = m.top.findNode("detailDuration")
    m.libraryApiTask = m.top.findNode("libraryApiTask")
    m.libraryItemsByRow = []
    m.selectedItem = invalid
    m.playSelectedCounter = 0
    m.server = invalid
    m.token = invalid

    m.libraryList.observeField("itemFocused", "onLibraryItemFocused")
    m.libraryList.observeField("itemSelected", "onLibraryItemSelected")
    m.libraryApiTask.observeField("response", "onLibraryApiResponse")
    updatePlayButtonFocus(false)
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
    showSelectedItem(invalid)
    setStatus("Loading library...")
    m.libraryApiTask.request = {
        action: "loadLibrary"
        server: request.server
        token: request.token
        bookLibraryId: request.bookLibraryId
    }
    m.libraryApiTask.control = "run"
end sub

'-------------------------------------------------------------------------------
' onLibraryApiResponse
'-------------------------------------------------------------------------------
sub onLibraryApiResponse()
    response = m.libraryApiTask.response
    if response = invalid then return

    if response.ok <> true then
        m.top.errorResponse = response
        setStatus(response.errorMessage)
        return
    end if

    if response.action = "loadLibrary" then
        m.top.libraryItems = response.libraryItems
        setStatus("")
    end if
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
        m.libraryList.setFocus(true)
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
    if m.selectedPoster <> invalid then m.selectedPoster.uri = buildCoverUrl(item)
    updateSelectedDetails(item)
end sub

'-------------------------------------------------------------------------------
' buildCoverUrl
'-------------------------------------------------------------------------------
function buildCoverUrl(item as dynamic) as string
    if item = invalid or item.id = invalid then return "pkg:/images/placeholder_cover.png"
    if m.server = invalid or m.server = "" or m.token = invalid or m.token = "" then return "pkg:/images/placeholder_cover.png"
    return m.server + "/api/items/" + item.id.ToStr() + "/cover?width=600&token=" + m.token
end function

'-------------------------------------------------------------------------------
' updateSelectedDetails
'-------------------------------------------------------------------------------
sub updateSelectedDetails(item as dynamic)
    metadata = getItemMetadata(item)

    setLabelText(m.detailTitle, getLibraryItemTitle(item))
    setLabelText(m.detailAuthor, "Author: " + getItemAuthor(metadata))
    setLabelText(m.detailDescription, getItemDescription(metadata))
    setLabelText(m.detailPublisher, "Publisher: " + FirstNonEmpty([metadata.publisher], "Unknown"))
    setLabelText(m.detailPublishDate, "Published: " + getItemPublishDate(metadata))
    setLabelText(m.detailDuration, "Duration: " + getItemDuration(item))
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
' getItemDuration
'-------------------------------------------------------------------------------
function getItemDuration(item as dynamic) as string
    duration = invalid
    if item <> invalid and item.media <> invalid then duration = item.media.duration
    if duration = invalid and item <> invalid then duration = item.duration
    if duration = invalid then return "Unknown"

    totalSeconds = int(val(duration.ToStr()))
    if totalSeconds <= 0 then return "Unknown"

    hours = int(totalSeconds / 3600)
    minutes = int((totalSeconds mod 3600) / 60)

    if hours > 0 and minutes > 0 then return hours.ToStr() + "h " + minutes.ToStr() + "m"
    if hours > 0 then return hours.ToStr() + "h"
    if minutes > 0 then return minutes.ToStr() + "m"
    return "Less than 1m"
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
        narrators: getItemNarrators(metadata)
        description: getItemDescription(metadata)
        publisher: FirstNonEmpty([metadata.publisher], "Unknown")
        publishDate: getItemPublishDate(metadata)
        duration: getItemDuration(item)
    }
end function

'-------------------------------------------------------------------------------
' onKeyEvent
'-------------------------------------------------------------------------------
function onKeyEvent(key as string, press as boolean) as boolean
    if press = false then return false

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
        if key = "right" then
            focusPlayButton()
            return true
        end if
    end if

    return false
end function

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
