'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.continueListeningGrid = m.top.findNode("continueListeningGrid")
    m.statusLabel = m.top.findNode("statusLabel")
    m.continueListeningTitle = m.top.findNode("continueListeningTitle")
    m.focusRequested = false
    m.backSelectedCounter = 0
    onInProgressItemsChanged()
end sub

'-------------------------------------------------------------------------------
' onInProgressItemsChanged
'-------------------------------------------------------------------------------
sub onInProgressItemsChanged()
    if m.continueListeningGrid = invalid then return

    root = CreateObject("roSGNode", "ContentNode")

    items = m.top.inProgressItems
    if items <> invalid then
        for each item in items
            if item <> invalid and item.id <> invalid then
                node = CreateObject("roSGNode", "ContentNode")
                node.title = getLibraryItemTitle(item)
                node.HDPosterUrl = buildCoverUrl(item.id)
                node.SDPosterUrl = node.HDPosterUrl
                root.appendChild(node)
            end if
        end for
    end if

    m.continueListeningGrid.content = root
    updateStatus(root.getChildCount())

    if m.focusRequested = true and m.top.visible = true then focusHomePage()
end sub

'-------------------------------------------------------------------------------
' updateStatus
'-------------------------------------------------------------------------------
sub updateStatus(itemCount as integer)
    if m.statusLabel = invalid or m.continueListeningGrid = invalid then return

    hasItems = itemCount > 0
    m.statusLabel.visible = not hasItems
    if m.continueListeningTitle <> invalid then m.continueListeningTitle.visible = hasItems
    m.continueListeningGrid.visible = hasItems

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

    m.top.setFocus(true)
    return true
end function

'-------------------------------------------------------------------------------
' onKeyEvent
'-------------------------------------------------------------------------------
function onKeyEvent(key as string, press as boolean) as boolean
    if press = false then return false
    if key <> "back" then return false

    m.backSelectedCounter = m.backSelectedCounter + 1
    m.top.backSelected = m.backSelectedCounter
    return true
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
