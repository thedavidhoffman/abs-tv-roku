'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.homeRowList = m.top.findNode("homeRowList")
    m.statusLabel = m.top.findNode("statusLabel")
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
end sub

'-------------------------------------------------------------------------------
' updateStatus
'-------------------------------------------------------------------------------
sub updateStatus(itemCount as integer)
    if m.statusLabel = invalid or m.homeRowList = invalid then return

    hasItems = itemCount > 0
    m.statusLabel.visible = not hasItems
    m.homeRowList.visible = hasItems

    if hasItems then
        m.statusLabel.text = ""
    else
        m.statusLabel.text = "Nothing in progress"
    end if
end sub

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
