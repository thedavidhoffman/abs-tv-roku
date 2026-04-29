'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.homeRowList = m.top.findNode("homeRowList")
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
    if m.homeRowList = invalid then return

    root = CreateObject("roSGNode", "ContentNode")
    row = CreateObject("roSGNode", "ContentNode")
    row.title = "Continue Listening"

    items = m.top.inProgressItems
    if items <> invalid then
        for each item in items
            if item <> invalid and item.id <> invalid then
                node = CreateObject("roSGNode", "ContentNode")
                node.title = getLibraryItemTitle(item)
                node.HDPosterUrl = buildCoverUrl(item.id)
                node.SDPosterUrl = node.HDPosterUrl
                row.appendChild(node)
            end if
        end for
    end if

    root.appendChild(row)
    m.homeRowList.content = root
    updateStatus(row.getChildCount())

    if m.focusRequested = true and m.top.visible = true then focusHomePage()
end sub

'-------------------------------------------------------------------------------
' updateStatus
'-------------------------------------------------------------------------------
sub updateStatus(itemCount as integer)
    if m.statusLabel = invalid or m.homeRowList = invalid then return

    hasItems = itemCount > 0
    m.statusLabel.visible = not hasItems
    if m.continueListeningTitle <> invalid then m.continueListeningTitle.visible = hasItems
    m.homeRowList.visible = hasItems

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

    if m.homeRowList <> invalid and m.homeRowList.visible = true then
        m.homeRowList.setFocus(true)
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
